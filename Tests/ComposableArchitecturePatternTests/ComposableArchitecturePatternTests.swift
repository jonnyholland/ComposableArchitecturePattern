//
//  ComposableArchitecturePatternTests.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 12/8/24.
//

import XCTest
@testable import ComposableArchitecturePattern

final class ComposableArchitecturePatternTests: XCTestCase {
	func testMockCourierGetsJSON() async throws {
		let api1 = MockServerAPI1()
		XCTAssertNotNil(api1.environment?.url)
		
		let sut = MockCourier()
		let dataFromRequest1 = try await sut.sendRequest(try api1.request(.GET), requestUID: .init())
		XCTAssertNotNil(dataFromRequest1)
		
		let api2 = MockServerAPI2()
		XCTAssertNotNil(api2.environment?.url)
		let dataFromRequest2 = try await sut.sendRequest(try api2.request(.GET), requestUID: .init())
		XCTAssertNotNil(dataFromRequest2)
	}
	
	func testServerFunctionality() async throws {
		let sut = MockServer1()
		let apis = await sut.apis
		XCTAssertTrue(apis.count == 1)
		
		let sutAPIs = await sut.apis
		let sutEnvironment = await sut.currentEnvironment
		XCTAssertTrue(sutAPIs.contains(where: { $0.environment == sutEnvironment }))
	}
	
	func testServerAPIReturnObjectsSupport() async throws {
		let sut1 = MockServerAPI1()
		XCTAssertTrue(sut1.supports(MockResponse1.self))
		
		let sut2 = MockServerAPI2()
		XCTAssertTrue(sut2.supports(MockResponse2.self))
	}
}
