//
//  Server+API.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

/// An object that specifies a specific server API.
///
/// - Note: It is highly encouraged to define your `supportedReturnObjects` to ensure `-supports<T: Decodable>(_:)` is able to automatically verify against this.
public protocol ServerAPI: Identifiable, Equatable, Sendable {
	/// The environment this API should be used against. Default is `nil`.
	/// - Note: If it can be used against any environment, leave it `nil`.
	var environment: ServerEnvironment? { get }
	
	/// The path this API corresponds to.
	var path: String { get }
	
	/// The headers required for this API. Default is `nil`.
	var headers: [String: String]? { get }
	
	/// The queries required for this API. Default is `nil`.
	var queries: [URLQueryItem]? { get }
	
	/// Data to send in the request's body.
	var body: Data? { get }
	
	/// All HTTP methods this API supports.
	var supportedHTTPMethods: [HTTPMethod] { get }
	
	/// All the return objects this API supports. Default is `nil`.
	///
	/// This helps ensure a non-supported object isn't attempted to be used with the API.
	var supportedReturnObjects: [Decodable.Type]? { get }
	
	/// The timeout length for the request. Default is `60`.
	var timeoutInterval: TimeInterval { get }
	
	/// Whether to block this API if the server is attempting to use a different environment.
	///
	/// For example, perhaps the server is using a specific environment but this API uses a different environment for some other purpose, such as a specific authentication endpoint. Setting this to `true` would mean that the API will throw an error if the environments don't match up.
	var strictEnvironmentEnforcement: Bool { get }
	
	/// The request for this API built from it's set properties and the passed in parameter values.
	/// - Throws: A `ServerAPIError.badRequest` if the method or environment isn't supported or if there is no environment or environment url.
	func request(_ method: HTTPMethod, at endpoint: String?, in environment: ServerEnvironment?, additionalHeaders: [String: String]?, additionalQueries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?) throws -> URLRequest
	
	/// Whether or not the provided type is supported by the API. Defaults to checking if the type is found in `supportedReturnObjects` or returning `false` if not found.
	func supports<T>(_ object: T.Type) -> Bool
}

extension Sequence where Element == Decodable.Type {
	/// Whether the given collection of decodable types is equal to this collection of decodable types.
	func isEqual(to other: [Decodable.Type]) -> Bool {
		self.contains(where: { type in other.contains(where: { $0 == type }) })
	}
}

extension ServerAPI {
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.id == rhs.id
	}
	
	func isEqual(to api: any ServerAPI) -> Bool {
		let returnObjectsEquatable = {
			if let supportedReturnObjects, let otherSupportedReturnObjects = api.supportedReturnObjects {
				return supportedReturnObjects.isEqual(to: otherSupportedReturnObjects)
			}
			return true
		}
		
		return self.environment == api.environment && self.path == api.path && self.headers == api.headers && self.queries == api.queries && self.body == api.body && self.supportedHTTPMethods == api.supportedHTTPMethods && self.timeoutInterval == api.timeoutInterval && returnObjectsEquatable()
	}
}

public extension ServerAPI {
	subscript(httpMethod: HTTPMethod) -> URLRequest? {
		guard let httpMethodIndex = self.supportedHTTPMethods.firstIndex(of: httpMethod) else {
			return nil
		}
		
		let httpMethod = self.supportedHTTPMethods[httpMethodIndex]
		return try? self.request(httpMethod)
	}
	
	var environment: ServerEnvironment? { nil }
	
	var headers: [String: String]? { nil }
	
	var queries: [URLQueryItem]? { nil }
	
	var body: Data? { nil }
	
	var supportedReturnObjects: [Decodable.Type]? { nil }
	
	var timeoutInterval: TimeInterval { 60 }
	
	var strictEnvironmentEnforcement: Bool { true }
	
	func supports<T>(_ object: T.Type) -> Bool {
		return self.supportedReturnObjects?.contains(where: { object == $0 }) ?? false
	}
}

public extension ServerAPI {
	func request(_ httpMethod: HTTPMethod, at endpoint: String? = nil, in environment: ServerEnvironment? = nil, additionalHeaders: [String: String]? = nil, additionalQueries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil) throws -> URLRequest {
		guard self.supportedHTTPMethods.contains(httpMethod) else {
			throw ServerAPIError.badRequest(description: "\(httpMethod.rawValue) is not supported for this API.")
		}
		if self.strictEnvironmentEnforcement, (self.environment != nil && environment != self.environment) {
			throw ServerAPIError.badRequest(description: "API (\(self.id)) requires to use environment: (\(self.environment?.description ?? "Unknown environment")) but instead (\(environment?.description ?? "Unknown environment")) was used.")
		}
		
		let environment = self.environment ?? environment
		guard let environment else {
			throw ServerAPIError.badRequest(description: "An environment must be present for the API.")
		}
		
		guard let baseURL = environment.url else {
			throw ServerAPIError.badRequest(description: "Unable to resolve base URL for environment.")
		}
		
		var urlComponents = URLComponents(url: baseURL.appending(path: self.path).appendingPathIfNotNil(endpoint), resolvingAgainstBaseURL: true)
		
		if let additionalQueries {
			var combinedQueries = additionalQueries
			if let queries {
				combinedQueries += queries
			}
			urlComponents?.queryItems = combinedQueries
		} else if let queries {
			urlComponents?.queryItems = queries
		}
		
		var request = URLRequest(
			url: urlComponents?.url ?? baseURL,
			cachePolicy: .useProtocolCachePolicy,
			timeoutInterval: timeoutInterval ?? self.timeoutInterval
		)
		
		request.allHTTPHeaderFields = self.headers
		if let additionalHeaders {
			additionalHeaders.forEach {
				request.setValue($0.value, forHTTPHeaderField: $0.key)
			}
		}
		request.httpMethod = httpMethod.rawValue
		if let httpBody {
			request.httpBody = try self._encodedData(httpBody)
		} else if let body {
			request.httpBody = try self._encodedData(body)
		}
		
		return request
	}
	
	private func _encodedData<T: Codable>(_ body: T?) throws -> Data {
		if let data = body as? Data {
			return data
		}
		
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		return try encoder.encode(body)
	}
}
