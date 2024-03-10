//
//  ViewCoordinator.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 3/9/24.
//

import SwiftUI

public protocol ViewCoordinator {
	associatedtype ContentView: View
	var view: ContentView { get }
	var state: ViewCoordinatorState { get }
	
	func load() async
	func reload() async
}

extension ViewCoordinator {
	public func load() async {}
	public func reload() async {}
}

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
