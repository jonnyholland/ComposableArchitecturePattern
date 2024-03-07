//
//  ServerResponses.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

/// The response containing the value of whether or not the request was successful.
public struct BoolResponse: Codable {
	public let value: Bool
	
	public init(_ value: Bool) {
		self.value = value
	}
}

/// The response containing the ID sent back when an object is created and successfully saved.
public struct CreationResponse<T: Codable>: Codable {
	public let id: T
	
	public init(id: T) {
		self.id = id
	}
}
