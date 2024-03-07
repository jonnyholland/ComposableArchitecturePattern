import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct ComposablePlugin: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
		ComposableMacro.self
    ]
}

public struct ComposableMacro: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		if let structDecl = declaration.as(StructDeclSyntax.self) {
			if structDecl.inheritanceClause == InheritanceClauseSyntax(
				IdentifierTypeSyntax(
					name: .identifier("View")
				)
			) {
				return [
					"let perform: OutputHandler<Actions>"
				]
			}
		}
		return []
	}
}

extension ComposableMacro: ExtensionMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		if let structDecl = declaration.as(StructDeclSyntax.self) {
			if structDecl.inheritanceClause == InheritanceClauseSyntax(
				IdentifierTypeSyntax(
					name: .identifier("View")
				)
			) {
				let equatableExtension = try ExtensionDeclSyntax("extension \(type.trimmed): ComposableView {}")
				return [equatableExtension]
			} else {
				let equatableExtension = try ExtensionDeclSyntax("extension \(type.trimmed): Composable {}")
				return [equatableExtension]
			}
		} else if (declaration.as(ClassDeclSyntax.self) != nil) {
			let equatableExtension = try ExtensionDeclSyntax("extension \(type.trimmed): ComposableObject {}")
			return [equatableExtension]
		} else if (declaration.as(EnumDeclSyntax.self) != nil) {
			let equatableExtension = try ExtensionDeclSyntax("extension \(type.trimmed): Composable {}")
			return [equatableExtension]
		}
		return []
	}
}
