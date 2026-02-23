//
//  RetryPolicyTests.swift
//  ComposableArchitecturePattern
//

import XCTest
@testable import ComposableArchitecturePattern

final class RetryPolicyTests: XCTestCase {
	// MARK: - BackoffStrategy

	func testNoneBackoffReturnsZero() {
		let strategy = BackoffStrategy.none
		XCTAssertEqual(strategy.delay(forAttempt: 0), 0)
		XCTAssertEqual(strategy.delay(forAttempt: 5), 0)
	}

	func testFixedBackoffReturnsConstant() {
		let strategy = BackoffStrategy.fixed(delay: 2.0)
		XCTAssertEqual(strategy.delay(forAttempt: 0), 2.0)
		XCTAssertEqual(strategy.delay(forAttempt: 1), 2.0)
		XCTAssertEqual(strategy.delay(forAttempt: 10), 2.0)
	}

	func testExponentialBackoffGrows() {
		let strategy = BackoffStrategy.exponential(base: 1.0, maxDelay: 60.0)
		XCTAssertEqual(strategy.delay(forAttempt: 0), 1.0)   // 1 * 2^0
		XCTAssertEqual(strategy.delay(forAttempt: 1), 2.0)   // 1 * 2^1
		XCTAssertEqual(strategy.delay(forAttempt: 2), 4.0)   // 1 * 2^2
		XCTAssertEqual(strategy.delay(forAttempt: 3), 8.0)   // 1 * 2^3
	}

	func testExponentialBackoffCapsAtMax() {
		let strategy = BackoffStrategy.exponential(base: 1.0, maxDelay: 10.0)
		XCTAssertEqual(strategy.delay(forAttempt: 10), 10.0) // Would be 1024, capped at 10
	}

	// MARK: - RetryPolicy

	func testDefaultShouldRetryOnNetwork() {
		let policy = RetryPolicy()
		XCTAssertTrue(policy.shouldRetry(.network(description: "timeout")))
	}

	func testDefaultShouldRetryOnUnknown() {
		let policy = RetryPolicy()
		XCTAssertTrue(policy.shouldRetry(.unknown()))
	}

	func testDefaultShouldNotRetryOnBadRequest() {
		let policy = RetryPolicy()
		XCTAssertFalse(policy.shouldRetry(.badRequest()))
	}

	func testDefaultShouldNotRetryOnUnauthorized() {
		let policy = RetryPolicy()
		XCTAssertFalse(policy.shouldRetry(.unauthorized()))
	}

	func testDefaultShouldNotRetryOnServer() {
		let policy = RetryPolicy()
		XCTAssertFalse(policy.shouldRetry(.server(httpStatusCode: 500)))
	}

	func testCustomShouldRetry() {
		let policy = RetryPolicy(shouldRetry: { error in
			if case .server = error { return true }
			return false
		})
		XCTAssertTrue(policy.shouldRetry(.server(httpStatusCode: 503)))
		XCTAssertFalse(policy.shouldRetry(.network()))
	}

	func testDefaultMaxAttempts() {
		let policy = RetryPolicy()
		XCTAssertEqual(policy.maxAttempts, 3)
	}
}
