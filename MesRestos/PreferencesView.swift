import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    static let storageKey = "application.appearance"

    case system = "Automatique"
    case light = "Clair"
    case dark = "Sombre"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon.stars"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppAppearance.storageKey) private var appearanceValue = AppAppearance.system.rawValue

    private var appearance: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceValue) ?? .system },
            set: { appearanceValue = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Apparence", selection: appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Apparence")
                } footer: {
                    Text("Le mode automatique suit l’apparence choisie dans les réglages de l’iPhone.")
                }
            }
            .navigationTitle("Préférences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") {
                        dismiss()
                    }
                }
            }
        }
    }
}
