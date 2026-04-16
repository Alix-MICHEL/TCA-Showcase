//
//  Property.swift
//  TCA-Showcase
//

import Foundation

struct Property: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let title: String
    let description: String
    let price: Double
    let location: String
    let bedrooms: Int
    let bathrooms: Int
    let area: Double
    let imageURL: String?
    let propertyType: PropertyType
    
    enum PropertyType: String, Codable, Equatable, Sendable {
        case apartment = "Apartment"
        case house = "House"
        case studio = "Studio"
        case villa = "Villa"
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "\(price) €"
    }
    
    var formattedArea: String {
        "\(Int(area)) m²"
    }
}

extension Property {
    static let mockProperties: [Property] = [
        Property(
            id: UUID(),
            title: "Modern Apartment with Seine View",
            description: "Beautiful fully renovated apartment in the heart of Paris.",
            price: 450_000,
            location: "Paris 15th",
            bedrooms: 2,
            bathrooms: 1,
            area: 65,
            imageURL: nil,
            propertyType: .apartment
        ),
        Property(
            id: UUID(),
            title: "Contemporary Villa with Pool",
            description: "Superb luxury villa with heated swimming pool.",
            price: 890_000,
            location: "Bordeaux",
            bedrooms: 4,
            bathrooms: 3,
            area: 180,
            imageURL: nil,
            propertyType: .villa
        ),
        Property(
            id: UUID(),
            title: "Cozy Studio Near Universities",
            description: "Perfect studio for students or young professionals.",
            price: 120_000,
            location: "Lyon 7th",
            bedrooms: 0,
            bathrooms: 1,
            area: 25,
            imageURL: nil,
            propertyType: .studio
        )
    ]
}
