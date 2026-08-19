//
//  MesRestosApp.swift
//  Mes Restos
//
//  Created by patrick zagiel on 09/08/2026.
//

import SwiftUI
import SwiftData

@main
struct MesRestosApp: App {
    @AppStorage(AppAppearance.storageKey) private var appearanceValue = AppAppearance.system.rawValue

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceValue) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(for: Restaurant.self)
    }
}
