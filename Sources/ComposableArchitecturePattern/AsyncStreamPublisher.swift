//
//  AsyncStreamPublisher.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 10/5/25.
//

/// A property wrapper for a value that can handle publishing streams.
@propertyWrapper public struct AsyncStreamPublisher<Value: Sendable>: Sendable {
	public var wrappedValue: Value {
		didSet {
			self._publish(self.wrappedValue)
		}
	}
	
	/// Create a new `AsyncStreamPublisher` with the specified value.
	public init(wrappedValue: Value) {
		self.wrappedValue = wrappedValue
	}
	
	/// A new stream for the underlying value.
	public mutating func newStream(withTerminationHandler: (@Sendable (AsyncStream<Value>.Continuation.Termination) -> Void)? = nil) -> AsyncStream<Value> {
		AsyncStream { continuation in
			self._streams.append(continuation)
			continuation.yield(self.wrappedValue)
			continuation.onTermination = withTerminationHandler
		}
	}
	
	/// The streams that have been created to listen to the underlying value.
	private var _streams: [AsyncStream<Value>.Continuation] = []
	
	/// Publish the new value to the streams.
	private func _publish(_ value: Value) {
		for continuation in self._streams {
			continuation.yield(value)
		}
	}
}
