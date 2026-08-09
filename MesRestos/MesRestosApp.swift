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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Restaurant.self)
    }
}
