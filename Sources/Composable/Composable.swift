import SwiftUI

/// A closure called asynchronously with the given output and throw any error.
public typealias OutputHandler<Output> = (Output) async throws -> Void

public protocol Composable {
	/// The supported actions of a view.
	associatedtype Actions
}

/// A protocol to provide a basis for making the implementation composable.
public protocol ComposableView: View, Composable {
	/// A closure called to handle actions performed in the view.
	var perform: OutputHandler<Actions> { get }
	
	/// Any layout designs to support a view.
	associatedtype Design
}

public protocol ComposableObject: Composable {
	func handle(action: Actions) async throws
}

@attached(member)
@attached(member, names: named(perform), named(Actions), named(Design))
public macro Composable() = #externalMacro(module: "ComposableMacros", type: "ComposableMacro")
