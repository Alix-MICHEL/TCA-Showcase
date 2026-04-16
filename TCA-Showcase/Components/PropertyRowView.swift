//
//  PropertyRowView.swift
//  TCA-Showcase
//

import SwiftUI

struct PropertyRowView: View {
    let property: Property
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(property.propertyType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
                Spacer()
                Text(property.formattedPrice)
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }
            Text(property.title)
                .font(.body)
                .fontWeight(.semibold)
            HStack {
                Image(systemName: "mappin")
                Text(property.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Label("\(property.bedrooms)", systemImage: "bed.double")
                Label("\(property.bathrooms)", systemImage: "shower")
                Label(property.formattedArea, systemImage: "square")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
