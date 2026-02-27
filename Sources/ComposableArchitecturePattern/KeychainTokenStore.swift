#if canImport(Security)
import Foundation
import Security

/// Errors specific to Keychain token storage operations.
public enum KeychainTokenStoreError: Error {
	case unexpectedItemData
	case encodingFailed
	case decodingFailed
	case addFailed(OSStatus)
	case updateFailed(OSStatus)
	case deleteFailed(OSStatus)
	case copyFailed(OSStatus)
}

/// Stores authentication tokens in the system Keychain.
///
/// Access and refresh tokens are stored as separate Keychain items under the
/// same service identifier with different account keys. Each item is
/// JSON-encoded with both the token value and expiration date.
public actor KeychainTokenStore: TokenStore {
	private let service: String
	private let accessGroup: String?

	private static let accessAccountKey = "com.cap.token.access"
	private static let refreshAccountKey = "com.cap.token.refresh"

	/// Creates a Keychain-backed token store.
	/// - Parameters:
	///   - service: The Keychain service identifier. Defaults to the bundle identifier.
	///   - accessGroup: Optional Keychain access group for sharing across app extensions.
	public init(service: String? = nil, accessGroup: String? = nil) {
		self.service = service ?? Bundle.main.bundleIdentifier ?? "com.cap.tokenstore"
		self.accessGroup = accessGroup
	}

	public func retrieveTokenPair() async throws -> TokenPair? {
		let accessToken = try readToken(account: Self.accessAccountKey)
		let refreshToken = try readToken(account: Self.refreshAccountKey)

		guard accessToken != nil || refreshToken != nil else { return nil }

		return TokenPair(
			accessToken: accessToken ?? Token(),
			refreshToken: refreshToken ?? Token()
		)
	}

	public func storeTokenPair(_ tokenPair: TokenPair) async throws {
		try writeToken(tokenPair.accessToken, account: Self.accessAccountKey)
		try writeToken(tokenPair.refreshToken, account: Self.refreshAccountKey)
	}

	public func deleteTokenPair() async throws {
		try deleteToken(account: Self.accessAccountKey)
		try deleteToken(account: Self.refreshAccountKey)
	}

	// MARK: - Private Helpers

	private struct StoredToken: Codable {
		let value: String
		let expiresOn: Date?
	}

	private func baseQuery(account: String) -> [String: Any] {
		var query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
		]
		if let accessGroup {
			query[kSecAttrAccessGroup as String] = accessGroup
		}
		return query
	}

	private func readToken(account: String) throws -> Token? {
		var query = baseQuery(account: account)
		query[kSecReturnData as String] = true
		query[kSecMatchLimit as String] = kSecMatchLimitOne

		var result: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &result)

		switch status {
		case errSecSuccess:
			guard let data = result as? Data else {
				throw KeychainTokenStoreError.unexpectedItemData
			}
			guard let stored = try? JSONDecoder().decode(StoredToken.self, from: data) else {
				throw KeychainTokenStoreError.decodingFailed
			}
			return Token(value: stored.value, expiresOn: stored.expiresOn)

		case errSecItemNotFound:
			return nil

		default:
			throw KeychainTokenStoreError.copyFailed(status)
		}
	}

	private func writeToken(_ token: Token, account: String) throws {
		guard let value = token.value else {
			// If the token has no value, delete any existing entry
			try? deleteToken(account: account)
			return
		}

		let stored = StoredToken(value: value, expiresOn: token.expiresOn)
		guard let data = try? JSONEncoder().encode(stored) else {
			throw KeychainTokenStoreError.encodingFailed
		}

		// Try to update first
		let query = baseQuery(account: account)
		let attributes: [String: Any] = [kSecValueData as String: data]
		let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

		switch updateStatus {
		case errSecSuccess:
			return

		case errSecItemNotFound:
			// Item doesn't exist yet — add it
			var addQuery = query
			addQuery[kSecValueData as String] = data
			let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
			guard addStatus == errSecSuccess else {
				throw KeychainTokenStoreError.addFailed(addStatus)
			}

		default:
			throw KeychainTokenStoreError.updateFailed(updateStatus)
		}
	}

	private func deleteToken(account: String) throws {
		let query = baseQuery(account: account)
		let status = SecItemDelete(query as CFDictionary)

		guard status == errSecSuccess || status == errSecItemNotFound else {
			throw KeychainTokenStoreError.deleteFailed(status)
		}
	}
}
#endif
