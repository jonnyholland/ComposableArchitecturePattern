//
//  ViewCoordinator.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 3/9/24.
//

import SwiftUI

/// An object that acts as a coordinator.
public protocol Coordinator {
	/// The current state of the coordinator.
	var state: CoordinatorState { get }
	
	/// Load the coordinator with any logic of setup necessary for its operation.
	func load() async
	/// Perform any necessary function to reload the coordinator.
	func reload() async
	
	/// An enumeration of expected results
	associatedtype Results
	/// A stream of current events corresponding to the coordinator's status.
	///
	/// This stream is useful to react to the coordinator's change in status, such as when the coordinator is finished loading or if the coordinator needs to reload.
	var statusStream: AsyncStream<CoordinatorStatus<Actions, Results>> { get }
	
	/// An enumeration of supported actions of the coordinator.
	associatedtype Actions
	/// Perform the specified enum action asynchronously.
	/// - Returns: The specified result.
	@discardableResult
	func perform(action: Actions) async throws -> Results
	
	/// Perform the specified enum action asynchronously.
	@available(*, deprecated, message: "This method has been deprecated. Use `perform(action:) -> Results` instead.")
	func perform(action: Actions) async throws
	
	/// An enumeration of actions to sync to.
	associatedtype SyncActions
	/// Sync the coordinator to the specified stream.
	///
	/// Use this if there is some action or function that is dependent upon some other coordinator's `statusStream` or some other asynchronous stream.
	func sync(to stream: AsyncStream<SyncActions>)
}

extension Coordinator {
	public func load() async {}
	public func reload() async {}
}

public enum EmptyActions {}
public enum EmptyResults {}

extension Coordinator {
	public var statusStream: AsyncStream<CoordinatorStatus<EmptyActions, EmptyResults>> {
		AsyncStream { _ in }
	}
	
	public func perform(action: EmptyActions) async throws -> EmptyResults {}
	
	public func peform(action: EmptyActions) async throws {}
	
	public func sync(to stream: AsyncStream<EmptyActions>) {}
}

/// The state of the coordinator.
public enum CoordinatorState: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		if case let .error(lhsError, lhsDescription) = lhs, case let .error(rhsError, rhsDescription) = rhs {
			return lhsError?.localizedDescription == rhsError?.localizedDescription || lhsDescription == rhsDescription
		} else if case .idle = lhs, case .idle = rhs {
			return true
		} else if case .loaded = lhs, case .loaded = rhs {
			return true
		} else if case .needsReload = lhs, case .needsReload = rhs {
			return true
		}
		return false
	}
	
	/// The coordinator is in idle mode.
	case idle
	/// The coordinator has fully loaded and is operational.
	case loaded
	/// The coordinator is in a state that needs reload.
	case needsReload
	/// The coordinator is in an error state.
	case error(error: Error? = nil, description: String? = nil)
}

public enum CoordinatorStatus<A, R> {
	/// The specified action was handled by the coordinator with the specified result. `result` is defaulted to `nil` because there may be scenarios where you don't want to expose the result of the action, such as when a coordinator may be handling sensitive data or data that is irrelevant outside the context of the coordinator.
	case actionHandled(action: A, result: R? = nil)
	/// The coordinator's state was updated to the specified new state.
	case stateUpdated(newState: CoordinatorState)
}

/// An object that coordinates between view, networking, or other logic
public protocol ViewCoordinator: Coordinator {
	associatedtype ContentView: View
	/// What the coordinator displays as its main content
	var view: ContentView { get }
}

@available(*, renamed: "CoordinatorState")
public enum ViewCoordinatorState: Equatable {
	public static func == (lhs: ViewCoordinatorState, rhs: ViewCoordinatorState) -> Bool {
		if case let .error(lhsError) = lhs, case let .error(rhsError) = rhs {
			return lhsError?.localizedDescription == rhsError?.localizedDescription
		} else if case .idle = lhs, case .idle = rhs {
			return true
		} else if case .loaded = lhs, case .loaded = rhs {
			return true
		} else if case .needsReload = lhs, case .needsReload = rhs {
			return true
		}
		return false
	}
	
	case idle
	case loaded
	case needsReload
	case error(error: Error? = nil)
}
