//
//  ConcreteServerAPI.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 3/16/26.
//

import Foundation

/// A concrete implementation of ServerAPI.
public struct ConcreteServerAPI: ServerAPI {
	public let id: UUID
	
	public var environment: ServerEnvironment?
	public var path: String
	public var supportedHTTPMethods: [HTTPMethod]
	public var headers: [String: String]?
	public var queries: [URLQueryItem]?
	public var body: Data?
	public var supportedReturnObjects: [any Decodable.Type]?
	public var timeoutInterval: TimeInterval = 300
	public var strictEnvironmentEnforcement: Bool = true
	
	public init(
		id: UUID = UUID(),
		environment: ServerEnvironment? = nil,
		path: String,
		supportedHTTPMethods: [HTTPMethod],
		headers: [String : String]? = nil,
		queries: [URLQueryItem]? = nil,
		body: Data? = nil,
		supportedReturnObjects: [any Decodable.Type]? = nil,
		timeoutInterval: TimeInterval,
		strictEnvironmentEnforcement: Bool
	) {
		self.id = id
		self.environment = environment
		self.path = path
		self.supportedHTTPMethods = supportedHTTPMethods
		self.headers = headers
		self.queries = queries
		self.body = body
		self.supportedReturnObjects = supportedReturnObjects
		self.timeoutInterval = timeoutInterval
		self.strictEnvironmentEnforcement = strictEnvironmentEnforcement
	}
}
