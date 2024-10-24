//
//  Server.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import SwiftUI
import OSLog

public enum HTTPMethod: String, Equatable {
	case DELETE
	case GET
	case POST
	case PUT
}

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
	
	var logger: Logger { get }
	
	/// Designated initializer
	init(
		environments: [ServerEnvironment],
		currentEnvironment: ServerEnvironment?,
		additionalHTTPHeaders: [String: String]?,
		supportedAPIs: [any ServerAPI],
		logActivity: LogActivity
	)
	
	/// Sends a GET request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func get<T: Codable>(_ api: any ServerAPI, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
	/// Sends a POST request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func post<T: Codable>(_ api: any ServerAPI, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
	
	/// Sends a POST request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the return type of `Bool` is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func post(_ api: any ServerAPI, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> Bool
	
	/// Sends a PUT request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func put<T: Codable>(_ api: any ServerAPI, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
	
	/// Sends a PUT request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the return type of `Bool` is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func put(_ api: any ServerAPI, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> Bool
	
	/// Sends a DELETE request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the specified return type is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func delete<T: Codable>(_ api: any ServerAPI, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
	
	/// Sends a DELETE request and returns the specified value type from the given API.
	///
	///	- Note: `additionalHeaders` will override a key-value in `additionalHTTPHeaders`.
	/// - Note: The server automatically checks against these values to check whether they're supported by the API or not. For instance, if the return type of `Bool` is not supported, a `ServerAPIError.badRequest` error is thrown. If the specified API doesn't support this function, a `ServerAPIError.badRequest` error is thrown.
	func delete(_ api: any ServerAPI, additionalHeaders: [String: String]?, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> Bool
	
	/// Send the given request to the server and return the decoded object.
	/// - Returns: The given decoded type or an `APIError`.
	/// - Throws: A `ServerAPIError` if unable to decode or an error encountered during the request.
	func sendRequest<T: Codable>(_ request: URLRequest, requestUID: UUID, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
	
	/// Send the given request to the server.
	/// - Returns: A boolean indicating the success of the request.
	/// - Throws: A `ServerAPIError` if unable to decode or an error encountered during the request.
	func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Bool
}

public extension Server {
	var logActivity: LogActivity {
		return .all
	}
	
	var loggers: Logger {
		return Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.Coordinator", category: String(describing: Self.self))
	}
	
	// GETs
	func get<T: Codable>(_ api: any ServerAPI, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
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
		
		let request = try api.request(.GET, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return decoded
	}
	
	// POSTs
	func post<T: Codable>(_ api: any ServerAPI, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
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
		
		let request = try api.request(.POST, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return decoded
	}
	
	func post(_ api: any ServerAPI, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> Bool {
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
		
		let request = try api.request(.POST, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let wasSuccessful = try await self.sendRequest(request, requestUID: requestUID)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return wasSuccessful
	}
	
	// PUTs
	func put<T: Codable>(_ api: any ServerAPI, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
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
		
		let request = try api.request(.PUT, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return decoded
	}
	
	func put(_ api: any ServerAPI, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> Bool {
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
		
		let request = try api.request(.PUT, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let wasSuccessful = try await self.sendRequest(request, requestUID: requestUID)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return wasSuccessful
	}
	
	// DELETEs
	func delete<T: Codable>(_ api: any ServerAPI, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
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
		
		let request = try api.request(.DELETE, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return decoded
	}
	
	func delete(_ api: any ServerAPI, additionalHeaders: [String: String]? = nil, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> Bool {
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

		let request = try api.request(.DELETE, in: self.currentEnvironment, additionalHeaders: self._combineAdditionalHeaders(additionalHeaders), additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let wasSuccessful = try await self.sendRequest(request, requestUID: requestUID)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw ServerAPIError.taskCancelled(error: error)
		}
		
		return wasSuccessful
	}
	
	func sendRequest<T: Codable>(_ request: URLRequest, requestUID: UUID, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
		if self.logActivity == .all {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Start]")
		}
		
		let (data, response) = try await URLSession.shared.data(for: request)
		
		self.requestsBeingProcessed.remove(requestUID)
		
		if self.logActivity == .all {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Finish]")
		}
		
		guard try response.analyzeAsHTTPResponse() else {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) { Failed }")
			throw ServerAPIError.unknown(description: "Unable to complete server response.")
		}
		
		if self.logActivity == .all {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) { Success }")
		}
		
		guard let data: T = try self._decode(data: data, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy) else {
			throw ServerAPIError.unableToDecode(description: NSLocalizedString("Unable to decode object", comment: ""), error: nil)
		}
		return data
	}
	
	/// Send the given request to the server and return the result.
	/// - Returns: A result with `Void` or an `APIError`.
	func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Bool {
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Start]")
		}
		
		let (_, response) = try await URLSession.shared.data(for: request)
		
		self.requestsBeingProcessed.remove(requestUID)
		
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Finish]")
		}
		
		guard try response.analyzeAsHTTPResponse() else {
			logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) { Failed }")
			throw ServerAPIError.unknown(description: "Unable to complete server response.")
		}
		
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) { Success }")
		}
		
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
	
	fileprivate func _checkAPISupportsType<T: Codable>(_ api: any ServerAPI, type: T.Type) throws {
		guard api.supports(T.self) else {
			throw ServerAPIError.badRequest(description: NSLocalizedString("API doesn't support type: `\(T.self)`.", comment: ""))
		}
	}
	
	private func _combineAdditionalHeaders(_ additionalHeaders: [String: String]?) -> [String: String]? {
		guard let additionalHeaders else {
			return self.additionalHTTPHeaders
		}
		guard var additionalHTTPHeaders else {
			return additionalHeaders
		}
		
		return additionalHTTPHeaders.merging(additionalHeaders, uniquingKeysWith: { $1 })
	}
}

extension Server {
	private func _decode<DecodableType: Decodable>(data: Data?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) throws -> DecodableType {
		guard let data else {
			throw ServerAPIError.incorrectReponseData(description: NSLocalizedString("Unexpected empty response returned.", comment: ""))
		}
		
		do {
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = dateDecodingStrategy
			decoder.keyDecodingStrategy = keyDecodingStrategy
			
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
