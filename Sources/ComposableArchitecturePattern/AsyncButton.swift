//
//  AsyncButton.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 3/7/24.
//

import SwiftUI

/// Displays a button with the specified label and calls the action closure when the button is triggered.
public struct AsyncButton<Label: View>: View {
	private var tasker: AsyncTaskHandler<UUID>
	
	let action: () async -> Void
	let label: () -> Label
	
	/// Create a new async button with the given action closure and label.
	public init(taskHandler: AsyncTaskHandler<UUID> = AsyncTaskHandler<UUID>(), action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
		self.tasker = taskHandler
		self.action = action
		self.label = label
	}
	
    public var body: some View {
		Button(
			action: {
				self.tasker.id = UUID()
			},
			label: self.label
		)
		.task(id: self.tasker.id, priority: .userInitiated) {
			await self.action()
		}
    }
	
	/// Creates a new instance of async button but requests the task handler to cancel the task before returning.
	///
	/// Use this method when you want to cancel a task that has already started and you don't have access to the task handler.
	public func cancelTask(_ value: Bool) -> Self {
		let newSelf = self
		if value {
			self.tasker.cancel()
		}
		return newSelf
	}
}
