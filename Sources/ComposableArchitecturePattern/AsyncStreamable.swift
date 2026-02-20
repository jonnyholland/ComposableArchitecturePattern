//
//  AsyncStreamable.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 10/5/25.
//

/// A protocol for streaming a value.
public protocol _AsyncStreamable {
	associatedtype Value: Sendable
	/// The underlying value to be streamed.
	var value: AsyncStreamPublisher<Value> { get }
}

/// An actor to handle streaming for a value.
public actor AsyncStreamable<T: Sendable>: _AsyncStreamable {
	nonisolated(unsafe) public var value: AsyncStreamPublisher<T>
	
	/// Create a new `AsyncStreamable` with the specified `AsyncStreamPublisher`.
	public init(value: AsyncStreamPublisher<T>) {
		self.value = value
	}
	
	/// Create a new `AsyncStreamable` with the specified underlying value.
	public init(value: T) {
		self.value = AsyncStreamPublisher(wrappedValue: value)
	}
	
	/// Update the underlying value with the new value.
	public func update(to newValue: T) {
		self.value.wrappedValue = newValue
	}
	
	/// A new stream on the underlying value, specifying any termination action to be performed during termination.
	public func stream(withTerminationHandler: (@Sendable (AsyncStream<Value>.Continuation.Termination) -> Void)? = nil) async -> AsyncStream<T> {
		self.value.newStream(withTerminationHandler: withTerminationHandler)
	}
	
	/// Shutsdown the stream by terminating the streams.
	public func shutdown() {
		self.value.shutdown()
	}
}
