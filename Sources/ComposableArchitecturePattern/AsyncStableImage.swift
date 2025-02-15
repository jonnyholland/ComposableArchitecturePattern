//
//  AsyncStableImage.swift
//  ComposableArchitecturePattern
//
//  Created by Jonathan Holland on 2/14/25.
//

import SwiftUI

/// Displays an image from the specified URL owned by the view.
///
/// The difference between `AsyncStableImage` and `AsyncImage` is this view loads the image once and then doesn't refresh unless manually done so.
public struct AsyncStableImage<ImageContent: View, Placeholder: View>: View {
	// MARK: Injected properties
	let url: URL?
	let imageClosure: (Image?, Error?) -> ImageContent
	let placeholderClosure: Placeholder?
	
	/// Create a new `AsyncStableImage`.
	/// - Parameters:
	/// 	- url: The URL the image is located at.
	/// 	- imageView: A closure to build content for the image passed into it.
	/// 	- placeholderView: A view to display while the image is loading.
	public init(
		url: URL?,
		imageView: @escaping (Image?, Error?) -> ImageContent,
		placeholderView: Placeholder?
	) {
		self.url = url
		self.imageClosure = imageView
		self.placeholderClosure = placeholderView
	}
	
	// MARK: Local properties
	@State private var refreshID = UUID()
	@State private var isLoading = true
	@State private var image: Image?
	@State private var error: Error?
	
	public var body: some View {
		self.contentView
			.task(
				id: self.refreshID,
				{
					if let url {
						defer {
							self.isLoading = false
						}
						self.error = nil
						self.isLoading = true
						do {
							let (data, _) = try await URLSession.shared.data(from: url)
#if os(macOS)
							if let nsImage = NSImage(data: data) {
								self.image = Image(nsImage: nsImage)
							}
#else
							if let uiImage = UIImage(data: data) {
								self.image = Image(uiImage: uiImage)
							}
#endif
						} catch {
							self.error = error
						}
					}
				}
			)
	}
	
	@ViewBuilder
	private var contentView: some View {
		if self.isLoading {
			self.placeholderClosure
		} else {
			self.imageClosure(self.image, self.error)
		}
	}
}
