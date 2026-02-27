import Foundation

/// A pair of access and refresh tokens for authenticated API requests.
public struct TokenPair: Sendable {
	public var accessToken: Token
	public var refreshToken: Token

	public init(accessToken: Token, refreshToken: Token) {
		self.accessToken = accessToken
		self.refreshToken = refreshToken
	}

	/// Whether the access token has a valid, non-expired value.
	public var isAccessValid: Bool {
		accessToken.isValid
	}

	/// Whether the refresh token has a valid, non-expired value.
	public var canRefresh: Bool {
		refreshToken.isValid
	}
}
