//
//  PropertySearchView.swift
//  TCA-Showcase
//

import SwiftUI
import ComposableArchitecture

struct PropertySearchView: View {
    
    @Bindable var store: StoreOf<PropertySearchFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                if store.shouldShowEmptyState {
                    emptyStateView
                } else if store.shouldShowNoResults {
                    noResultsView
                } else {
                    propertyListView
                }
            }
            .navigationTitle("Property Search")
            .searchable(text: $store.searchQuery, prompt: "Search...")
            .onSubmit(of: .search) {
                store.send(.searchQueryDebounced)
            }
            .toolbar {
                if store.isLoading {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                    }
                }
            }
            .alert(
                item: Binding(
                    get: { store.errorMessage.map { ErrorWrapper(message: $0) } },
                    set: { _ in store.send(.clearError) }
                )
            ) { errorWrapper in
                Alert(
                    title: Text("Error"),
                    message: Text(errorWrapper.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationDestination(
                item: Binding(
                    get: { store.selectedProperty },
                    set: { _ in store.send(.clearSelectedProperty) }
                )
            ) { property in
                PropertyDetailView(
                    store: Store(
                        initialState: PropertyDetailFeature.State(property: property)
                    ) {
                        PropertyDetailFeature()
                    }
                )
            }
        }
        .onAppear {
            if store.properties.isEmpty && !store.isLoading {
                store.send(.searchQueryDebounced)
            }
        }
    }
    
    private var propertyListView: some View {
        List(store.properties) { property in
            PropertyRowView(property: property)
                .onTapGesture {
                    store.send(.propertyTapped(property))
                }
        }
        .overlay {
            if store.isLoading && store.properties.isEmpty {
                ProgressView("Searching...")
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Search for Properties", systemImage: "house.fill")
        } description: {
            Text("Use the search bar to filter properties")
        } actions: {
            Button("Show All Properties") {
                store.send(.searchQueryDebounced)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var noResultsView: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("Try a different search")
        )
    }
}

