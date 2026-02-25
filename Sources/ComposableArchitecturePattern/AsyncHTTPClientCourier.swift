//
//  AsyncHTTPClientCourier.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 2/21/26.
//

#if canImport(AsyncHTTPClient)
import AsyncHTTPClient
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import NIOCore
import Logging

/// An actor that couriers requests using `AsyncHTTPClient.HTTPClient`.
public actor AsyncHTTPClientCourier: Courier {
	/// A shared instance that can be used for couriering requests.
	public static let shared = AsyncHTTPClientCourier()

	/// The `HTTPClient` to use for all server calls.
	public let client: HTTPClient

	/// The timeout for each request.
	public var timeout: TimeAmount

	/// The maximum response body size in bytes. Defaults to 10MB.
	public var maxResponseSize: Int

	/// The logger to use with communicating server courier activity.
	lazy var logger = Logger(label: "com.CAP.AsyncHTTPClientCourier")

	/// Whether or not to log all activity with this server.
	var logActivity: LogActivity

	/// Designated initializer.
	/// - Parameters:
	///   - client: The `HTTPClient` to use for making requests.
	///   - timeout: The timeout for each request. Defaults to 60 seconds.
	///   - maxResponseSize: The maximum response body size in bytes. Defaults to 10MB.
	///   - logActivity: The log activity to use for processing requests.
	public init(client: HTTPClient = .shared, timeout: TimeAmount = .seconds(60), maxResponseSize: Int = 1024 * 1024 * 10, logActivity: LogActivity = .all) {
		self.client = client
		self.timeout = timeout
		self.maxResponseSize = maxResponseSize
		self.logActivity = logActivity
	}

	public func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Data? {
		guard let url = request.url else {
			throw ServerAPIError.badRequest(description: "URLRequest has no URL.")
		}

		if self.logActivity == .all {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(url.absoluteString) [Start]")
		}

		var httpRequest = HTTPClientRequest(url: url.absoluteString)
		httpRequest.method = .init(rawValue: request.httpMethod ?? "GET")

		if let allHTTPHeaderFields = request.allHTTPHeaderFields {
			for (key, value) in allHTTPHeaderFields {
				httpRequest.headers.add(name: key, value: value)
			}
		}

		if let body = request.httpBody {
			httpRequest.body = .bytes(body)
		}

		let response = try await self.client.execute(httpRequest, timeout: self.timeout)

		if self.logActivity == .all {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(url.absoluteString) [Finish]")
		}

		var responseBody = try await response.body.collect(upTo: self.maxResponseSize)
		let data = responseBody.readData(length: responseBody.readableBytes) ?? Data()
		let statusCode = Int(response.status.code)

		switch statusCode {
			case 200...299:
				break
			case 100...199:
				throw ServerAPIError.unknown(description: "Informational response: \(statusCode)")
			case 401:
				self.logger.error("\(Date()) - (\(requestUID)) Request to \(url.absoluteString) { Unauthorized: \(statusCode) }")
				throw ServerAPIError.unauthorized(description: "HTTP 401")
			case 400...499:
				self.logger.error("\(Date()) - (\(requestUID)) Request to \(url.absoluteString) { Failed: \(statusCode) }")
				throw ServerAPIError.network(description: "HTTP \(statusCode)")
			case 500...599:
				self.logger.error("\(Date()) - (\(requestUID)) Request to \(url.absoluteString) { Failed: \(statusCode) }")
				throw ServerAPIError.server(description: "HTTP \(statusCode)", httpStatusCode: statusCode)
			default:
				self.logger.error("\(Date()) - (\(requestUID)) Request to \(url.absoluteString) { Failed: \(statusCode) }")
				throw ServerAPIError.unknown(description: "Unknown HTTP status: \(statusCode)")
		}

		if self.logActivity == .all {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(url.absoluteString) { Success }")
		}

		return data
	}
}
#endif
