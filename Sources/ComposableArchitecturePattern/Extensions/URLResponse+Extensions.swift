//
//  URLResponse+Extensions.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

public extension URLResponse {
	func analyzeAsHTTPResponse() throws -> Bool {
		guard let httpResponse = self as? HTTPURLResponse else {
			throw ServerAPIError.unknown(description: "Unable to unwrap as `HTTPURLResponse`")
		}
		
		switch httpResponse.statusCode {
			case 100...199:
				throw ServerAPIError.unknown(description: httpResponse.description)
			case 200...299:
				return true
			case 400...499:
				throw ServerAPIError.network(description: httpResponse.description)
			case 500...599:
				throw ServerAPIError.server(description: httpResponse.description, httpStatusCode: httpResponse.statusCode)
			default:
				throw ServerAPIError.unknown(description: "Unknown HTTPURLResponse: \(httpResponse.description)")
		}
	}
}
