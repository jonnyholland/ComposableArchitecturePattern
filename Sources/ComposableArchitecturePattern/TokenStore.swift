import Foundation

/// Persistent storage for authentication token pairs.
public protocol TokenStore: Sendable {
	/// Retrieves the stored token pair, or `nil` if none exists.
	func retrieveTokenPair() async throws -> TokenPair?

	/// Stores a token pair, replacing any existing one.
	func storeTokenPair(_ tokenPair: TokenPair) async throws

	/// Deletes any stored token pair.
	func deleteTokenPair() async throws
}

/// An in-memory token store for testing and platforms without Keychain.
public actor InMemoryTokenStore: TokenStore {
	private var tokenPair: TokenPair?

	public init() {}

	public func retrieveTokenPair() async throws -> TokenPair? {
		tokenPair
	}

	public func storeTokenPair(_ tokenPair: TokenPair) async throws {
		self.tokenPair = tokenPair
	}

	public func deleteTokenPair() async throws {
		tokenPair = nil
	}
}
