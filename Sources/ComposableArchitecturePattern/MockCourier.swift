//
//  MockCourier.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 12/8/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct MockCourier: Courier {
	public func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Data? {
		guard let url = request.url else {
			throw ServerAPIError.unknown(description: "Must have a valid URL to get mock data.", error: nil)
		}
		
		return try? Data(contentsOf: url)
	}
}
