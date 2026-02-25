//
//  Server+Interceptors.swift
//  ComposableArchitecturePattern
//
//  Created by CAP on 2/23/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Intercepts and transforms outgoing requests before they are sent.
public protocol RequestInterceptor: Sendable {
	func intercept(_ request: URLRequest) async throws -> URLRequest
}

/// Intercepts and transforms response data after it is received.
public protocol ResponseInterceptor: Sendable {
	func intercept(_ data: Data?, for request: URLRequest) async throws -> Data?
}
