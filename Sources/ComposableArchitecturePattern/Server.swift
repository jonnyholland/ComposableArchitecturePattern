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
	var additionalHTTPHeaders: [String : String]? { get }
	/// Whether or not to log all activity wtih this server.
	var logActivity: LogActivity { get }
	
	associatedtype API: ServerAPI
	var apis: [API] { get }
	
	var blockAllAPIsNotSupported: Bool { get }
	var requestsBeingProcessed: Set<UUID> { get set }
	
	var logger: Logger { get }
	
	/// Designated initializer
	init(
		environments: [ServerEnvironment],
		currentEnvironment: ServerEnvironment?,
		additionalHTTPHeaders: [String : String]?,
		supportedAPIs: [API],
		logActivity: LogActivity
	)
	
	func get<T: Codable>(_ api: API, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
	
	func post<T: Codable>(_ api: API, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
	
	func post(_ api: API, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> Bool
	
	func put<T: Codable>(_ api: API, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
	
	func put(_ api: API, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> Bool
	
	func delete<T: Codable>(_ api: API, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> T
	
	func delete(_ api: API, queries: [URLQueryItem]?, httpBodyOverride httpBody: Data?, timeoutInterval: TimeInterval?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) async throws -> Bool
	
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
	func get<T: Codable>(_ api: API, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
		if self.blockAllAPIsNotSupported {
			try self._checkAPIsContainAPI(api)
			
			try self._checkAPISupportsType(api, type: T.self)
		}
		
		let requestUID = UUID()
		self.requestsBeingProcessed.insert(requestUID)
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Processing GET Request")
		}
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw error
		}
		
		let request = try api.request(.GET, in: self.currentEnvironment, additionalHeaders: self.additionalHTTPHeaders, additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw error
		}
		
		return decoded
	}
	
	// POSTs
	func post<T: Codable>(_ api: API, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
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
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw error
		}
		
		let request = try api.request(.POST, in: self.currentEnvironment, additionalHeaders: self.additionalHTTPHeaders, additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw error
		}
		
		return decoded
	}
	
	func post(_ api: API, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> Bool {
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
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw error
		}
		
		let request = try api.request(.POST, in: self.currentEnvironment, additionalHeaders: self.additionalHTTPHeaders, additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let wasSuccessful = try await self.sendRequest(request, requestUID: requestUID)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw error
		}
		
		return wasSuccessful
	}
	
	// PUTs
	func put<T: Codable>(_ api: API, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
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
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw error
		}
		
		let request = try api.request(.PUT, in: self.currentEnvironment, additionalHeaders: self.additionalHTTPHeaders, additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw error
		}
		
		return decoded
	}
	
	func put(_ api: API, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> Bool {
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
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw error
		}
		
		let request = try api.request(.PUT, in: self.currentEnvironment, additionalHeaders: self.additionalHTTPHeaders, additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let wasSuccessful = try await self.sendRequest(request, requestUID: requestUID)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw error
		}
		
		return wasSuccessful
	}
	
	// DELETEs
	func delete<T: Codable>(_ api: API, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
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
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw error
		}
		
		let request = try api.request(.DELETE, in: self.currentEnvironment, additionalHeaders: self.additionalHTTPHeaders, additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let decoded: T = try await self.sendRequest(request, requestUID: requestUID, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw error
		}
		
		return decoded
	}
	
	func delete(_ api: API, queries: [URLQueryItem]? = nil, httpBodyOverride httpBody: Data? = nil, timeoutInterval: TimeInterval? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> Bool {
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
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: api.path)) [Cancelled]")
			throw error
		}
		
		let request = try api.request(.DELETE, in: self.currentEnvironment, additionalHeaders: self.additionalHTTPHeaders, additionalQueries: queries, httpBodyOverride: httpBody, timeoutInterval: timeoutInterval)
		let wasSuccessful = try await self.sendRequest(request, requestUID: requestUID)
		
		do {
			try Task.checkCancellation()
		} catch {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Cancelled]")
			throw error
		}
		
		return wasSuccessful
	}
	
	func sendRequest<T: Codable>(_ request: URLRequest, requestUID: UUID, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) async throws -> T {
		if self.logActivity == .all {
			logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Start]")
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
	fileprivate func _checkAPIsContainAPI(_ api: API) throws {
		guard self.apis.contains(api) else {
			throw ServerAPIError.badRequest(description: NSLocalizedString("API for path \(api.path) isn't supported.", comment: ""))
		}
	}
	
	fileprivate func _checkAPISupportsType<T: Codable>(_ api: API, type: T.Type) throws {
		guard api.supports(T.self) else {
			throw ServerAPIError.badRequest(description: NSLocalizedString("API doesn't support type: `\(T.self)`.", comment: ""))
		}
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
