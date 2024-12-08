//
//  MockServerResponses.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 12/8/24.
//

import Foundation

struct MockResponse1: Decodable {
	let name: String
	let age: Int
}

struct MockResponse2: Codable {
	let name: String
	let age: Int
	let city: String
}

