//
//  ServerAPIError.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

public enum ServerAPIError: Error {
	/// The API request is bad.
	case badRequest(description: String? = nil, error: Error? = nil)
	/// The API unexpectedly returned empty data.
	case emptyData
	/// The wrong data returned in response.
	case incorrectReponseData(description: String? = nil)
	case local(description: String? = nil, error: Error?)
	/// An error occurred with the network.
	case network(description: String? = nil)
	/// Functionality to complete the API request is incomplete.
	case notImplemented(description: String? = nil)
	/// An error occurred with the server.
	case server(description: String? = nil, httpStatusCode: Int, jsonObject: Any? = nil)
	/// A task cancellation occurred.
	case taskCancelled(description: String? = nil, error: Error? = nil)
	/// An error occurred while attempting to decode.
	case unableToDecode(description: String? = nil, error: Error? = nil)
	/// An error occurred while attempting to parse data.
	case unableToParse(description: String? = nil, error: Error?)
	/// An unknown error occrred.
	case unknown(description: String? = nil, error: Error? = nil)
}
