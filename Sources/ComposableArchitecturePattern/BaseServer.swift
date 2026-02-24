//
//  BaseServer.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 2/24/26.
//

import Foundation
import Logging

/// A server for handling API calls.
///
/// Use this if you need a base server without needing to heavily customize the functionality.
public actor BaseServer: Server {
	public var currentEnvironment: ServerEnvironment?
	
	public var environments: [ServerEnvironment]
	
	public var additionalHTTPHeaders: [String: String]?
	
	public var apis: [any ServerAPI]
	
	public var courier: any Courier
	
	public var authenticator: (any Authenticator)?
	
	public var responseCache: (any ResponseCache)?
	
	public var responseInterceptors: [any ResponseInterceptor]
	
	public var requestInterceptors: [any RequestInterceptor]
	
	public var retryPolicy: RetryPolicy?
	
	public var cacheTTL: TimeInterval
	
	public var blockAllAPIsNotSupported: Bool
	
	public var logActivity: LogActivity
	
	public var requestsBeingProcessed = Set<UUID>()
	
	public var logger: Logger
	
	/// Designated initializer.
	///
	/// - Parameters:
	/// 	- currentEnvironment: The current environment of the server for making service calls.
	/// 	- environments: Environments available to the server for making service calls.
	/// 	- additionalHTTPHeaders: Additional headers needed for making service calls. This is useful for passing in authentication headers that will always need to be there.
	/// 	- apis: The API's the server will manage.
	/// 	- courier: The courier for actually making the service calls. If you're running on native Apple software, use `DefaultCourier.shared`. If running on Linux or something else, use `AsyncHTTPClientCourier.shared`.
	/// 	- authenticator:  An object to manage authentication for server requests.
	/// 	- requestInterceptors: Interceptors to act on or transform requests before they are sent.
	/// 	- responseInterceptors: Interceptors to act on or transform responses when they are received.
	/// 	- responseCache: An object to cache responses.
	/// 	- retryPolicy: How retries should be handled.
	/// 	- cacheTTL: Caching duration.
	/// 	- blockAllAPIsNotSupported: Whether or not to strictly block all API's that try to use this service that are not explicitly defined in `apis`. Defaults to `true`.
	/// 	- logActivity: How to log activity of the server.
	/// 	- logger: The logger object to use for logging.
	public init(
		currentEnvironment: ServerEnvironment? = nil, 
		environments: [ServerEnvironment], 
		additionalHTTPHeaders: [String: String]? = nil,
		apis: [any ServerAPI],
		courier: any Courier,
		authenticator: (any Authenticator)? = nil,
		requestInterceptors: [any RequestInterceptor],
		responseInterceptors: [any ResponseInterceptor],
		responseCache: (any ResponseCache)? = nil,
		retryPolicy: RetryPolicy? = nil,
		cacheTTL: TimeInterval,
		blockAllAPIsNotSupported: Bool = true,
		logActivity: LogActivity,
		logger: Logger
	) {
		self.currentEnvironment = currentEnvironment
		self.environments = environments
		self.additionalHTTPHeaders = additionalHTTPHeaders
		self.apis = apis
		self.courier = courier
		self.authenticator = authenticator
		self.responseCache = responseCache
		self.responseInterceptors = responseInterceptors
		self.requestInterceptors = requestInterceptors
		self.retryPolicy = retryPolicy
		self.cacheTTL = cacheTTL
		self.blockAllAPIsNotSupported = blockAllAPIsNotSupported
		self.logActivity = logActivity
		self.logger = logger
	}
}
