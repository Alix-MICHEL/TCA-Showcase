//
//  TCA_ShowcaseApp.swift
//  TCA-Showcase
//
//  Created by Alix Michel on 14/04/2026.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCA_ShowcaseApp: App {
    var body: some Scene {
        WindowGroup {
            PropertySearchView(
                store: Store(initialState: PropertySearchFeature.State()) {
                    PropertySearchFeature()
                }
            )
        }
    }
}
