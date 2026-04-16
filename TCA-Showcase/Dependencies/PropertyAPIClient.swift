//
//  PropertyAPIClient.swift
//  TCA-Showcase
//

import Foundation
import ComposableArchitecture

struct PropertyAPIClient: Sendable {
    var searchProperties: @Sendable (_ query: String) async throws -> [Property]
    var fetchProperty: @Sendable (_ id: UUID) async throws -> Property
}

extension PropertyAPIClient: DependencyKey {
    static let liveValue = Self(
        searchProperties: { query in
            try await Task.sleep(for: .seconds(1))
            let lowercased = query.lowercased()
            if lowercased.isEmpty {
                return Property.mockProperties
            } else {
                return Property.mockProperties.filter { property in
                    property.title.lowercased().contains(lowercased) ||
                    property.location.lowercased().contains(lowercased)
                }
            }
        },
        fetchProperty: { id in
            try await Task.sleep(for: .seconds(0.5))
            guard let property = Property.mockProperties.first(where: { $0.id == id }) else {
                throw PropertyAPIError.propertyNotFound
            }
            return property
        }
    )
    
    static let previewValue = Self(
        searchProperties: { query in
            // Faster for Xcode previews
            try await Task.sleep(for: .milliseconds(100))
            let lowercased = query.lowercased()
            if lowercased.isEmpty {
                return Property.mockProperties
            } else {
                return Property.mockProperties.filter { property in
                    property.title.lowercased().contains(lowercased) ||
                    property.location.lowercased().contains(lowercased)
                }
            }
        },
        fetchProperty: { id in
            try await Task.sleep(for: .milliseconds(50))
            guard let property = Property.mockProperties.first(where: { $0.id == id }) else {
                throw PropertyAPIError.propertyNotFound
            }
            return property
        }
    )
    
    static let testValue = Self(
        searchProperties: unimplemented("PropertyAPIClient.searchProperties"),
        fetchProperty: unimplemented("PropertyAPIClient.fetchProperty")
    )
}

extension DependencyValues {
    var propertyAPIClient: PropertyAPIClient {
        get { self[PropertyAPIClient.self] }
        set { self[PropertyAPIClient.self] = newValue }
    }
}

enum PropertyAPIError: Error {
    case propertyNotFound
    case networkError

    var localizedDescription: String {
        switch self {
        case .propertyNotFound: return "Property not found"
        case .networkError: return "Network error"
        }
    }
}
