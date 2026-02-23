//
//  ResponseCacheTests.swift
//  ComposableArchitecturePattern
//

import XCTest
@testable import ComposableArchitecturePattern

final class ResponseCacheTests: XCTestCase {
	func testStoreAndRetrieve() async {
		let cache = InMemoryResponseCache()
		let url = URL(string: "https://example.com/data")!
		let data = Data("response".utf8)

		await cache.store(data, for: url, ttl: 60)
		let retrieved = await cache.cachedResponse(for: url)
		XCTAssertEqual(retrieved, data)
	}

	func testCacheMissReturnsNil() async {
		let cache = InMemoryResponseCache()
		let url = URL(string: "https://example.com/missing")!
		let result = await cache.cachedResponse(for: url)
		XCTAssertNil(result)
	}

	func testTTLExpiry() async {
		let cache = InMemoryResponseCache()
		let url = URL(string: "https://example.com/expiring")!
		let data = Data("temporary".utf8)

		// Store with a very short TTL
		await cache.store(data, for: url, ttl: 0.01)

		// Wait for expiry
		try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

		let result = await cache.cachedResponse(for: url)
		XCTAssertNil(result)
	}

	func testMaxEntriesEviction() async {
		let cache = InMemoryResponseCache(defaultTTL: 300, maxEntries: 2)
		let url1 = URL(string: "https://example.com/1")!
		let url2 = URL(string: "https://example.com/2")!
		let url3 = URL(string: "https://example.com/3")!

		await cache.store(Data("a".utf8), for: url1, ttl: 300)
		// Small delay to ensure different storedAt times
		try? await Task.sleep(nanoseconds: 10_000_000)
		await cache.store(Data("b".utf8), for: url2, ttl: 300)
		try? await Task.sleep(nanoseconds: 10_000_000)
		// This should evict url1 (the oldest)
		await cache.store(Data("c".utf8), for: url3, ttl: 300)

		let result1 = await cache.cachedResponse(for: url1)
		let result2 = await cache.cachedResponse(for: url2)
		let result3 = await cache.cachedResponse(for: url3)

		XCTAssertNil(result1, "Oldest entry should be evicted")
		XCTAssertNotNil(result2)
		XCTAssertNotNil(result3)
	}

	func testRemoveCachedResponse() async {
		let cache = InMemoryResponseCache()
		let url = URL(string: "https://example.com/remove")!
		await cache.store(Data("data".utf8), for: url, ttl: 60)

		await cache.removeCachedResponse(for: url)
		let result = await cache.cachedResponse(for: url)
		XCTAssertNil(result)
	}

	func testRemoveAll() async {
		let cache = InMemoryResponseCache()
		let url1 = URL(string: "https://example.com/1")!
		let url2 = URL(string: "https://example.com/2")!

		await cache.store(Data("a".utf8), for: url1, ttl: 60)
		await cache.store(Data("b".utf8), for: url2, ttl: 60)

		await cache.removeAll()

		let result1 = await cache.cachedResponse(for: url1)
		let result2 = await cache.cachedResponse(for: url2)
		XCTAssertNil(result1)
		XCTAssertNil(result2)
	}

	func testUpdatingExistingKeyDoesNotEvict() async {
		let cache = InMemoryResponseCache(defaultTTL: 300, maxEntries: 2)
		let url1 = URL(string: "https://example.com/1")!
		let url2 = URL(string: "https://example.com/2")!

		await cache.store(Data("a".utf8), for: url1, ttl: 300)
		await cache.store(Data("b".utf8), for: url2, ttl: 300)

		// Update url1 — should not evict anything since it's an existing key
		await cache.store(Data("a-updated".utf8), for: url1, ttl: 300)

		let result1 = await cache.cachedResponse(for: url1)
		let result2 = await cache.cachedResponse(for: url2)
		XCTAssertEqual(String(data: result1!, encoding: .utf8), "a-updated")
		XCTAssertNotNil(result2)
	}
}
