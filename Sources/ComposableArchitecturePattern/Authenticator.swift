//
//  Authenticator.swift
//  ComposableArchitecturePattern
//
//  Created by CAP on 2/23/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Manages authentication for server requests.
///
/// Implementations inject auth headers into outgoing requests and handle
/// credential refresh when a 401 is received.
public protocol Authenticator: Sendable {
	/// Applies authentication credentials to the given request.
	func authenticate(_ request: URLRequest) async throws -> URLRequest

	/// Refreshes credentials (e.g., exchanges a refresh token for a new access token).
	func refreshCredentials() async throws

	/// Whether the authenticator currently holds valid credentials.
	var isAuthenticated: Bool { get async }
}
