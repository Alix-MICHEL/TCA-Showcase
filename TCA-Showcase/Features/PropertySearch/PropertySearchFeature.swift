//
//  PropertySearchFeature.swift
//  TCA-Showcase
//

import Foundation
import ComposableArchitecture

@Reducer
struct PropertySearchFeature {
    
    @ObservableState
    struct State: Equatable {
        var searchQuery: String = ""
        var properties: [Property] = []
        var isLoading: Bool = false
        var errorMessage: String?
        var selectedProperty: Property?
        
        var shouldShowEmptyState: Bool {
            !isLoading && properties.isEmpty && searchQuery.isEmpty
        }
        
        var shouldShowNoResults: Bool {
            !isLoading && properties.isEmpty && !searchQuery.isEmpty
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case searchQueryDebounced
        case searchResponse(Result<[Property], Error>)
        case propertyTapped(Property)
        case clearSelectedProperty
        case clearError
    }
    
    @Dependency(\.propertyAPIClient) var propertyAPIClient
    @Dependency(\.continuousClock) var clock
    
    private enum CancelID { case search }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding(\.searchQuery):
                // Trigger search with debounce to avoid too many requests
                state.errorMessage = nil
                return .run { send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.searchQueryDebounced)
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)
                
            case .binding:
                return .none
                
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
                
            case let .searchResponse(.success(properties)):
                state.isLoading = false
                state.properties = properties
                return .none
                
            case let .searchResponse(.failure(error)):
                state.isLoading = false
                state.properties = []
                
                if let apiError = error as? PropertyAPIError {
                    state.errorMessage = apiError.localizedDescription
                } else {
                    state.errorMessage = "An error occurred"
                }
                return .none
                
            case let .propertyTapped(property):
                state.selectedProperty = property
                return .none
                
            case .clearSelectedProperty:
                state.selectedProperty = nil
                return .none
                
            case .clearError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}
