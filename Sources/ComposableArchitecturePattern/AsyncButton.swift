//
//  AsyncButton.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 2/14/25.
//

import os
import SwiftUI

/// An action that runs asynchronously.
public typealias AsyncAction = @Sendable () async -> Void

/// An action that runs asynchronously and throws errors.
public typealias AsyncThrowsAction = @Sendable () async throws -> Void

public enum AsyncActionState {
	case idle
	case finished
	case running
}

/// Displays a button and runs the specified action asynchronously.
public struct AsyncButton<Label: View>: View {
	/// Create a new `AsyncButton`.
	public init(
		buttonRole: ButtonRole?,
		action: @escaping AsyncAction,
		label: Label
	) {
		self.buttonRole = buttonRole
		self.action = action
		self.label = label
	}
	
	// MARK: Injected properties
	let buttonRole: ButtonRole?
	let action: AsyncAction
	let label: Label
	
	// MARK: Local properties
	@State private var taskID = UUID()
	@State private var state: AsyncActionState = .idle
	private var detachTask = false
	private var loggerClosure: ((AsyncActionState) -> Void)?
	private let logger = Logger()
	
	public var body: some View {
		Button {
			if self.detachTask {
				Task.detached {
					await self.action()
				}
			} else {
				self.state = .idle
				self.taskID = UUID()
				self.logger.info("\(Date()) [AsyncButton] - Action invoked. Task id: \(self.taskID)")
			}
		} label: {
			self.label
		}
		.task(
			id: self.taskID,
			{
				guard !self.detachTask else {
					return
				}
				
				self.state = .running
				self.logger.info("\(Date()) [AsyncButton] - Running task...")
				
				await self.action()
				
				self.state = .finished
				self.logger.info("\(Date()) [AsyncButton] - Finished running task.")
			}
		)
	}
	
	/// Detach the task action from the view.
	public func detachTask(_ value: Bool) -> Self {
		var newSelf = self
		newSelf.detachTask = value
		return newSelf
	}
	
	/// Get logger state information about the task running.
	public func logger(_ logger: @escaping (AsyncActionState) -> Void) -> Self {
		var newSelf = self
		newSelf.loggerClosure = logger
		return newSelf
	}
}
