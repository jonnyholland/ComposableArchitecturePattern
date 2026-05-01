//
//  URLResponse+Extensions.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension URLResponse {
	/// Maps an HTTP response (and optional response body) to either success
	/// (`true`) or a thrown `ServerAPIError`. When `body` is supplied and the
	/// status falls in 4xx (other than 401), the body is preserved on
	/// `ServerAPIError.http` so callers can decode structured error envelopes.
	///
	/// - Parameter body: Optional response body data captured alongside the
	///   response. Pass `nil` when the body isn't available — the resulting
	///   `.http` error will carry only the status code.
	func analyzeAsHTTPResponse(body: Data? = nil) throws -> Bool {
		guard let httpResponse = self as? HTTPURLResponse else {
			throw ServerAPIError.unknown(description: "Unable to unwrap as `HTTPURLResponse`")
		}

		switch httpResponse.statusCode {
			case 100...199:
				throw ServerAPIError.unknown(description: httpResponse.description)
			case 200...299:
				return true
			case 401:
				throw ServerAPIError.unauthorized(description: httpResponse.description)
			case 400...499:
				throw ServerAPIError.http(
					description: httpResponse.description,
					statusCode: httpResponse.statusCode,
					body: body
				)
			case 500...599:
				throw ServerAPIError.server(description: httpResponse.description, httpStatusCode: httpResponse.statusCode)
			default:
				throw ServerAPIError.unknown(description: "Unknown HTTPURLResponse: \(httpResponse.description)")
		}
	}
}
