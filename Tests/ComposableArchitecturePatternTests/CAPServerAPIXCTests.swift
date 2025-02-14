//
//  CAPServerAPIXCTests.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 12/8/24.
//

import XCTest
@testable import ComposableArchitecturePattern

final class CAPServerAPIXCTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testMockCourierGetsJSON() async throws {
		let api1 = MockServerAPI1()
		XCTAssertNotNil(api1.environment?.url)
		
		let sut = MockCourier()
		let dataFromRequest1 = try await sut.sendRequest(try api1.request(.GET), requestUID: .init())
		XCTAssertNotNil(dataFromRequest1)
		XCTAssertNoThrow({
			let mockUser: MockUser = try self._decode(data: dataFromRequest1)
			XCTAssertEqual(mockUser.name, "Jonathan")
			XCTAssertEqual(mockUser.age, 30)
		})
		
		
		let api2 = MockServerAPI2()
		XCTAssertNotNil(api2.environment?.url)
		let dataFromRequest2 = try await sut.sendRequest(try api2.request(.GET), requestUID: .init())
		XCTAssertNotNil(dataFromRequest2)
		XCTAssertNoThrow({
			let mockUser: MockUser = try self._decode(data: dataFromRequest2)
			XCTAssertEqual(mockUser.name, "Steve Jobs")
			XCTAssertEqual(mockUser.age, 30)
			XCTAssertEqual(mockUser.city, "Cupertino")
			XCTAssertEqual(mockUser.email, "steve@apple.com")
		})
	}
	
	func testServerAPIReturnObjectsSupport() async throws {
		let sut1 = MockServerAPI1()
		XCTAssertTrue(sut1.supports(MockResponse1.self))
		
		let sut2 = MockServerAPI2()
		XCTAssertTrue(sut2.supports(MockResponse2.self))
	}
	
	func testReturnObjectsSupport() async throws {
		let api = MockServerAPI1()
		let server = MockServer1()
		
		let serverCurrentEnvironment = await server.currentEnvironment
		XCTAssertNotNil(serverCurrentEnvironment)
		XCTAssertNotNil(api.environment?.url)
		
		XCTAssertNoThrow(try api.request(.GET))
		
		let response: MockResponse1 = try await {
			try await server.get(using: api)
		}()
		
		XCTAssertNoThrow(response, "Unable to complete request")
	}
}

extension CAPServerAPIXCTests {
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
