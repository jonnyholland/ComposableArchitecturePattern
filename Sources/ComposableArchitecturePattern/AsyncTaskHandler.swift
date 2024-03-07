//
//  AsyncTaskHandler.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 3/7/24.
//

import Foundation

@Observable
open class AsyncTaskHandler<T: Equatable> {
	var id: T?
	var task: Task<Any, Error>?
	
	/// Designated initializer.
	public init(id: T? = nil, task: Task<Any, Error>? = nil) {
		self.id = id
		self.task = task
	}
	
	/// Performs the given closure in a new task.
	///
	/// This will also cancel any previous task.
	public func performAction(actionHandler: @escaping () async -> Void) {
		if let task {
			task.cancel()
		}
		
		let actionHandler = actionHandler
		self.task = Task {
			await actionHandler()
		}
	}
	
	/// Nullifies `id` and requests `task` to cancel.
	public func cancel() {
		self.id = nil
		self.task?.cancel()
	}
}
