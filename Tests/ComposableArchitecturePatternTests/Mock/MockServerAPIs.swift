//
//  MockServerAPIs.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 12/8/24.
//

import Foundation
@testable import ComposableArchitecturePattern

enum MockServerEnvironments {
	static let mockServerAPI1 = ServerEnvironment.localTests(url: Bundle.module.url(forResource: "MockResponse1JSON", withExtension: "json"))
	static let mockServerAPI2 = ServerEnvironment.localTests(url: Bundle.module.url(forResource: "MockResponse2JSON", withExtension: "json"))
}

struct MockServerAPI1: ServerAPI {
	let id = UUID()
	var environment: ServerEnvironment? = MockServerEnvironments.mockServerAPI1
	var path: String = ""
	var supportedHTTPMethods: [HTTPMethod] = [.GET]
	var supportedReturnObjects: [Decodable.Type]? = [MockResponse1.self]
	var strictEnvironmentEnforcement: Bool { false }
}

struct MockServerAPI2: ServerAPI {
	let id = UUID()
	var environment: ServerEnvironment? = MockServerEnvironments.mockServerAPI2
	var path: String = ""
	var supportedHTTPMethods: [HTTPMethod] = [.GET]
	var supportedReturnObjects: [Decodable.Type]? = [MockResponse2.self]
	var strictEnvironmentEnforcement: Bool { false }
}

actor MockServer1: Server {
	var environments: [ServerEnvironment] = [MockServerEnvironments.mockServerAPI1]
	lazy var currentEnvironment: ServerEnvironment? = self.environments.first
	lazy var courier: Courier = MockCourier()
	var requestsBeingProcessed = Set<UUID>()
	var apis: [any ServerAPI] = [MockServerAPI1()]
}

actor MockServer2: Server {
	var environments: [ServerEnvironment] = [MockServerEnvironments.mockServerAPI2]
	lazy var currentEnvironment: ServerEnvironment? = self.environments.first
	lazy var courier: Courier = MockCourier()
	var requestsBeingProcessed = Set<UUID>()
	var apis: [any ServerAPI] = [MockServerAPI2()]
}
