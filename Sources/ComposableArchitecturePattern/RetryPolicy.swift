//
//  RetryPolicy.swift
//  ComposableArchitecturePattern
//
//  Created by CAP on 2/23/26.
//

import Foundation

/// Strategy for computing delay between retry attempts.
public enum BackoffStrategy: Sendable {
	/// No delay between retries.
	case none
	/// A fixed delay between each retry.
	case fixed(delay: TimeInterval)
	/// Exponential backoff with a configurable base and maximum delay.
	case exponential(base: TimeInterval = 1.0, maxDelay: TimeInterval = 60.0)

	/// Computes the delay for the given attempt number (0-indexed).
	public func delay(forAttempt attempt: Int) -> TimeInterval {
		switch self {
		case .none:
			return 0
		case .fixed(let delay):
			return delay
		case .exponential(let base, let maxDelay):
			let computed = base * pow(2.0, Double(attempt))
			return min(computed, maxDelay)
		}
	}
}

/// Configures retry behavior for failed requests.
public struct RetryPolicy: Sendable {
	/// Maximum number of attempts (1 = no retry, 2 = one retry, etc.).
	public let maxAttempts: Int

	/// The backoff strategy to use between retries.
	public let backoff: BackoffStrategy

	/// Determines whether the given error should trigger a retry.
	public let shouldRetry: @Sendable (ServerAPIError) -> Bool

	public init(
		maxAttempts: Int = 3,
		backoff: BackoffStrategy = .exponential(),
		shouldRetry: @escaping @Sendable (ServerAPIError) -> Bool = { error in
			switch error {
			case .network, .unknown:
				return true
			default:
				return false
			}
		}
	) {
		self.maxAttempts = maxAttempts
		self.backoff = backoff
		self.shouldRetry = shouldRetry
	}
}
