//
//  PipelineIntegrationTests.swift
//  ComposableArchitecturePattern
//

import XCTest
import Logging
@testable import ComposableArchitecturePattern

// MARK: - Pipeline Test Helpers

/// A courier that returns configurable data or throws configurable errors.
private struct ConfigurableCourier: Courier {
	var responseData: Data?
	var error: ServerAPIError?
	let tracker: RequestTracker

	func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Data? {
		await tracker.recordRequest(request)
		if let error { throw error }
		return responseData
	}
}

private actor RequestTracker {
	var requests: [URLRequest] = []
	func recordRequest(_ request: URLRequest) { requests.append(request) }
	func getRequests() -> [URLRequest] { requests }
}

/// A courier that fails N times then succeeds.
private actor FailThenSucceedCourier: Courier {
	var failuresRemaining: Int
	let successData: Data
	var attemptCount = 0

	init(failCount: Int, successData: Data = Data("{\"name\":\"ok\",\"age\":1}".utf8)) {
		self.failuresRemaining = failCount
		self.successData = successData
	}

	func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Data? {
		attemptCount += 1
		if failuresRemaining > 0 {
			failuresRemaining -= 1
			throw ServerAPIError.network(description: "Transient failure")
		}
		return successData
	}

	func getAttemptCount() -> Int { attemptCount }
}

/// A courier that always returns 401 unauthorized.
private struct UnauthorizedCourier: Courier {
	let tracker: RequestTracker

	func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Data? {
		await tracker.recordRequest(request)
		throw ServerAPIError.unauthorized(description: "HTTP 401")
	}
}

/// A simple request interceptor that adds a header.
private struct TestHeaderInterceptor: RequestInterceptor {
	let headerName: String
	let headerValue: String

	func intercept(_ request: URLRequest) async throws -> URLRequest {
		var r = request
		r.setValue(headerValue, forHTTPHeaderField: headerName)
		return r
	}
}

/// A simple response interceptor that wraps data in an array JSON.
private struct PrefixResponseInterceptor: ResponseInterceptor {
	func intercept(_ data: Data?, for request: URLRequest) async throws -> Data? {
		return data
	}
}

/// Mock authenticator for pipeline tests.
private actor PipelineAuthenticator: Authenticator {
	var token: String
	var refreshCount = 0

	init(token: String = "pipeline-token") {
		self.token = token
	}

	func authenticate(_ request: URLRequest) async throws -> URLRequest {
		var r = request
		r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		return r
	}

	func refreshCredentials() async throws {
		refreshCount += 1
		token = "refreshed-\(refreshCount)"
	}

	var isAuthenticated: Bool { !token.isEmpty }

	func getRefreshCount() -> Int { refreshCount }
}

// MARK: - Pipeline Test API & Server

private struct PipelineTestAPI: ServerAPI {
	let id = UUID()
	var environment: ServerEnvironment? = .localTests(url: nil)
	var path: String = "/test"
	var headers: [String: String]? = nil
	var queries: [URLQueryItem]? = nil
	var body: Data? = nil
	var supportedHTTPMethods: [HTTPMethod] = [.GET, .POST]
	var supportedReturnObjects: [Decodable.Type]? = [MockResponse1.self]
	var timeoutInterval: TimeInterval = 60
	var strictEnvironmentEnforcement: Bool = false
}

private actor PipelineTestServer: Server {
	var environments: [ServerEnvironment] = [.localTests(url: nil)]
	var currentEnvironment: ServerEnvironment? = .localTests(url: nil)
	var additionalHTTPHeaders: [String: String]? = nil
	var logActivity: LogActivity = .all
	var apis: [any ServerAPI] = [PipelineTestAPI()]
	var blockAllAPIsNotSupported: Bool = false
	var requestsBeingProcessed = Set<UUID>()
	var logger: Logger = Logger(label: "com.CAP.PipelineTestServer")

	var courier: Courier
	var authenticator: (any Authenticator)?
	var retryPolicy: RetryPolicy?
	var requestInterceptors: [any RequestInterceptor]
	var responseInterceptors: [any ResponseInterceptor]
	var responseCache: (any ResponseCache)?
	var cacheTTL: TimeInterval

	init(
		courier: Courier,
		authenticator: (any Authenticator)? = nil,
		retryPolicy: RetryPolicy? = nil,
		requestInterceptors: [any RequestInterceptor] = [],
		responseInterceptors: [any ResponseInterceptor] = [],
		responseCache: (any ResponseCache)? = nil,
		cacheTTL: TimeInterval = 300
	) {
		self.courier = courier
		self.authenticator = authenticator
		self.retryPolicy = retryPolicy
		self.requestInterceptors = requestInterceptors
		self.responseInterceptors = responseInterceptors
		self.responseCache = responseCache
		self.cacheTTL = cacheTTL
	}
}

// MARK: - Tests

final class PipelineIntegrationTests: XCTestCase {
	let jsonData = Data("{\"name\":\"Test\",\"age\":25}".utf8)

	func testCacheHitSkipsCourier() async throws {
		let tracker = RequestTracker()
		let courier = ConfigurableCourier(responseData: jsonData, error: nil, tracker: tracker)
		let cache = InMemoryResponseCache()

		let url = URL(string: "https://example.com/test")!
		await cache.store(jsonData, for: url, ttl: 300)

		let server = PipelineTestServer(courier: courier, responseCache: cache)
		// Use sendRequest directly with a GET request
		var request = URLRequest(url: url)
		request.httpMethod = "GET"

		let result: Bool = try await server.sendRequest(request, requestUID: UUID(), httpMethod: .GET)
		XCTAssertTrue(result)

		// Courier should NOT have been called — cache hit
		let requests = await tracker.getRequests()
		XCTAssertEqual(requests.count, 0, "Courier should not be called on cache hit")
	}

	func testPOSTNotCached() async throws {
		let tracker = RequestTracker()
		let courier = ConfigurableCourier(responseData: jsonData, error: nil, tracker: tracker)
		let cache = InMemoryResponseCache()

		let url = URL(string: "https://example.com/test")!

		let server = PipelineTestServer(courier: courier, responseCache: cache)
		var request = URLRequest(url: url)
		request.httpMethod = "POST"

		let result: Bool = try await server.sendRequest(request, requestUID: UUID(), httpMethod: .POST)
		XCTAssertTrue(result)

		// Courier SHOULD have been called since POST bypasses cache
		let requests = await tracker.getRequests()
		XCTAssertEqual(requests.count, 1)

		// Cache should not have stored the POST response
		let cached = await cache.cachedResponse(for: url)
		XCTAssertNil(cached, "POST responses should not be cached")
	}

	func testInterceptorsApplied() async throws {
		let tracker = RequestTracker()
		let courier = ConfigurableCourier(responseData: jsonData, error: nil, tracker: tracker)
		let interceptor = TestHeaderInterceptor(headerName: "X-Test", headerValue: "intercepted")

		let server = PipelineTestServer(courier: courier, requestInterceptors: [interceptor])
		var request = URLRequest(url: URL(string: "https://example.com/test")!)
		request.httpMethod = "GET"

		let _: Bool = try await server.sendRequest(request, requestUID: UUID(), httpMethod: .GET)

		let requests = await tracker.getRequests()
		XCTAssertEqual(requests.first?.value(forHTTPHeaderField: "X-Test"), "intercepted")
	}

	func testAuthenticatorApplied() async throws {
		let tracker = RequestTracker()
		let courier = ConfigurableCourier(responseData: jsonData, error: nil, tracker: tracker)
		let auth = PipelineAuthenticator(token: "my-auth-token")

		let server = PipelineTestServer(courier: courier, authenticator: auth)
		var request = URLRequest(url: URL(string: "https://example.com/test")!)
		request.httpMethod = "GET"

		let _: Bool = try await server.sendRequest(request, requestUID: UUID(), httpMethod: .GET)

		let requests = await tracker.getRequests()
		XCTAssertEqual(requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer my-auth-token")
	}

	func testRetryOnTransientFailure() async throws {
		let courier = FailThenSucceedCourier(failCount: 2)
		let retryPolicy = RetryPolicy(maxAttempts: 3, backoff: .none)

		let server = PipelineTestServer(courier: courier, retryPolicy: retryPolicy)
		var request = URLRequest(url: URL(string: "https://example.com/test")!)
		request.httpMethod = "GET"

		let result: Bool = try await server.sendRequest(request, requestUID: UUID(), httpMethod: .GET)
		XCTAssertTrue(result)

		let attempts = await courier.getAttemptCount()
		XCTAssertEqual(attempts, 3, "Should have attempted 3 times (2 failures + 1 success)")
	}

	func testRetryExhaustedThrows() async {
		let courier = FailThenSucceedCourier(failCount: 5)
		let retryPolicy = RetryPolicy(maxAttempts: 2, backoff: .none)

		let server = PipelineTestServer(courier: courier, retryPolicy: retryPolicy)
		var request = URLRequest(url: URL(string: "https://example.com/test")!)
		request.httpMethod = "GET"

		do {
			let _: Bool = try await server.sendRequest(request, requestUID: UUID(), httpMethod: .GET)
			XCTFail("Expected error after retry exhaustion")
		} catch let error as ServerAPIError {
			if case .network = error { } else {
				XCTFail("Expected network error, got: \(error)")
			}
		} catch {
			XCTFail("Unexpected error type: \(error)")
		}
	}

	func testUnauthorizedTriggersRefreshAndRetry() async throws {
		// First call returns 401, after refresh the courier still returns 401
		// but at least refresh should have been called.
		let tracker = RequestTracker()
		let courier = UnauthorizedCourier(tracker: tracker)
		let auth = PipelineAuthenticator(token: "expired-token")

		let server = PipelineTestServer(courier: courier, authenticator: auth)
		var request = URLRequest(url: URL(string: "https://example.com/test")!)
		request.httpMethod = "GET"

		do {
			let _: Bool = try await server.sendRequest(request, requestUID: UUID(), httpMethod: .GET)
			XCTFail("Expected unauthorized error")
		} catch {
			// Expected — the courier always returns 401
		}

		// Verify refresh was attempted
		let refreshCount = await auth.getRefreshCount()
		XCTAssertEqual(refreshCount, 1, "Should have attempted to refresh credentials once")
	}

	func testGETResponseStoredInCache() async throws {
		let tracker = RequestTracker()
		let courier = ConfigurableCourier(responseData: jsonData, error: nil, tracker: tracker)
		let cache = InMemoryResponseCache()

		let url = URL(string: "https://example.com/cacheable")!
		let server = PipelineTestServer(courier: courier, responseCache: cache)
		var request = URLRequest(url: url)
		request.httpMethod = "GET"

		let _: Bool = try await server.sendRequest(request, requestUID: UUID(), httpMethod: .GET)

		let cached = await cache.cachedResponse(for: url)
		XCTAssertEqual(cached, jsonData, "GET response should be stored in cache")
	}
}
