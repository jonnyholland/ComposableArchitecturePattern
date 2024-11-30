//
//  URL+Extensions.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 11/29/24.
//

import Foundation

extension URL {
	/// Returns a URL by appending the specified path to the URL if the specified path is not `nil`, with a hint for handling directory awareness.
	///
	/// - Note: See [appending(path:directoryHint:)](doc://com.apple.documentation/documentation/foundation/url/3988449-appending) for more information about the underlying method.
	/// - Parameter path: The path to add.
	/// - Returns: If `path` is not `nil`, a URL with the appended path component. Otherwise, `self`.
	public func appendingPathIfNotNil(_ path: String?, directoryHint: URL.DirectoryHint = .inferFromPath) -> URL {
		if let path {
			return self.appending(path: path, directoryHint: directoryHint)
		} else {
			return self
		}
	}
}
