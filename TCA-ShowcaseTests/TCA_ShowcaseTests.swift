//
//  TCA_ShowcaseTests.swift
//  TCA-ShowcaseTests
//
//  Created by Alix Michel on 14/04/2026.
//

import Testing
import Foundation
import ComposableArchitecture
@testable import TCA_Showcase

/// Comprehensive test suite for PropertySearchFeature
/// Demonstrates TestStore usage with TCA
@MainActor
struct PropertySearchFeatureTests {
    
    // MARK: - Search Tests
    
    /// Test that searching with a query loads properties successfully
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
        
        // User types in search query (triggers debounced search)
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

        // Wait for search response
        await store.receive(\.searchResponse.success) {
            $0.isLoading = false
            $0.properties = mockProperties
        }
    }
    
    /// Test that empty query triggers search for all properties
    @Test func testEmptyQueryShowsAllProperties() async throws {
        let clock = TestClock()
        
        let store = TestStore(
            initialState: PropertySearchFeature.State(searchQuery: "Paris")
        ) {
            PropertySearchFeature()
        } withDependencies: {
            $0.propertyAPIClient.searchProperties = { _ in Property.mockProperties }
            $0.continuousClock = clock
        }
        
        // User clears search query
        await store.send(.binding(.set(\.searchQuery, ""))) {
            $0.searchQuery = ""
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
            $0.properties = Property.mockProperties
        }
    }
    
    /// Test error handling when search fails
    @Test func testSearchFailureHandlesError() async throws {
        let store = TestStore(
            initialState: PropertySearchFeature.State()
        ) {
            PropertySearchFeature()
        } withDependencies: {
            $0.propertyAPIClient.searchProperties = { _ in
                throw PropertyAPIError.networkError
            }
        }
        
        await store.send(.searchQueryDebounced) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        
        await store.receive(\.searchResponse.failure) {
            $0.isLoading = false
            $0.properties = []
            $0.errorMessage = PropertyAPIError.networkError.localizedDescription
        }
    }
    
    // MARK: - Navigation Tests
    
    /// Test that tapping a property navigates to detail
    @Test func testPropertyTappedNavigatesToDetail() async throws {
        let property = Property.mockProperties[0]

        let store = TestStore(
            initialState: PropertySearchFeature.State(
                properties: [property]
            )
        ) {
            PropertySearchFeature()
        }

        await store.send(.propertyTapped(property)) {
            $0.selectedProperty = property
        }
    }
    
    // MARK: - Error Clearing Tests
    
    /// Test that error can be cleared
    @Test func testClearError() async throws {
        let store = TestStore(
            initialState: PropertySearchFeature.State(
                errorMessage: "Test error"
            )
        ) {
            PropertySearchFeature()
        }
        
        await store.send(.clearError) {
            $0.errorMessage = nil
        }
    }
    
    // MARK: - State Computation Tests
    
    /// Test empty state computation
    @Test func testEmptyStateComputation() {
        var state = PropertySearchFeature.State()
        #expect(state.shouldShowEmptyState == true)
        
        state.isLoading = true
        #expect(state.shouldShowEmptyState == false)
        
        state.isLoading = false
        state.properties = Property.mockProperties
        #expect(state.shouldShowEmptyState == false)
    }
    
    /// Test no results state computation
    @Test func testNoResultsStateComputation() {
        var state = PropertySearchFeature.State()
        #expect(state.shouldShowNoResults == false)
        
        state.searchQuery = "NonExistent"
        #expect(state.shouldShowNoResults == true)
        
        state.isLoading = true
        #expect(state.shouldShowNoResults == false)
    }
}

// MARK: - PropertyDetailFeature Tests

@MainActor
struct PropertyDetailFeatureTests {
    
    /// Test toggling favorite state
    @Test func testToggleFavorite() async throws {
        let property = Property.mockProperties[0]
        
        let store = TestStore(
            initialState: PropertyDetailFeature.State(property: property)
        ) {
            PropertyDetailFeature()
        }
        
        #expect(store.state.isFavorite == false)
        
        await store.send(.toggleFavorite) {
            $0.isFavorite = true
        }
        
        await store.send(.toggleFavorite) {
            $0.isFavorite = false
        }
    }
    
    /// Test contact button shows sheet via binding
    @Test func testContactButtonShowsSheet() async throws {
        let property = Property.mockProperties[0]

        let store = TestStore(
            initialState: PropertyDetailFeature.State(property: property)
        ) {
            PropertyDetailFeature()
        }

        await store.send(.binding(.set(\.showingContactSheet, true))) {
            $0.showingContactSheet = true
        }

        await store.send(.binding(.set(\.showingContactSheet, false))) {
            $0.showingContactSheet = false
        }
    }

    /// Test debounce behavior cancels previous searches
    @Test func testSearchDebounceCancelsPreviousRequests() async throws {
        let searchCallCount = LockIsolated(0)
        let clock = TestClock()

        let store = TestStore(
            initialState: PropertySearchFeature.State()
        ) {
            PropertySearchFeature()
        } withDependencies: {
            $0.propertyAPIClient.searchProperties = { _ in
                searchCallCount.withValue { $0 += 1 }
                try await Task.sleep(for: .seconds(0.5))
                return Property.mockProperties
            }
            $0.continuousClock = clock
        }

        // Rapidly type "P", then "Pa", then "Par"
        await store.send(.binding(.set(\.searchQuery, "P"))) {
            $0.searchQuery = "P"
            $0.errorMessage = nil
        }

        await store.send(.binding(.set(\.searchQuery, "Pa"))) {
            $0.searchQuery = "Pa"
        }

        await store.send(.binding(.set(\.searchQuery, "Par"))) {
            $0.searchQuery = "Par"
        }

        // Advance clock to trigger the last debounce only
        await clock.advance(by: .milliseconds(300))

        // Only the last search should execute after debounce
        await store.receive(\.searchQueryDebounced) {
            $0.isLoading = true
        }

        await store.receive(\.searchResponse.success) {
            $0.isLoading = false
            $0.properties = Property.mockProperties
        }

        // Verify only one search was executed (debounce cancelled the earlier ones)
        #expect(searchCallCount.value == 1)
    }
}

// MARK: - PropertyAPIClient Tests

struct PropertyAPIClientTests {
    
    /// Test that mock API client returns data
    @Test func testMockAPIClientReturnsProperties() async throws {
        let client = PropertyAPIClient.previewValue
        let properties = try await client.searchProperties("")
        
        #expect(properties.count > 0)
        #expect(properties == Property.mockProperties)
    }
    
    /// Test that search filters properties
    @Test func testSearchFiltersProperties() async throws {
        let client = PropertyAPIClient.liveValue
        let properties = try await client.searchProperties("Paris")
        
        // Should only return properties matching "Paris"
        for property in properties {
            let matches = property.title.lowercased().contains("paris") ||
                         property.location.lowercased().contains("paris") ||
                         property.propertyType.rawValue.lowercased().contains("paris")
            #expect(matches == true)
        }
    }
    
    /// Test fetching property by ID
    @Test func testFetchPropertyById() async throws {
        let client = PropertyAPIClient.previewValue
        let targetProperty = Property.mockProperties[0]
        
        let fetchedProperty = try await client.fetchProperty(targetProperty.id)
        #expect(fetchedProperty == targetProperty)
    }
    
    /// Test fetching non-existent property throws error
    @Test func testFetchNonExistentPropertyThrowsError() async throws {
        let client = PropertyAPIClient.previewValue
        let nonExistentId = UUID()
        
        await #expect(throws: PropertyAPIError.self) {
            try await client.fetchProperty(nonExistentId)
        }
    }
}

// MARK: - Property Model Tests

struct PropertyModelTests {
    
    /// Test formatted price
    @Test func testFormattedPrice() {
        let property = Property.mockProperties[0]
        let formatted = property.formattedPrice
        
        #expect(formatted.contains("€"))
        #expect(!formatted.contains("."))
    }
    
    /// Test formatted area
    @Test func testFormattedArea() {
        let property = Property.mockProperties[0]
        let formatted = property.formattedArea
        
        #expect(formatted.contains("m²"))
    }
    
    /// Test property equality
    @Test func testPropertyEquality() {
        let property1 = Property.mockProperties[0]
        let property2 = Property.mockProperties[0]
        let property3 = Property.mockProperties[1]
        
        #expect(property1 == property2)
        #expect(property1 != property3)
    }
}
