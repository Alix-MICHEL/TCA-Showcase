//
//  PropertyDetailView.swift
//  TCA-Showcase
//

import SwiftUI
import ComposableArchitecture

struct PropertyDetailView: View {
    
    @Bindable var store: StoreOf<PropertyDetailFeature>
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                propertyImage
                priceSection
                Divider()
                basicInfoSection
                Divider()
                locationSection
                Divider()
                descriptionSection
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        store.send(.shareButtonTapped)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button {
                        store.send(.toggleFavorite)
                    } label: {
                        Image(systemName: store.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(store.isFavorite ? .red : .primary)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                store.showingContactSheet = true
            } label: {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Contact")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $store.showingContactSheet) {
            contactSheet
        }
    }

    private var propertyImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.1))
                .frame(height: 250)
            VStack {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Property Image")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var priceSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.property.formattedPrice)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
                Text(store.property.propertyType.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.headline)
            HStack(spacing: 24) {
                InfoColumn(icon: "bed.double", label: "Bedrooms", value: "\(store.property.bedrooms)")
                InfoColumn(icon: "shower", label: "Bathrooms", value: "\(store.property.bathrooms)")
                InfoColumn(icon: "square", label: "Area", value: store.property.formattedArea)
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.accentColor)
                Text(store.property.location)
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
            Text(store.property.description)
                .foregroundStyle(.secondary)
        }
    }
    
    private var contactSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                Text("Contact Agent")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("In a real app, this would display contact information.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        store.showingContactSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
