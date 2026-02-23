//
//  AuthenticatorTests.swift
//  ComposableArchitecturePattern
//

import XCTest
@testable import ComposableArchitecturePattern

// MARK: - Mock Authenticator

private actor MockAuthenticator: Authenticator {
	var token: String?
	var refreshCount = 0
	var shouldFailRefresh = false

	init(token: String? = "valid-token") {
		self.token = token
	}

	func authenticate(_ request: URLRequest) async throws -> URLRequest {
		guard let token else {
			throw ServerAPIError.unauthorized(description: "No token")
		}
		var modified = request
		modified.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		return modified
	}

	func refreshCredentials() async throws {
		refreshCount += 1
		if shouldFailRefresh {
			throw ServerAPIError.unauthorized(description: "Refresh failed")
		}
		token = "refreshed-token"
	}

	var isAuthenticated: Bool {
		token != nil
	}

	func setToken(_ token: String?) {
		self.token = token
	}

	func setFailRefresh(_ fail: Bool) {
		self.shouldFailRefresh = fail
	}

	func getRefreshCount() -> Int {
		refreshCount
	}
}

// MARK: - Tests

final class AuthenticatorTests: XCTestCase {
	func testAuthenticateInjectsAuthHeader() async throws {
		let auth = MockAuthenticator(token: "my-token")
		var request = URLRequest(url: URL(string: "https://api.example.com/data")!)
		request = try await auth.authenticate(request)
		XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer my-token")
	}

	func testAuthenticateThrowsWhenNoToken() async {
		let auth = MockAuthenticator(token: nil)
		let request = URLRequest(url: URL(string: "https://api.example.com/data")!)

		do {
			_ = try await auth.authenticate(request)
			XCTFail("Expected unauthorized error")
		} catch let error as ServerAPIError {
			if case .unauthorized = error { } else {
				XCTFail("Wrong error: \(error)")
			}
		} catch {
			XCTFail("Unexpected error type: \(error)")
		}
	}

	func testRefreshCredentialsUpdatesToken() async throws {
		let auth = MockAuthenticator(token: "old-token")
		try await auth.refreshCredentials()

		var request = URLRequest(url: URL(string: "https://api.example.com/data")!)
		request = try await auth.authenticate(request)
		XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer refreshed-token")
	}

	func testRefreshFailurePropagatesError() async {
		let auth = MockAuthenticator(token: "old-token")
		await auth.setFailRefresh(true)

		do {
			try await auth.refreshCredentials()
			XCTFail("Expected error")
		} catch let error as ServerAPIError {
			if case .unauthorized = error { } else {
				XCTFail("Wrong error: \(error)")
			}
		} catch {
			XCTFail("Unexpected error type: \(error)")
		}
	}

	func testIsAuthenticated() async {
		let auth = MockAuthenticator(token: "valid")
		let result = await auth.isAuthenticated
		XCTAssertTrue(result)

		await auth.setToken(nil)
		let result2 = await auth.isAuthenticated
		XCTAssertFalse(result2)
	}
}
