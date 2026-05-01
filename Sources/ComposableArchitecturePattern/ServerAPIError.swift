//
//  ServerAPIError.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

/// An error encountered during server operation.
public enum ServerAPIError: Error {
	/// The API request is bad.
	case badRequest(description: String? = nil, error: Error? = nil)
	/// The API unexpectedly returned empty data.
	case emptyData(description: String? = nil)
	/// The wrong data returned in response.
	case incorrectReponseData(description: String? = nil)
	/// A local error.
	case local(description: String? = nil, error: Error? = nil)
	/// The request was unauthorized (HTTP 401).
	case unauthorized(description: String? = nil)
	/// An error occurred with the network.
	@available(*, deprecated, message: "Use .http(description:statusCode:body:) which preserves the response body for structured error decoding.")
	case network(description: String? = nil)
	/// An HTTP 4xx error with the response status code and optional response body
	/// preserved so callers can decode structured error envelopes such as
	/// `{"error": {"code": "USER_HAS_CLUSTER", "message": "..."}}`.
	case http(description: String? = nil, statusCode: Int, body: Data? = nil)
	/// Functionality to complete the API request is incomplete.
	case notImplemented(description: String? = nil)
	/// An error occurred with the server.
	case server(description: String? = nil, httpStatusCode: Int)
	/// A task cancellation occurred.
	case taskCancelled(description: String? = nil, error: Error? = nil)
	/// An error occurred while attempting to decode.
	case unableToDecode(description: String? = nil, error: Error? = nil)
	/// An error occurred while attempting to parse data.
	case unableToParse(description: String? = nil, error: Error?)
	/// An unknown error occrred.
	case unknown(description: String? = nil, error: Error? = nil)
}
