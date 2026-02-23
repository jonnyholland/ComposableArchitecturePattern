//
//  InterceptorTests.swift
//  ComposableArchitecturePattern
//

import XCTest
@testable import ComposableArchitecturePattern

// MARK: - Test Interceptors

private struct AddHeaderInterceptor: RequestInterceptor {
	let name: String
	let value: String

	func intercept(_ request: URLRequest) async throws -> URLRequest {
		var modified = request
		modified.addValue(value, forHTTPHeaderField: name)
		return modified
	}
}

private struct UppercaseResponseInterceptor: ResponseInterceptor {
	func intercept(_ data: Data?, for request: URLRequest) async throws -> Data? {
		guard let data, let string = String(data: data, encoding: .utf8) else { return data }
		return Data(string.uppercased().utf8)
	}
}

private struct FailingRequestInterceptor: RequestInterceptor {
	func intercept(_ request: URLRequest) async throws -> URLRequest {
		throw ServerAPIError.local(description: "Interceptor failure")
	}
}

private struct OrderTrackingInterceptor: RequestInterceptor {
	let label: String
	let tracker: OrderTracker

	func intercept(_ request: URLRequest) async throws -> URLRequest {
		await tracker.append(label)
		return request
	}
}

private actor OrderTracker {
	var labels: [String] = []
	func append(_ label: String) { labels.append(label) }
}

// MARK: - Tests

final class InterceptorTests: XCTestCase {
	func testRequestInterceptorAddsHeader() async throws {
		let interceptor = AddHeaderInterceptor(name: "X-Custom", value: "test")
		var request = URLRequest(url: URL(string: "https://example.com")!)
		request = try await interceptor.intercept(request)
		XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "test")
	}

	func testResponseInterceptorTransformsData() async throws {
		let interceptor = UppercaseResponseInterceptor()
		let input = Data("hello world".utf8)
		let request = URLRequest(url: URL(string: "https://example.com")!)
		let output = try await interceptor.intercept(input, for: request)
		XCTAssertEqual(String(data: output!, encoding: .utf8), "HELLO WORLD")
	}

	func testResponseInterceptorHandlesNilData() async throws {
		let interceptor = UppercaseResponseInterceptor()
		let request = URLRequest(url: URL(string: "https://example.com")!)
		let output = try await interceptor.intercept(nil, for: request)
		XCTAssertNil(output)
	}

	func testRequestInterceptorChainOrder() async throws {
		let tracker = OrderTracker()
		let first = OrderTrackingInterceptor(label: "A", tracker: tracker)
		let second = OrderTrackingInterceptor(label: "B", tracker: tracker)
		let interceptors: [any RequestInterceptor] = [first, second]

		var request = URLRequest(url: URL(string: "https://example.com")!)
		for interceptor in interceptors {
			request = try await interceptor.intercept(request)
		}

		let labels = await tracker.labels
		XCTAssertEqual(labels, ["A", "B"])
	}

	func testFailingInterceptorPropagatesError() async {
		let interceptor = FailingRequestInterceptor()
		let request = URLRequest(url: URL(string: "https://example.com")!)

		do {
			_ = try await interceptor.intercept(request)
			XCTFail("Expected error")
		} catch let error as ServerAPIError {
			if case .local(let description, _) = error {
				XCTAssertEqual(description, "Interceptor failure")
			} else {
				XCTFail("Wrong error case: \(error)")
			}
		} catch {
			XCTFail("Unexpected error type: \(error)")
		}
	}
}
