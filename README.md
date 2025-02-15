# Composable Architecture Pattern (CAP)

This package is designed to give you free code to make your projects, apps, and development more composable, testable, and scalable, as well as to demonstrate how to build composable views and code. The included library contains a robust collection of networking objects and patterns that's intended to help you get going quickly and confidently. A list demos showing how to use CAP can be found in [Demo Apps](#demo-apps) and a growing list of composable contributions can be found in [Great Community Examples](#great-community-examples).

Why CAP? Well, since I've been developing apps in SwiftUI since 2019, one thing had become very clear to me: there's really not a great way of architecting SwiftUI apps without using older, mostly irrelevant methodologies, such as MVVM. Additionally, I saw bad habits: large observable objects being passed around from view to view or worse yet each view getting an observable object when that's not really necessary. CAP is designed to fix this by giving general guidelines (protocols) to use to structure and guide your code. See demo apps for examples: [Demo Apps](#demo-apps).

Composable means self-sustained<sup>1</sup>, which means each view should be able to sustain itself. In order to do that the view should have an approach that allows actions in the view to be testable. This means giving the view what it needs so it can be testable where objects, values, actions performed in the view can be tested in a straightfoward way. This also means architecting our code so we can have a separation of concerns so we're not passing around large view models or objects into each view. There's several ways this can be done and will be discussed below.

You'll notice this is called a "pattern". This is because I believe software architecture always needs guidance but not always a library or framework. This approach allows you to make use of the architecture pattern and the library as you see fit. While being light and overall easy to use, writing good code takes time and effort and your goal should be to improve as a developer to architect safe code that hopefully is scalable and reusable.

## Get Started
It would behoove you to read through [Core Principles](#core-principles) to fully understand the overall logic behind this architecture pattern. 

## Demo Apps
- [NY Times News](https://github.com/jonnyholland/NY-Times-News/tree/main)
- [Harvard Art Museum](https://github.com/jonnyholland/HarvardArt/tree/main)

**Community-driven apps**
- [Marvel](https://github.com/NathanRUbeda/Marvel) by Nathan Ubeda
- [TwitchStream](https://github.com/NathanRUbeda/TwitchStream) by Nathan Ubeda

## Core Principles
1. Composable. Each object and view should be composable, which means self-contained. So, we should avoid large complex views that are heavily dependent upon another view or on a specific object. Only give views what they need. It's imperative that your approach towards architecture be one of adapatability. I can't emphasize this enough: **Not all situations are the same. Not all situations require the exact same approach**. I have seen the mistake of forcing the same approach and same template for views in a SwiftUI app more times than I can count and this is a big mistake and, in my opinion, displays a lack of understanding how SwiftUI is designed to operate.

Instead, use the ever popular acronym: KISS (insert clip of Dwight telling Ryan about Michael telling him this and it hurting his feelings) - Rather than the traditional acronym explanation instead use it like this: **K**eep **I**t **S**tupid **S**imple. The goal here is for the architecture and views to be as simple as possible so as complexity grows your work doesn't necessarily grow in complexity.

Therefore, you will need to look at each view from the perspective of "what's the minimal amount that needs to be here?". That's always easier said than done and easier in theory than practice. So, what I usually do when I'm unsure how to architect a view and understand it's needs and whether or not it needs to be reusable, etc: do whatever you need to get the view/feature working, then be a harsh critic and determine how to break down any views or features within the view and how to scope the work so it's clearly understandable by yourself and others later on.

2. Testability. Make sure your code is testable, actually functionally testable. This requires you to approach objects, views, and overall architure from the perspective of being able to easily test it.

I would like to point out that testing your code is only going to get you so far. In fact, **testability should never come at the cost of stable features/views or eat up loads of development time**. As odd as it may seem, sometimes testability directly impacts quality because the code logic and architecture can become so fragmented that it becomes difficult to work with the code or reliably build out features without heavy/complex overhead or time unit testing simple/basic stuff.

Remember, there's only so much you can test and there's always something you'll miss or the user will expose. The point here is to do your best but don't go overboard. For instance, testing objects returned from a web service is highly valuable and crucial. But, you shouldn't be creating complex objects to handle web service responses, outside of perahps some extreme circumstance. The goal should be to rely on built-in language features to your benefit and make the response objects as straightforward as possible so you don't have to eat up precious development time on tests for a custom decoder/encoder to figure out why it's failing. 

If you lay the groundwork for and shape your mind towards testability, you'll find testing can be very easy and fun. Building a unit test will feel more rewarding and less like chess game or figuring out the right pieces to get it to work.

3. Reliability. Architect your code, app, and views so it's reliable. This may seem like a simple thing to point out but it's surprising how often this gets lost in the thought of architecting solutions. This means, again, avoiding massive objects with complex code that's difficult to track things, understand, or scale.

## Understanding and using CAP

### Providers, Servers, APIs
CAP's nomenclature is to use "server"s to define overall functionality specific to a server and "api"s for individual API's to be consumed or interacted with. The design here is to break up key elements of this mechanism so it's as clear as possible, while also being as testable as possible; meaning, we want this to scale easily while also being easy to work with. 

I personally like the following architecture for networking: Provider: Protocol (consumed by a view, view model, or coordinator) > Server > API. This allows the consumer of the protocol to not care about how the provider is defining its implementation and the implementation of any server or api.

```swift
import ComposableArchitecturePattern

protocol UserProvider {
    func getUserInfo() async throws -> UserInfoResponse
    func updateUserInfo(with request: UserInfoUpdate) async throws
}

struct UserInfoAPI: ServerAPI {
    let id = UUID()
    var environment: ServerEnvironment? = ServerAPIConstants.productionEnvironment
    var path: String = "user/info"
    var supportedHTTPMethods: [HTTPMethod] = [.GET, .PUT]
    var supportedReturnObjects: [Decodable.Type]? = [UserInfoResponse.self]
}

actor CoreServer: Server {
    static let userInfoAPI = UserInfoAPI()

    var environments: [ServerEnvironment] = [ServerAPIConstants.productionEnvironment]
    lazy var currentEnvironment: ServerEnvironment? = ServerAPIConstants.productionEnvironment
    var requestsBeingProcessed = Set<UUID>()
    var apis: [any ServerAPI] = [Self.userInfoAPI]

    func getUserInfo() async throws -> UserInfoResponse {
	return self.get(using: Self.userInfoAPI)
    }
    func updateUserInfo(with request: UserInfoUpdate) async throws {
	return self.put(using: Self.userInfoAPI)
    }
}

actor CoreUserProvider: UserProvider {
    lazy var coreServer = CoreServer()

    func getUserInfo() async throws -> UserInfoResponse {
	return self.coreServer.getUserInfo()
    }
    func updateUserInfo(with request: UserInfoUpdate) async throws {
	return self.coreServer.updateUserInfo()
    }
}
```

### Using a coordinator
Coordinators can be very helpful in making your code and logic solid, composable, and scalable. The coordinators can be as simple or complex as you need. Typically, you'll need a coordinator where the view or feature has complexities such as delegate callbacks or other transactions that must be completed as part of the feature or view.

```swift
@Observable
final class AppCoordinator: Coordinator {
	var state: CoordinatorState = .idle
	
	enum Actions {
		case getPresets
	}
	
	func perform(action: Actions) async throws {
		switch action {
			case .getPresets:
				...
		}
	}
}
```

A view coordinator can be great for integrating into legacy (UIKit/AppKit) projects that use legacy architectures, such as MVVM, MVC, or some mixture, as well as for just generally to make sure a complex feature view has easy coordination between networking, the model, and the view. 

```swift
@Observable
final class FeatureDetailCoordinator: ViewCoordinator {
	var state: CoordinatorState = .idle
	var viewModel: FeatureDetailViewModel
	
	var view: some View {
		SomeView(viewModel: self.viewModel)
			.environment(\.error, self.viewModel.error)
			// Add other environment properties and values…
	}
	
	enum Actions {
		case fetchDetails
	}
	
	func perform(action: Actions) async throws {
		switch action {
			case .fetchDetails:
				let details = self.provider.fetchDetails(for: id)
				self.viewModel.update(from: details)
		}
	}
}
```

### Composability with views
Making SwiftUI views composable is somewhat of an art. There's a few ways to accomplish this:

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

b.) Environment. One of the great features of SwiftUI that is done really well is scoping to the environment. You can pass values, objects, etc. into the environment and any child view *within the scope of the view where the values are being passed into the environment* so any view that wants/needs to access the stuff in the environment can by simply adding `@Environment(...) var ...` corresponding to the appropriate environment values.

This can be a great way of reducing the stress on architecting your app/view. This can be as complex or simple as you desire. *Just keep in mind that any view in the hierarchy down stream of where the environment stuff is injected can access the environment values*.

c.) Predetermined values or models with actions. This is a similar approach to protocols but here we pass in an object or values that aren't specific to any protocol but are specific in what must be used.
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

## Great Community Examples
Some of these examples may not specifically use CAP but demonstrate great composability in general. As I've said, there's several ways composability can be implemented and not everything needs to be the same. 

- [Gallery App](https://github.com/area51/gallery-app) - Great example of composability using coordinators with real-life complexities. This project was influenced by the principles discussed in here when it was referred to as the Coordinator Pattern.
- [MovieDatabase](https://github.com/NathanRUbeda/MovieDatabase) - Solid example of building composably and using many production-ready elements, such as web services.
- [Pokedex](https://github.com/NathanRUbeda/Pokedex) - Solid example of building composably and using many production-ready elements, such as web services.

## References
1. (Composability - Wikipedia)[https://en.wikipedia.org/wiki/Composability]
