//
//  ServerEnvironment.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

/// A server environment with url path.
public enum ServerEnvironment: Hashable, CustomStringConvertible {
	/// A development environment.
	case development(url: String)
	/// A local environment.
	case local(url: String)
	/// A production environment.
	case production(url: String)
	/// A test environment.
	case test(url: String)
	
	public var description: String {
		switch self {
			case let .development(url),
				 let .local(url),
				 let .production(url),
				 let .test(url):
				return url
		}
	}
	
	/// A url from the environment path.
	public var url: URL? {
		switch self {
			case let .development(url),
				 let .local(url),
				 let .production(url),
				 let .test(url):
				return URL(string: url)
		}
	}
}
