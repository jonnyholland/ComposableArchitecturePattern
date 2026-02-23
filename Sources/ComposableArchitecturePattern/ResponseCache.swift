//
//  ResponseCache.swift
//  ComposableArchitecturePattern
//
//  Created by CAP on 2/23/26.
//

import Foundation

/// Caches response data keyed by URL.
public protocol ResponseCache: Sendable {
	/// Returns cached data for the given URL, or nil if not cached or expired.
	func cachedResponse(for url: URL) async -> Data?
	/// Stores response data for the given URL with a time-to-live.
	func store(_ data: Data, for url: URL, ttl: TimeInterval) async
	/// Removes the cached response for the given URL.
	func removeCachedResponse(for url: URL) async
	/// Removes all cached responses.
	func removeAll() async
}

/// An in-memory response cache backed by a dictionary with TTL-based expiry and max entry eviction.
public actor InMemoryResponseCache: ResponseCache {
	private struct Entry {
		let data: Data
		let expiresAt: Date
		let storedAt: Date
	}

	private var cache: [URL: Entry] = [:]
	private let defaultTTL: TimeInterval
	private let maxEntries: Int

	public init(defaultTTL: TimeInterval = 300, maxEntries: Int = 100) {
		self.defaultTTL = defaultTTL
		self.maxEntries = maxEntries
	}

	public func cachedResponse(for url: URL) async -> Data? {
		guard let entry = cache[url] else { return nil }
		if Date() >= entry.expiresAt {
			cache.removeValue(forKey: url)
			return nil
		}
		return entry.data
	}

	public func store(_ data: Data, for url: URL, ttl: TimeInterval) async {
		// Evict oldest entry if at capacity (and not updating an existing key)
		if cache[url] == nil, cache.count >= maxEntries {
			let oldest = cache.min(by: { $0.value.storedAt < $1.value.storedAt })
			if let oldestKey = oldest?.key {
				cache.removeValue(forKey: oldestKey)
			}
		}

		let entry = Entry(data: data, expiresAt: Date().addingTimeInterval(ttl), storedAt: Date())
		cache[url] = entry
	}

	public func removeCachedResponse(for url: URL) async {
		cache.removeValue(forKey: url)
	}

	public func removeAll() async {
		cache.removeAll()
	}
}
