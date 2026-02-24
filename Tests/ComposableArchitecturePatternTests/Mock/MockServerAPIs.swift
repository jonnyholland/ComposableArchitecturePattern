//
//  MockServerAPIs.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 12/8/24.
//

import Foundation
@testable import ComposableArchitecturePattern
import Logging

enum MockServerEnvironments {
	static let mockServerAPI1 = ServerEnvironment.localTests(url: Bundle.module.url(forResource: "MockResponse1JSON", withExtension: "json"))
	static let mockServerAPI2 = ServerEnvironment.localTests(url: Bundle.module.url(forResource: "MockResponse2JSON", withExtension: "json"))
}

struct MockServerAPI1: ServerAPI {
	let id = UUID()
	var environment: ServerEnvironment? = MockServerEnvironments.mockServerAPI1
	var path: String = ""
	var headers: [String: String]? = nil
	var queries: [URLQueryItem]? = nil
	var body: Data? = nil
	var supportedHTTPMethods: [HTTPMethod] = [.GET]
	var supportedReturnObjects: [Decodable.Type]? = [MockResponse1.self]
	var timeoutInterval: TimeInterval = 60
	var strictEnvironmentEnforcement: Bool = false
}

struct MockServerAPI2: ServerAPI {
	let id = UUID()
	var environment: ServerEnvironment? = MockServerEnvironments.mockServerAPI2
	var path: String = ""
	var headers: [String: String]? = nil
	var queries: [URLQueryItem]? = nil
	var body: Data? = nil
	var supportedHTTPMethods: [HTTPMethod] = [.GET]
	var supportedReturnObjects: [Decodable.Type]? = [MockResponse2.self]
	var timeoutInterval: TimeInterval = 60
	var strictEnvironmentEnforcement: Bool = false
}

actor MockServer1: Server {
	var environments: [ServerEnvironment] = [MockServerEnvironments.mockServerAPI1]
	var currentEnvironment: ServerEnvironment? = MockServerEnvironments.mockServerAPI1
	var additionalHTTPHeaders: [String: String]? = nil
	var logActivity: LogActivity = .all
	var apis: [any ServerAPI] = [MockServerAPI1()]
	var blockAllAPIsNotSupported: Bool = true
	var requestsBeingProcessed = Set<UUID>()
	var logger: Logger = Logger(label: "com.CAP.MockServer1")
	var courier: Courier = MockCourier()
	var authenticator: (any Authenticator)? = nil
	var retryPolicy: RetryPolicy? = nil
	var requestInterceptors: [any RequestInterceptor] = []
	var responseInterceptors: [any ResponseInterceptor] = []
	var responseCache: (any ResponseCache)? = nil
	var cacheTTL: TimeInterval = 300
}

actor MockServer2: Server {
	var environments: [ServerEnvironment] = [MockServerEnvironments.mockServerAPI2]
	var currentEnvironment: ServerEnvironment? = MockServerEnvironments.mockServerAPI2
	var additionalHTTPHeaders: [String: String]? = nil
	var logActivity: LogActivity = .all
	var apis: [any ServerAPI] = [MockServerAPI2()]
	var blockAllAPIsNotSupported: Bool = true
	var requestsBeingProcessed = Set<UUID>()
	var logger: Logger = Logger(label: "com.CAP.MockServer2")
	var courier: Courier = MockCourier()
	var authenticator: (any Authenticator)? = nil
	var retryPolicy: RetryPolicy? = nil
	var requestInterceptors: [any RequestInterceptor] = []
	var responseInterceptors: [any ResponseInterceptor] = []
	var responseCache: (any ResponseCache)? = nil
	var cacheTTL: TimeInterval = 300
}
