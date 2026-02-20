//
//  AsyncStreamableTests.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 10/5/25.
//

import Testing
@testable import ComposableArchitecturePattern

struct AsyncStreamableTests {
    @Test func testMultipleAsyncStreams() async throws {
		let valueToBeStreamed: AsyncStreamable<Int> = .init(value: Int())
		
		try await withThrowingDiscardingTaskGroup { group
			in
			group.addTask {
				var i = 0
				repeat {
					print("Updating values += 1")
					i += 1
					await valueToBeStreamed.update(to: i)
					
					try await Task.sleep(for: .seconds(1))
				} while i < 10
				
				print("Finished. Shutting down the stream.")
				await valueToBeStreamed.shutdown()
			}
			group.addTask {
				let stream1 = await valueToBeStreamed.stream()
				for await value in stream1 {
					print("Stream 1 received value: \(value)")
				}
			}
			group.addTask {
				let stream2 = await valueToBeStreamed.stream()
				for await value in stream2 {
					print("Stream 2 received value: \(value)")
				}
			}
			group.addTask {
				let stream3 = await valueToBeStreamed.stream()
				for await value in stream3 {
					print("Stream 3 received value: \(value)")
				}
			}
		}
    }
}
