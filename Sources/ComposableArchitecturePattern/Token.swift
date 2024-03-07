//
//  Token.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

public struct Token {
	public var value: String?
	public var expiresOn: Date?
	
	public init(value: String? = nil, expiresOn: Date? = nil) {
		self.value = value
		self.expiresOn = expiresOn
	}
}
