# TCA Showcase - Property Search Application

## 📋 Description

iOS property search application developed in SwiftUI with The Composable Architecture (TCA) 1.x. This project is a Proof of Concept (PoC) demonstrating best practices for modern TCA architecture.

## 🏗️ Architecture

### The Composable Architecture (TCA)

This project uses **TCA 1.x** with new macros to simplify code:

- **@Reducer**: Define reducers concisely
- **@ObservableState**: Automatic integration with SwiftUI and change observation
- **@Dependency**: Manage testable and injectable dependencies

### Project Structure

```
TCA-Showcase/
├── Models/
│   └── Property.swift              # Property data model
├── Dependencies/
│   └── PropertyAPIClient.swift     # API client with dependency injection
├── Features/
│   ├── PropertySearch/
│   │   ├── PropertySearchFeature.swift   # Search reducer
│   │   └── PropertySearchView.swift      # SwiftUI view
│   └── PropertyDetail/
│       ├── PropertyDetailFeature.swift   # Detail reducer
│       └── PropertyDetailView.swift      # Detail view
├── Components/
│   ├── PropertyRowView.swift       # Reusable property row component
│   └── InfoColumn.swift            # Reusable info column component
├── Helpers/
│   └── ErrorWrapper.swift          # Error wrapper for alerts
└── Tests/
    └── TCA_ShowcaseTests.swift     # Unit tests with TestStore
```

## 🎯 Features

### Property Search

- **Property list**: Display all available properties
- **Real-time search**: Filter by name, location, or type with debouncing
- **Loading states**: Progress indicator during requests
- **Error handling**: Display errors with localized messages
- **Empty state**: User-friendly interface when no properties are available
- **No results**: Informative message for unsuccessful searches

### Detail View

- **Complete information**: Price, area, number of rooms
- **User actions**: Favorites, share, contact
- **Smooth navigation**: Integration with NavigationStack
- **Modal sheet**: Contact the agent

## 🔑 TCA Concepts Demonstrated

### 1. State Management with @ObservableState

```swift
@ObservableState
struct State: Equatable {
    var searchQuery: String = ""
    var properties: [Property] = []
    var isLoading: Bool = false
    var errorMessage: String?
}
```

State is **immutable**, **equatable**, and automatically observable by SwiftUI.

### 2. Actions and Reducer with @Reducer

```swift
@Reducer
struct PropertySearchFeature {
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case searchQueryDebounced
        case searchResponse(Result<[Property], Error>)
        case propertyTapped(Property)
        case clearSelectedProperty
        case clearError
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.searchQuery):
                state.errorMessage = nil
                return .run { send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.searchQueryDebounced)
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .searchQueryDebounced:
                state.isLoading = true
                let query = state.searchQuery
                return .run { send in
                    await send(.searchResponse(
                        Result { try await propertyAPIClient.searchProperties(query) }
                    ))
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)
            // ...
            }
        }
    }
}
```

Actions represent all possible events. `BindableAction` enables two-way binding with SwiftUI. The reducer is a pure function that describes state transitions.

### 3. Side Effects with Effect.run

```swift
return .run { send in
    await send(.searchResponse(
        Result { try await propertyAPIClient.searchProperties(query) }
    ))
}
```

Side effects are managed explicitly via `Effect`, ensuring testability and predictability.

### 4. Dependency Injection with Multiple Values

```swift
struct PropertyAPIClient: Sendable {
    var searchProperties: @Sendable (_ query: String) async throws -> [Property]
    var fetchProperty: @Sendable (_ id: UUID) async throws -> Property
}

extension PropertyAPIClient: DependencyKey {
    static let liveValue = Self(
        searchProperties: { query in
            try await Task.sleep(for: .seconds(1))
            // Real implementation with 1s delay
        }
    )

    static let previewValue = Self(
        searchProperties: { query in
            try await Task.sleep(for: .milliseconds(100))
            // Fast implementation for Xcode Previews
        }
    )

    static let testValue = Self(
        searchProperties: unimplemented("PropertyAPIClient.searchProperties"),
        fetchProperty: unimplemented("PropertyAPIClient.fetchProperty")
    )
}

@Dependency(\.propertyAPIClient) var propertyAPIClient
```

Dependencies are injected via the TCA dependency system with three values:
- **liveValue**: Production implementation (realistic delays)
- **previewValue**: Fast previews in Xcode (100ms delays)
- **testValue**: Fails if not overridden in tests (catches missing mocks)

### 5. Navigation

```swift
.navigationDestination(
    item: Binding(
        get: { store.selectedProperty },
        set: { _ in store.send(.clearSelectedProperty) }
    )
) { property in
    PropertyDetailView(
        store: Store(initialState: PropertyDetailFeature.State(property: property)) {
            PropertyDetailFeature()
        }
    )
}
```

Navigation is managed through state, ensuring predictability and testability.

### 6. Debouncing and Cancellation for Search

```swift
@Dependency(\.continuousClock) var clock

case .binding(\.searchQuery):
    state.errorMessage = nil
    return .run { send in
        try await clock.sleep(for: .milliseconds(300))
        await send(.searchQueryDebounced)
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)

case .searchQueryDebounced:
    state.isLoading = true
    let query = state.searchQuery

    return .run { send in
        await send(.searchResponse(
            Result {
                try await propertyAPIClient.searchProperties(query)
            }
        ))
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)
```

Search requests are debounced (300ms) using `clock.sleep` to avoid overloading the API while typing. The `.cancellable(cancelInFlight: true)` ensures that previous in-flight requests are automatically cancelled when a new search is triggered. Using `clock` instead of the deprecated `.debounce()` method allows for better testability with `TestClock`.

## ✅ Testing

### Unit Tests with TestStore

```swift
@Test func testSearchWithQuery() async throws {
    let mockProperties = [Property.mockProperties[0]]
    let clock = TestClock()

    let store = TestStore(
        initialState: PropertySearchFeature.State()
    ) {
        PropertySearchFeature()
    } withDependencies: {
        $0.propertyAPIClient.searchProperties = { _ in mockProperties }
        $0.continuousClock = clock
    }

    // User types in search query
    await store.send(.binding(.set(\.searchQuery, "Paris"))) {
        $0.searchQuery = "Paris"
        $0.errorMessage = nil
    }

    // Advance clock to trigger debounce
    await clock.advance(by: .milliseconds(300))

    // Receive debounced action
    await store.receive(\.searchQueryDebounced) {
        $0.isLoading = true
    }

    await store.receive(\.searchResponse.success) {
        $0.isLoading = false
        $0.properties = mockProperties
    }
}
```

**TestStore** verifies:
- State changes are exactly as expected
- All effects are handled
- No unwanted side effects

### Test Coverage

- ✅ Successful search with debouncing
- ✅ Empty search (display all)
- ✅ Error handling
- ✅ Property selection and navigation
- ✅ Error clearing
- ✅ Empty state computation
- ✅ No results state
- ✅ **Debounce cancellation** - Verifies only the last search executes
- ✅ API client mock with previewValue
- ✅ Property filtering
- ✅ Favorite toggling
- ✅ Contact sheet with BindableAction

## 🚀 Running the Project

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation

1. Clone the repository
2. Open `TCA-Showcase.xcodeproj`
3. Select a simulator or device
4. Build and run (⌘R)

### Running Tests

```bash
# Command line
xcodebuild test -project TCA-Showcase.xcodeproj -scheme TCA-Showcase -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Or in Xcode
⌘U
```

## 📚 Resources

- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [Point-Free Videos](https://www.pointfree.co)
- [TCA Documentation](https://pointfreeco.github.io/swift-composable-architecture/)

## 🎓 Key Learnings

This project demonstrates:

1. **Modern TCA**: Using the latest macros (@Reducer, @ObservableState)
2. **Dependency Management**: Testable dependency injection
3. **Side Effect Management**: Explicit and controllable effects
4. **Comprehensive Testing**: Exhaustive validation with TestStore
5. **Navigation**: State-based navigation with SwiftUI
6. **Performance**: Debouncing for optimized search
7. **Error Handling**: Robust error management
8. **Empty States**: User-friendly empty and no-results states

## 📝 License

This project is a proof of concept for educational purposes.
