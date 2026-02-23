//
//  MultipartFormDataTests.swift
//  ComposableArchitecturePattern
//

import XCTest
@testable import ComposableArchitecturePattern

final class MultipartFormDataTests: XCTestCase {
	func testContentTypeIncludesBoundary() {
		let form = MultipartFormData(boundary: "test-boundary")
		XCTAssertEqual(form.contentType, "multipart/form-data; boundary=test-boundary")
	}

	func testAddFieldEncodesCorrectly() {
		var form = MultipartFormData(boundary: "BOUNDARY")
		form.addField(named: "username", value: "john")
		let encoded = form.encode()
		let body = String(data: encoded, encoding: .utf8)!

		XCTAssertTrue(body.contains("--BOUNDARY\r\n"))
		XCTAssertTrue(body.contains("Content-Disposition: form-data; name=\"username\"\r\n"))
		XCTAssertTrue(body.contains("\r\njohn\r\n"))
		XCTAssertTrue(body.contains("--BOUNDARY--\r\n"))
	}

	func testAddFileEncodesCorrectly() {
		var form = MultipartFormData(boundary: "BOUNDARY")
		let fileData = Data("file-content".utf8)
		form.addFile(named: "avatar", filename: "photo.png", mimeType: "image/png", data: fileData)
		let encoded = form.encode()
		let body = String(data: encoded, encoding: .utf8)!

		XCTAssertTrue(body.contains("Content-Disposition: form-data; name=\"avatar\"; filename=\"photo.png\"\r\n"))
		XCTAssertTrue(body.contains("Content-Type: image/png\r\n"))
		XCTAssertTrue(body.contains("file-content"))
	}

	func testMultiplePartsEncodeInOrder() {
		var form = MultipartFormData(boundary: "B")
		form.addField(named: "first", value: "1")
		form.addField(named: "second", value: "2")
		let body = String(data: form.encode(), encoding: .utf8)!

		let firstRange = body.range(of: "first")!
		let secondRange = body.range(of: "second")!
		XCTAssertTrue(firstRange.lowerBound < secondRange.lowerBound)
	}

	func testEmptyFormStillHasClosingBoundary() {
		let form = MultipartFormData(boundary: "B")
		let body = String(data: form.encode(), encoding: .utf8)!
		XCTAssertEqual(body, "--B--\r\n")
	}

	func testAddPartDirectly() {
		var form = MultipartFormData(boundary: "B")
		let part = MultipartFormData.Part(name: "data", data: Data("hello".utf8), filename: "hello.txt", mimeType: "text/plain")
		form.addPart(part)
		let body = String(data: form.encode(), encoding: .utf8)!
		XCTAssertTrue(body.contains("filename=\"hello.txt\""))
		XCTAssertTrue(body.contains("Content-Type: text/plain"))
	}
}
