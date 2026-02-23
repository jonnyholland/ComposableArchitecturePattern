//
//  Server.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation
import Logging

/// The HTTP method type.
public enum HTTPMethod: String, Equatable, Sendable {
	case DELETE
	case GET
	case POST
	case PUT
}

/// An actor that handles server interactions.
///
/// This is the equivalent of a web service. The idea is for this to be the base actor to handle all server interactions that correspond to the defined API's. This ensures API's can be scoped to specific servers, thus allowing you to scope feature support.
public protocol Server: Actor {
	/// Environments supported by this server.
	var environments: [ServerEnvironment] { get }
	/// The current environment being used by this server to process requests.
	var currentEnvironment: ServerEnvironment? { get }
	/// Additional headers that may be required/needed for interaction with this server.
	var additionalHTTPHeaders: [String: String]? { get }
	/// Whether or not to log all activity wtih this server.
	var logActivity: LogActivity { get }
	
	/// All the API's supported by the server.
	var apis: [any ServerAPI] { get }
	
	/// Flag to not all the server to send any request that is not explicitly defined in `apis`.
	var blockAllAPIsNotSupported: Bool { get }
	/// All the requests currently being processed.
	var requestsBeingProcessed: Set<UUID> { get set }
	
	/// The logger to use with communicating server activity.
	var logger: Logger { get }
	
	/// The courier for making URL requests.
	///
	/// By default it will use a shared instance of `DefaultCourier`.
	var courier: Courier { get }
	
	/// Sends a GET request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func get<T: Decodable>(using api: any ServerAPI, to endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> T
	
	/// Sends a POST request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func post<T: Decodable>(using api: any ServerAPI, to endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> T
	
	/// Sends a POST request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the return type of `Bool` is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func post(using api: any ServerAPI, to endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> Bool
	
	/// Sends a PUT request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func put<T: Decodable>(using api: any ServerAPI, to endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> T
	
	/// Sends a PUT request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the return type of `Bool` is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func put(using api: any ServerAPI, to endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> Bool
	
	/// Sends a DELETE request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func delete<T: Decodable>(using api: any ServerAPI, to endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> T
	
	/// Sends a DELETE request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the return type of `Bool` is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func delete(using api: any ServerAPI, to endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> Bool
}

public extension Server {
	var logActivity: LogActivity {
		return .all
	}
	
	var logger: Logger {
		return Logger(label: "\(Bundle.main.bundleIdentifier ?? "com.CAP.Server").\(String(describing: Self.self))")
	}

	#if canImport(os)
	var courier: Courier { DefaultCourier.shared }
	#elseif canImport(AsyncHTTPClient)
	var courier: Courier { AsyncHTTPClientCourier.shared }
	#endif
	
	var currentEnvironment: ServerEnvironment? { nil }
	
	var additionalHTTPHeaders: [String: String]? { nil }
	
	var blockAllAPIsNotSupported: Bool { true }
	
	// GETs
	func get<T: Decodable>(using api: any ServerAPI, to endpoint: String? = nil, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) async throws -> T {
		if self.blockAllAPIsNotSupported {
			try self._checkAPIsContainAPI(api)
			
			try self._checkAPISupportsType(api, type: T.self)
		}
		
		let requestUID = UUID()
		self.requestsBeingProcessed.insert(requestUID)
		if self.logActivity == .all {
			logger.info("\(Date()) [GET] - (\(requestUID)) Processing GET Request")
		}
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		let request = try api.request(.GET, at: endpoint, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return decoded
	}
	
	/// Sends a GET request and returns the specified value type based on the specified path.
	///
	/// The default implementation attempts to find and unwrap the first api that supports `path`,  `GET` http method, `currentEnvironment` (if the API's environment is specified), and supports the return type. If none are found, it throws a `ServerAPIError.badRequest`. If an api is found, it gets unwrapped and then this calls `-get(using:, to:, additionalHeaders:, queries:, httpBodyOverride:, timeoutInterval:, dataDecodingStrategry:, keyDecodingStrategy:)`.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func get<T: Decodable>(path: String, endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> T {
		guard let api = self.apis.first(where: { $0.path == path && $0.supportedHTTPMethods.contains(.GET) && ($0.environment != nil ? $0.environment == self.currentEnvironment : true) && $0.supports(T.self) }) else {
			throw ServerAPIError.notImplemented(description: "No API found for \(path)")
		}
		
		return try await self.get(using: api, to: endpoint, additionalHeaders: additionalHeaders, queries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
	}
	
	// POSTs
	func post<T: Decodable>(using api: any ServerAPI, to endpoint: String? = nil, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) async throws -> T {
		if self.blockAllAPIsNotSupported {
			try self._checkAPIsContainAPI(api)
			
			try self._checkAPISupportsType(api, type: T.self)
		}
		let requestUID = UUID()
		self.requestsBeingProcessed.insert(requestUID)
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Processing POST Request")
		}
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		let request = try api.request(.POST, at: endpoint, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return decoded
	}
	
	func post(using api: any ServerAPI, to endpoint: String? = nil, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) async throws -> Bool {
		if self.blockAllAPIsNotSupported {
			try self._checkAPIsContainAPI(api)
		}
		let requestUID = UUID()
		self.requestsBeingProcessed.insert(requestUID)
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Processing POST Request")
		}
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		let request = try api.request(.POST, at: endpoint, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let wasSuccessful = try await self.sendRequest(request, requestUID: requestUID)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return wasSuccessful
	}
	
	/// Sends a POST request and returns the specified value type based on the specified path.
	///
	/// The default implementation attempts to find and unwrap the first api that supports `path`,  `POST` http method, `currentEnvironment` (if the API's environment is specified), and supports the return type. If none are found, it throws a `ServerAPIError.badRequest`. If an api is found, it gets unwrapped and then this calls `-post(using:, to:, additionalHeaders:, queries:, httpBodyOverride:, timeoutInterval:, dataDecodingStrategry:, keyDecodingStrategy:)`.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func post<T: Decodable>(path: String, endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> T {
		guard let api = self.apis.first(where: { $0.path == path && $0.supportedHTTPMethods.contains(.POST) && ($0.environment != nil ? $0.environment == self.currentEnvironment : true) && $0.supports(T.self) }) else {
			throw ServerAPIError.notImplemented(description: "No API found for \(path)")
		}
		
		return try await self.post(using: api, to: endpoint, additionalHeaders: additionalHeaders, queries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
	}
	
	// PUTs
	func put<T: Decodable>(using api: any ServerAPI, to endpoint: String? = nil, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) async throws -> T {
		if self.blockAllAPIsNotSupported {
			try self._checkAPIsContainAPI(api)
			
			try self._checkAPISupportsType(api, type: T.self)
		}
		
		let requestUID = UUID()
		self.requestsBeingProcessed.insert(requestUID)
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Processing PUT Request")
		}
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		let request = try api.request(.PUT, at: endpoint, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return decoded
	}
	
	func put(using api: any ServerAPI, to endpoint: String? = nil, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) async throws -> Bool {
		if self.blockAllAPIsNotSupported {
			try self._checkAPIsContainAPI(api)
		}
		
		let requestUID = UUID()
		self.requestsBeingProcessed.insert(requestUID)
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Processing PUT Request")
		}
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		let request = try api.request(.PUT, at: endpoint, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let wasSuccessful = try await self.sendRequest(request, requestUID: requestUID)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return wasSuccessful
	}
	
	/// Sends a PUT request and returns the specified value type based on the specified path.
	///
	/// The default implementation attempts to find and unwrap the first api that supports `path`,  `PUT` http method, `currentEnvironment` (if the API's environment is specified), and supports the return type. If none are found, it throws a `ServerAPIError.badRequest`. If an api is found, it gets unwrapped and then this calls `-put(using:, to:, additionalHeaders:, queries:, httpBodyOverride:, timeoutInterval:, dataDecodingStrategry:, keyDecodingStrategy:)`.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func put<T: Decodable>(path: String, endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> T {
		guard let api = self.apis.first(where: { $0.path == path && $0.supportedHTTPMethods.contains(.PUT) && ($0.environment != nil ? $0.environment == self.currentEnvironment : true) && $0.supports(T.self) }) else {
			throw ServerAPIError.notImplemented(description: "No API found for \(path)")
		}
		
		return try await self.put(using: api, to: endpoint, additionalHeaders: additionalHeaders, queries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
	}
	
	// DELETEs
	func delete<T: Decodable>(using api: any ServerAPI, to endpoint: String? = nil, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) async throws -> T {
		if self.blockAllAPIsNotSupported {
			try self._checkAPIsContainAPI(api)
			
			try self._checkAPISupportsType(api, type: T.self)
		}
		let requestUID = UUID()
		self.requestsBeingProcessed.insert(requestUID)
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Processing DELETE Request")
		}
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		let request = try api.request(.DELETE, at: endpoint, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return decoded
	}
	
	func delete(using api: any ServerAPI, to endpoint: String? = nil, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) async throws -> Bool {
		if self.blockAllAPIsNotSupported {
			try self._checkAPIsContainAPI(api)
		}
		let requestUID = UUID()
		self.requestsBeingProcessed.insert(requestUID)
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Processing DELETE Request")
		}
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}

		let request = try api.request(.DELETE, at: endpoint, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let wasSuccessful = try await self.sendRequest(request, requestUID: requestUID)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return wasSuccessful
	}
	
	/// Sends a DELETE request and returns the specified value type based on the specified path.
	///
	/// The default implementation attempts to find and unwrap the first api that supports `path`,  `DELETE` http method, `currentEnvironment` (if the API's environment is specified), and supports the return type. If none are found, it throws a `ServerAPIError.badRequest`. If an api is found, it gets unwrapped and then this calls `-delete(using:, to:, additionalHeaders:, queries:, httpBodyOverride:, timeoutInterval:, dataDecodingStrategry:, keyDecodingStrategy:)`.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func delete<T: Decodable>(path: String, endpoint: String?, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?) async throws -> T {
		guard let api = self.apis.first(where: { $0.path == path && $0.supportedHTTPMethods.contains(.DELETE) && ($0.environment != nil ? $0.environment == self.currentEnvironment : true) && $0.supports(T.self) }) else {
			throw ServerAPIError.notImplemented(description: "No API found for \(path)")
		}
		
		return try await self.delete(using: api, to: endpoint, additionalHeaders: additionalHeaders, queries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
	}
	
	func sendRequest<T: Decodable>(_ request: URLRequest, requestUID: UUID, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) async throws -> T {
		let data = try await self.courier.sendRequest(request, requestUID: requestUID)
		
		self.requestsBeingProcessed.remove(requestUID)
		
		guard let data: T = try self._decode(data: data, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy) else {
			throw ServerAPIError.unableToDecode(description: NSLocalizedString("Unable to decode object", comment: ""), error: nil)
		}
		return data
	}
	
	/// Send the given request to the server and return the result.
	/// - Returns: A result with `Void` or an `APIError`.
	func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Bool {
		let _ = try await self.courier.sendRequest(request, requestUID: requestUID)
		
		self.requestsBeingProcessed.remove(requestUID)
		
		return true
	}
	
	/// Checks if the `apis` contains the given api.
	///
	/// - Throws: A `ServerAPIError` if not found.
	fileprivate func _checkAPIsContainAPI(_ api: any ServerAPI) throws {
		guard self.apis.contains(where: { $0.isEqual(to: api) }) else {
			throw ServerAPIError.badRequest(description: NSLocalizedString("API for path \(api.path) isn't supported.", comment: ""))
		}
	}
	
	fileprivate func _checkAPISupportsType<T: Decodable>(_ api: any ServerAPI, type: T.Type) throws {
		guard api.supports(T.self) else {
			throw ServerAPIError.badRequest(description: NSLocalizedString("API doesn't support type: `\(T.self)`.", comment: ""))
		}
	}
	
	private func _combineAdditionalHeaders(_ additionalHeaders: [String: String]?) -> [String: String]? {
		guard let additionalHeaders else {
			return self.additionalHTTPHeaders
		}
		guard let additionalHTTPHeaders else {
			return additionalHeaders
		}
		
		return additionalHTTPHeaders.merging(additionalHeaders, uniquingKeysWith: { $1 })
	}
}

extension Server {
	private func _decode<DecodableType: Decodable>(data: Data?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil , keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil) throws -> DecodableType {
		guard let data else {
			throw ServerAPIError.incorrectReponseData(description: NSLocalizedString("Unexpected empty response returned.", comment: ""))
		}
		
		do {
			let decoder = JSONDecoder()
			if let dateDecodingStrategy {
				decoder.dateDecodingStrategy = dateDecodingStrategy
			}
			if let keyDecodingStrategy {
				decoder.keyDecodingStrategy = keyDecodingStrategy
			}
			
			return try decoder.decode(DecodableType.self, from: data)
		} catch let decodingError as DecodingError {
			let decodingErrorContextDescription = { (context: DecodingError.Context) -> String in
				var description = context.debugDescription.appending("\nCoding Path: ")
				description += context.codingPath.map(\.stringValue).joined(separator: ", ")
				return description
			}
			
			switch decodingError {
				case .typeMismatch(_, let context), .valueNotFound(_, let context), .keyNotFound(_, let context), .dataCorrupted(let context):
					throw ServerAPIError.unableToParse(description: decodingErrorContextDescription(context), error: decodingError)
				default:
					throw ServerAPIError.unableToParse(description: decodingError.localizedDescription, error: decodingError)
			}
		} catch {
			throw ServerAPIError.local(description: error.localizedDescription, error: error)
		}
	}
}

public enum LogActivity {
	/// Post all activities to the logger.
	case all
	/// Post only errors to the logger.
	case errors
}
