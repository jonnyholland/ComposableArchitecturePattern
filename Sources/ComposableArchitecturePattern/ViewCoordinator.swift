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
	var statusStream: AsyncStream<CoordinatorStatus<Actions, Results>> { get }
	
	/// An enumeration of supported actions of the coordinator.
	associatedtype Actions
	/// Perform the specified enum action asynchronously.
	@discardableResult
	func perform(action: Actions) async throws -> Results
}

extension Coordinator {
	public func load() async {}
	public func reload() async {}
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
	case actionHandled(action: A, result: R)
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
