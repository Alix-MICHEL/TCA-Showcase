//
//  PropertyDetailFeature.swift
//  TCA-Showcase
//

import Foundation
import ComposableArchitecture

@Reducer
struct PropertyDetailFeature {
    
    @ObservableState
    struct State: Equatable {
        let property: Property
        var isFavorite: Bool = false
        var showingContactSheet: Bool = false
        
        init(property: Property) {
            self.property = property
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case toggleFavorite
        case shareButtonTapped
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .toggleFavorite:
                state.isFavorite.toggle()
                return .none

            case .shareButtonTapped:
                // TODO: Implement share functionality
                return .none
            }
        }
    }
}
