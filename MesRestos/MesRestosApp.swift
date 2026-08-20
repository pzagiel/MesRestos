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

    private let modelContainer: ModelContainer = {
        let schema = Schema([Restaurant.self])
        let cloudConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [cloudConfiguration])
        } catch let cloudError {
            // CloudKit peut être indisponible si iCloud est désactivé, si le compte
            // Apple ne possède pas les capacités nécessaires ou hors connexion.
            // Dans ce cas, Mes Restos reste entièrement utilisable avec une base
            // SwiftData locale et persistante sur l'appareil.
            let localConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )

            do {
                return try ModelContainer(for: schema, configurations: [localConfiguration])
            } catch let localError {
                fatalError(
                    "Impossible d’initialiser les données Mes Restos. " +
                    "CloudKit : \(cloudError). Stockage local : \(localError)"
                )
            }
        }
    }()

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceValue) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(modelContainer)
    }
}
