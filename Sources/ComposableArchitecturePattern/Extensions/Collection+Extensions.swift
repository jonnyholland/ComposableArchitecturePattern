//
//  Collection+Extensions.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 2/14/25.
//

import Foundation

extension Collection {
	/// The element at the given index.
	/// - Parameter index: The index of the element.
	/// - Returns: The element at the given index or `nil` if the index isn't valid.
	/// - Complexity: O(1)
	public subscript(safe index: Index) -> Element? {
		self.indices.contains(index) ? self[index] : nil
	}
}
