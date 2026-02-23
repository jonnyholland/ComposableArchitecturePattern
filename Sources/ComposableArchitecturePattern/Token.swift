//
//  Token.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

public struct Token: Sendable {
	public var value: String?
	public var expiresOn: Date?

	public init(value: String? = nil, expiresOn: Date? = nil) {
		self.value = value
		self.expiresOn = expiresOn
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
