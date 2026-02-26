import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An ``Authenticator`` that reads and writes tokens through a ``TokenStore``.
///
/// On each request, injects the stored access token as a Bearer header.
/// When a 401 triggers ``refreshCredentials()``, the provided refresh handler
/// is called with the current refresh token and the resulting ``TokenPair``
/// is persisted back to the store.
public actor TokenStoreAuthenticator: Authenticator {
	private let store: any TokenStore
	private let refreshHandler: @Sendable (Token) async throws -> TokenPair

	/// Creates a token-store-backed authenticator.
	/// - Parameters:
	///   - store: The backing token store (Keychain, in-memory, etc.).
	///   - refreshHandler: A closure that exchanges a refresh token for a new token pair.
	public init(
		store: any TokenStore,
		refreshHandler: @escaping @Sendable (Token) async throws -> TokenPair
	) {
		self.store = store
		self.refreshHandler = refreshHandler
	}

	// MARK: - Authenticator

	public func authenticate(_ request: URLRequest) async throws -> URLRequest {
		guard let pair = try await store.retrieveTokenPair(),
			  let accessValue = pair.accessToken.value,
			  pair.isAccessValid
		else {
			throw ServerAPIError.unauthorized(description: "No valid access token available")
		}

		var authedRequest = request
		authedRequest.setValue("Bearer \(accessValue)", forHTTPHeaderField: "Authorization")
		return authedRequest
	}

	public func refreshCredentials() async throws {
		guard let pair = try await store.retrieveTokenPair(), pair.canRefresh else {
			throw ServerAPIError.unauthorized(description: "No valid refresh token available")
		}

		let newPair = try await refreshHandler(pair.refreshToken)
		try await store.storeTokenPair(newPair)
	}

	public nonisolated var isAuthenticated: Bool {
		get async {
			guard let pair = try? await store.retrieveTokenPair() else { return false }
			return pair.isAccessValid
		}
	}

	// MARK: - Additional API

	/// Stores credentials after a successful login (e.g., Google SSO).
	public func storeCredentials(_ tokenPair: TokenPair) async throws {
		try await store.storeTokenPair(tokenPair)
	}

	/// Clears all stored credentials (logout).
	public func clearCredentials() async throws {
		try await store.deleteTokenPair()
	}
}
