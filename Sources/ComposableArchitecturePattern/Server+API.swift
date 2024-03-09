//
//  Server+API.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

public protocol ServerAPI: Identifiable, Equatable {
	var environment: ServerEnvironment? { get set }
	var path: String { get set }
	var headers: [String: String]? { get set }
	var queries: [URLQueryItem]? { get set }
	var body: Data? { get set }
	var supportedHTTPMethods: [HTTPMethod] { get set }
	var supportedReturnObjects: [Codable.Type]? { get set }
	var timeoutInterval: TimeInterval { get set }
	
	init(environment: ServerEnvironment?, path: String, headers: [String: String]?, queries: [URLQueryItem]?, supportedHTTPMethods: [HTTPMethod], supportedReturnObjects: [Codable.Type]?, timeoutInterval: TimeInterval)
	
	func request(_ method: HTTPMethod, in environment: ServerEnvironment?, additionalHeaders: [String: String]?, additionalQueries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?) throws -> URLRequest
	func supports<T: Codable>(_ object: T.Type) -> Bool
}

public extension ServerAPI {
	subscript(httpMethod: HTTPMethod) -> URLRequest? {
		guard let httpMethodIndex = self.supportedHTTPMethods.firstIndex(of: httpMethod) else {
			return nil
		}
		
		let httpMethod = self.supportedHTTPMethods[httpMethodIndex]
		return try? self.request(httpMethod)
	}
}

public extension ServerAPI {
	func request(_ httpMethod: HTTPMethod, in environment: ServerEnvironment? = nil, additionalHeaders: [String: String]? = nil, additionalQueries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil) throws -> URLRequest {
		guard self.supportedHTTPMethods.contains(httpMethod) else {
			throw ServerAPIError.badRequest(description: "\(httpMethod.rawValue) is not supported for this API.")
		}
		if (self.environment != nil && environment != self.environment) {
			throw ServerAPIError.badRequest(description: "API (\(self.id)) requires to use environment: \(self.environment?.description ?? "Unknown environment")")
		}
		
		let environment = self.environment ?? environment
		guard let environment else {
			throw ServerAPIError.badRequest(description: "An environment must be present for the API.")
		}
		
		guard let baseURL = environment.url else {
			throw ServerAPIError.badRequest(description: "Unable to resolve base URL for environment.")
		}
		
		var urlComponents = URLComponents(url: baseURL.appendingPathComponent(self.path), resolvingAgainstBaseURL: true)
		
		if let additionalQueries {
			var combinedQueries = additionalQueries
			if let queries {
				combinedQueries += queries
			}
			urlComponents?.queryItems = combinedQueries
		} else if let queries {
			urlComponents?.queryItems = queries
		}
		
		var request = URLRequest(url: urlComponents?.url ?? baseURL,
								 cachePolicy: .useProtocolCachePolicy,
								 timeoutInterval: timeoutInterval ?? self.timeoutInterval)
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
