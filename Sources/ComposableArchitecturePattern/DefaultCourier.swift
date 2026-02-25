//
//  DefaultCourier.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 12/8/24.
//

#if canImport(Darwin)
import Foundation
import Logging

/// An actor that can be used for couriering requests.
public actor DefaultCourier: Courier {
	/// A shared instance that can be used for couriering requests.
	public static let shared = DefaultCourier()

	/// The `URLSession` to use for all server calls.
	public var urlSession: URLSession

	/// The logger to use with communicating server courier activity.
	lazy var logger = Logger(label: "com.CAP.DefaultCourier")

	/// Whether or not to log all activity wtih this server.
	var logActivity: LogActivity

	/// Designated initializer.
	/// - Parameters:
	/// 	- urlSession: The session to use for making external calls.
	/// 	- logActivity: The log activity to use for processing requests.
	public init(urlSession: URLSession = .shared, logActivity: LogActivity = .all) {
		self.urlSession = urlSession
		self.logActivity = logActivity
	}

	public func sendRequest(_ request: URLRequest, requestUID: UUID) async throws -> Data? {
		if self.logActivity == .all {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Start]")
		}

		let (data, response) = try await self.urlSession.data(for: request)

		if self.logActivity == .all {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) [Finish]")
		}

		guard try response.analyzeAsHTTPResponse() else {
			self.logger.error("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) { Failed }")
			throw ServerAPIError.unknown(description: "Unable to complete server response.")
		}

		if self.logActivity == .all {
			self.logger.info("\(Date()) - (\(requestUID)) Request to \(String(describing: request.url?.description)) { Success }")
		}

		return data
	}
}
#endif
