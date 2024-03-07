//
//  ServerEnvironment.swift
//  ComposableViewPattern
//
//  Created by Jonathan Holland on 1/01/24.
//

import Foundation

public enum ServerEnvironment: Hashable, CustomStringConvertible {
	case development(url: String)
	case local(url: String)
	case production(url: String)
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
