//
//  Server+Courier.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 12/8/24.
//

import Foundation

public protocol Courier: Sendable {
	/// Send the given request to the server.
	/// - Returns: A boolean indicating the success of the request.
	/// - Throws: A `ServerAPIError` if unable to decode or an error encountered during the request.
	func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Data?
}
