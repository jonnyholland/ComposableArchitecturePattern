//
//  Token.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

/// A token object for authentication.
public struct Token: Sendable {
	/// The value of the token.
	public var value: String?
	/// When the token expires.
	public var expiresOn: Date?

	public init(value: String? = nil, expiresOn: Date? = nil) {
		self.value = value
		self.expiresOn = expiresOn
	}
	
	/// Create a new token with the given value and expiration duration.
	public init(value: String? = nil, expiresIn: TimeInterval) {
		self.value = value
		self.expiresOn = .init(timeIntervalSince1970: expiresIn)
	}

	/// Whether the token has expired based on the current date.
	public var isExpired: Bool {
		guard let expiresOn else { return false }
		return expiresOn <= Date()
	}

	/// Whether the token has a non-nil, non-empty value and is not expired.
	public var isValid: Bool {
		guard let value, !value.isEmpty else { return false }
		return !isExpired
	}
}
