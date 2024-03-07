# Composable Architecture Pattern (CAP)

This package is designed to demonstrate how to build composable views and code so the views and code can be testable, scalable, and reusable. This also provides a library that's intended to very basic so you don't have to learn the library or use CAP as a framework but rather as a source you can dip into and use when you want or need to.

Composable means self-sustained (1), which means each view should be able to sustain itself. In order to do that the view should have an approach that allows actions in the view to be testable. This means giving the view what it needs so it can be testable, no more no less. This also means architecting our code so we can have a separation of concerns so we're not passing around large view models or objects into each view. There's several ways this can be done and will be discussed below.

You'll notice this is called a "pattern". This is because I believe software architecture always needs guidance but not always a library or framework. This approach allows you to make use of the architecture pattern and the library as you see fit. While being light and overall easy to use, writing good code takes time and effort and your goal should be to improve as a developer to architect safe code that hopefully is scalable and reusable.

## Get Started
It would behoove you to read through [Core Principles](#core-principles) to fully understand the overall logic behind this architecture pattern. 

## Core Principles
1. Composable
Each object and view should be composable, which means self-contained. So, we should avoid large complex views that are heavily dependent upon another view or on a specific object. There's several ways we can accomplish this:

a.) Protocols. This is a great way of isolating the view to whatever we define in the protocol so the view can be used anywhere that can conform and provide what the protocol entails.
```swift
protocol UserData {
	var imageURL: URL? { get }
	var name: String { get }
	var info: String? { get }
}

struct UserCell<User: UserData>: View {
	let user: User
	
	var body: some View {
		HStack {
			AsyncImage(url: user.imageURL)
			
			VStack(alignment: .leading) {
				Text(user.name)
				
				if let info = self.user.info {
					Text(info)
						.foregroundStyle(.secondary)
				}
			}
		}
	}
}
```

We could take this further by also applying actions to the view.
```swift
enum ImageAction {
	case change
	case remove
}

protocol ImageData {
	var imageURL: URL? { get set }
}

struct ImageViewer<Image: ImageData, Action: ImageAction>: View {
	typealias ActionHandler = (Action) async throws -> Void // This can also return a `Bool` or whatever you want.
	
	let image: Image
	let handle: ActionHandler
	
	var body: some View {
		AsyncImage(url: image.imageURL)
			.contextMenu {
				Button("Remove") {
					Task {
						// We don't do anything with any error but in production you definitely should.
						try? await handle(.remove)
					}
				}
			}
	}
}
```

b.) Predetermined values or models with actions. This is a similar approach to protocols but here we pass in an object or values that aren't specific to any protocol but are specific in what must be used.
Here we will use specific values:
```swift
enum ImageAction {
	case change
	case remove
}

struct ImageViewer: View {
	typealias ActionHandler = (ImageAction) async throws -> Void // This can also return a `Bool` or whatever you want.
	
	let imageURL: URL?
	let handle: ActionHandler

	var body: some View {
		AsyncImage(url: self.imageURL)
			.contextMenu {
				Button("Remove") {
					Task {
						// We don't do anything with any error but in production you definitely should.
						try? await handle(.remove)
					}
				}
			}
	}
}

struct UserCell: View {
	...
	@State private var imageURL: URL?
	
	var body: some View {
		ImageViewer(
			imageURL: self.imageURL,
			handle: { action in
				switch action {
					case .change:
						// Present view to change the image.
					...
				}
			}
	}
}
```

Here we will use an object
```swift
@Observable // Only available in Swift 5.9 -> iOS 17, macOS 14
class ImageModel: ObservableObject {
	var imageURL: URL? // Will need to use @Published wrapper if not using @Observable macro.
}

struct ImageViewer: View {
	typealias ActionHandler = (ImageAction) async throws -> Void // This can also return a `Bool` or whatever you want.
	
	var model: ImageModel
	let handle: ActionHandler

	var body: some View {
		AsyncImage(url: self.model.imageURL)
			.contextMenu {
				Button("Remove") {
					Task {
						// We don't do anything with any error but in production you definitely should.
						try? await handle(.remove)
					}
				}
			}
	}
}

struct UserCell: View {
	...
	var imageModel: ImageModel // If not using @Observable macro, this will need to use @ObservedObject.
	
	var body: some View {
		ImageViewer(
			imageURL: self.imageModel, // This could also be referenced from a user model like: `self.userModel.imageModel`.
			handle: { action in
				switch action {
					case .change:
						// Present view to change the image.
					...
				}
			}
	}
}
```

As you can see there's parts of this that could get repetitive, such as using class objects for each view.

## References
1. (Composability - Wikipedia)[https://en.wikipedia.org/wiki/Composability]
