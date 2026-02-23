# Composable Architecture Pattern (CAP)

Build apps and design code in a self-sustainable and scalable way, no matter the current architecture. 

CAP provides protocol-driven guidelines and a networking layer to help you write composable, testable, and scalable code. Use coordinators when you need them, or just use CAP's networking layer on its own. It's a "pattern" — not a framework — so you adopt what makes sense for your project.

### What's included
- **Server** / **ServerAPI** — protocol-based networking with scoped APIs, environment support, and automatic request validation
- **Courier** — pluggable transport layer (`DefaultCourier`, `AsyncHTTPClientCourier`, `MockCourier`)
- **Coordinator** / **ViewCoordinator** — lightweight coordination between networking, model, and view
- **AsyncButton** / **AsyncStableImage** / **AsyncStreamable** — async-first SwiftUI utilities

## Get Started

Read through [Core Principles](#core-principles) to understand the design philosophy.

Add CAP as a dependency to your project:
```
.package(url: "https://github.com/jonnyholland/ComposableArchitecturePattern.git", from: "1.4.6")
```

### Platform Support
| Platform | Minimum Version |
|----------|----------------|
| iOS      | 17.0           |
| macOS    | 14.0           |
| tvOS     | 17.0           |
| watchOS  | 10.0           |
| Linux    | Swift 6.2+     |

CAP's networking layer (Server, Courier, ServerAPI) is fully cross-platform. On Apple platforms the default courier uses `URLSession`; on Linux it uses [AsyncHTTPClient](https://github.com/swift-server/async-http-client). SwiftUI-specific types (`AsyncButton`, `ViewCoordinator`, `AsyncStableImage`) are available on Apple platforms only.

### Dependencies
- [swift-log](https://github.com/apple/swift-log) — used for logging across all platforms
- [async-http-client](https://github.com/swift-server/async-http-client) — used on macOS and Linux for `AsyncHTTPClientCourier`

## Demo Apps
- [NY Times News](https://github.com/jonnyholland/NY-Times-News/tree/main)
- [Harvard Art Museum](https://github.com/jonnyholland/HarvardArt/tree/main)

**Community-driven apps**
- [Marvel](https://github.com/NathanRUbeda/Marvel) by Nathan Ubeda
- [TwitchStream](https://github.com/NathanRUbeda/TwitchStream) by Nathan Ubeda

## Core Principles

1. **Composable.** Each object and view should be self-contained. Only give views what they need. **Not all situations require the same approach** — adapt your architecture to each feature rather than forcing a single template everywhere. Keep it simple so complexity in features doesn't mean complexity in architecture.

2. **Testable.** Approach architecture from the perspective of being able to easily test it. That said, **testability should never come at the cost of stable features or eat up development time**. Rely on built-in language features, keep response objects straightforward, and don't over-fragment your code just to make it unit-testable.

3. **Reliable.** Avoid massive objects with complex code that's difficult to track, understand, or scale. Keep things small and focused.

## Understanding and using CAP

### Servers and APIs

A `Server` defines overall functionality for a backend, and `ServerAPI`s define individual endpoints. The recommended architecture is: **Provider Protocol > Server > API** — so consumers don't care about the implementation details.

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

actor UserNetworking: Server, UserProvider {
    static let userInfoAPI = UserInfoAPI()

    var environments: [ServerEnvironment] = [ServerAPIConstants.productionEnvironment]
    var currentEnvironment: ServerEnvironment? = ServerAPIConstants.productionEnvironment
    var requestsBeingProcessed = Set<UUID>()
    var apis: [any ServerAPI] = [Self.userInfoAPI]

    func getUserInfo() async throws -> UserInfoResponse {
	return try await self.get(using: Self.userInfoAPI)
    }
    func updateUserInfo(with request: UserInfoUpdate) async throws {
	try await self.put(using: Self.userInfoAPI)
    }
}
```

### Couriers
A `Courier` is the transport layer that a `Server` uses to send URL requests. CAP ships with three couriers:

| Courier | Platform | Description |
|---------|----------|-------------|
| `DefaultCourier` | Apple only | Uses `URLSession` for request execution. This is the default on Apple platforms. |
| `AsyncHTTPClientCourier` | macOS, Linux | Uses [AsyncHTTPClient](https://github.com/swift-server/async-http-client) for non-blocking, NIO-based request execution. This is the default on Linux. |
| `MockCourier` | All | Loads response data from a local file URL. Useful for unit testing. |

You can provide your own courier by conforming to the `Courier` protocol and overriding the `courier` property on your `Server`:

```swift
actor MyServer: Server {
    var courier: Courier { AsyncHTTPClientCourier(timeout: .seconds(30)) }
    // ...
}
```

### Coordinators

Use a `Coordinator` when a feature has complexities like delegate callbacks or multi-step transactions that need orchestration.

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

A `ViewCoordinator` extends `Coordinator` to also own a view — useful for coordinating between networking, model, and presentation.

```swift
@Observable
final class FeatureDetailCoordinator: ViewCoordinator {
	var state: CoordinatorState = .idle
	var details: FeatureDetails?

	var view: some View {
		FeatureDetailView(details: self.details)
	}

	func load() async {
		self.state = .loaded
	}

	enum Actions {
		case fetchDetails
	}

	func perform(action: Actions) async throws {
		switch action {
			case .fetchDetails:
				self.details = try await self.provider.fetchDetails(for: id)
		}
	}
}
```

## Community Examples

- [Gallery App](https://github.com/area51/gallery-app) - Composability using coordinators with real-life complexities.
- [MovieDatabase](https://github.com/NathanRUbeda/MovieDatabase) - Production-ready composable architecture with web services.
- [Pokedex](https://github.com/NathanRUbeda/Pokedex) - Production-ready composable architecture with web services.

## References
1. [Composability - Wikipedia](https://en.wikipedia.org/wiki/Composability)
