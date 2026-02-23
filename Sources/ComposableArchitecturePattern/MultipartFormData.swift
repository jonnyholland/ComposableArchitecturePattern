//
//  MultipartFormData.swift
//  ComposableArchitecturePattern
//
//  Created by CAP on 2/23/26.
//

import Foundation

/// A multipart/form-data body builder for HTTP uploads.
public struct MultipartFormData: Sendable {
	/// A single part in a multipart form data body.
	public struct Part: Sendable {
		public let name: String
		public let data: Data
		public let filename: String?
		public let mimeType: String?

		public init(name: String, data: Data, filename: String? = nil, mimeType: String? = nil) {
			self.name = name
			self.data = data
			self.filename = filename
			self.mimeType = mimeType
		}
	}

	private let boundary: String
	private var parts: [Part] = []

	public init(boundary: String = UUID().uuidString) {
		self.boundary = boundary
	}

	/// The Content-Type header value including the boundary.
	public var contentType: String {
		"multipart/form-data; boundary=\(boundary)"
	}

	/// Adds a text field.
	public mutating func addField(named name: String, value: String) {
		let data = Data(value.utf8)
		parts.append(Part(name: name, data: data))
	}

	/// Adds a file part.
	public mutating func addFile(named name: String, filename: String, mimeType: String, data: Data) {
		parts.append(Part(name: name, data: data, filename: filename, mimeType: mimeType))
	}

	/// Adds an arbitrary part.
	public mutating func addPart(_ part: Part) {
		parts.append(part)
	}

	/// Encodes all parts into the multipart/form-data body.
	public func encode() -> Data {
		var body = Data()

		for part in parts {
			body._append("--\(boundary)\r\n")

			if let filename = part.filename, let mimeType = part.mimeType {
				body._append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(filename)\"\r\n")
				body._append("Content-Type: \(mimeType)\r\n")
			} else {
				body._append("Content-Disposition: form-data; name=\"\(part.name)\"\r\n")
			}

			body._append("\r\n")
			body.append(part.data)
			body._append("\r\n")
		}

		body._append("--\(boundary)--\r\n")

		return body
	}
}

extension Data {
	mutating func _append(_ string: String) {
		if let data = string.data(using: .utf8) {
			append(data)
		}
	}
}
