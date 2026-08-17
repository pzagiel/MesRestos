import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct RestaurantFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let restaurant: Restaurant?

    @State private var name: String
    @State private var address: String
    @State private var rating: Double
    @State private var cuisine: String
    @State private var comment: String
    @State private var website: String
    @State private var phone: String
    @State private var isToTry: Bool
    @State private var isFavorite: Bool

    private static let commonCuisines = [
        "Belge",
        "Française",
        "Italienne",
        "Asiatique",
        "Méditerranéenne",
        "Moyen-Orientale",
        "Africaine",
        "Américaine",
        "Latino-américaine",
        "Indienne",
        "Végétarienne",
        "Cuisine d’auteur",
        "Néobistrot",
        "Bistronomie",
        "Café et brunch",
        "Glacier",
        "Autre"
    ]

    init(restaurant: Restaurant? = nil) {
        self.restaurant = restaurant
        _name = State(initialValue: restaurant?.name ?? "")
        _address = State(initialValue: restaurant?.address ?? "")
        _rating = State(initialValue: restaurant?.rating ?? 0)
        _cuisine = State(initialValue: restaurant?.cuisine ?? "Autre")
        _comment = State(initialValue: restaurant?.comment ?? "")
        _website = State(initialValue: restaurant?.website ?? "")
        _phone = State(initialValue: restaurant?.phone ?? "")
        _isToTry = State(initialValue: restaurant?.status == "À tester")
        _isFavorite = State(initialValue: restaurant?.isFavorite ?? false)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !cuisine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Restaurant") {
                    TextField("Nom", text: $name)
                    Picker("Type de cuisine", selection: $cuisine) {
                        ForEach(cuisineChoices, id: \.self) { cuisine in
                            Text(cuisine).tag(cuisine)
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Adresse", text: $address, axis: .vertical)
                        .lineLimit(2...3)
                    TextField("Site web (facultatif)", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Téléphone (facultatif)", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Suivi") {
                    Toggle(isOn: $isToTry) {
                        Label("À tester", systemImage: "bookmark")
                    }
                    Toggle(isOn: $isFavorite) {
                        Label("Favori", systemImage: "heart.fill")
                    }
                    .tint(.pink)
                }

                Section("Évaluation") {
                    HStack {
                        Slider(value: $rating, in: 0...5, step: 0.5)
                        Text("\(rating, specifier: "%.1f") / 5")
                            .monospacedDigit()
                            .foregroundStyle(.orange)
                            .frame(width: 58)
                    }
                }

                Section {
                    TextField(
                        "Votre remarque sur ce restaurant…",
                        text: $comment,
                        axis: .vertical
                    )
                    .lineLimit(4...8)
                } header: {
                    Text("Remarque / commentaire")
                } footer: {
                    Text("Ce champ est facultatif.")
                }

                Section {
                    Label("La position sera trouvée automatiquement", systemImage: "map")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Localisation")
                } footer: {
                    Text("La carte sera créée à partir de l’adresse. Vous pourrez enregistrer même si la localisation n’est pas trouvée.")
                }
            }
            .navigationTitle(restaurant == nil ? "Nouveau restaurant" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var cuisineChoices: [String] {
        if Self.commonCuisines.contains(cuisine) {
            return Self.commonCuisines
        }
        return [cuisine] + Self.commonCuisines
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCuisine = cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanWebsite = normalizedWebsite(website)
        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedRestaurant: Restaurant

        if let restaurant {
            restaurant.name = cleanName
            restaurant.address = cleanAddress
            restaurant.rating = rating
            restaurant.cuisine = cleanCuisine
            restaurant.comment = cleanComment
            restaurant.website = cleanWebsite
            restaurant.phone = cleanPhone
            restaurant.status = isToTry ? "À tester" : "Aucun"
            restaurant.isFavorite = isFavorite
            restaurant.latitude = nil
            restaurant.longitude = nil
            savedRestaurant = restaurant
        } else {
            let newRestaurant = Restaurant(
                name: cleanName,
                address: cleanAddress,
                rating: rating,
                cuisine: cleanCuisine,
                comment: cleanComment,
                website: cleanWebsite,
                phone: cleanPhone,
                status: isToTry ? "À tester" : "Aucun",
                isFavorite: isFavorite
            )
            modelContext.insert(newRestaurant)
            savedRestaurant = newRestaurant
        }
        dismiss()

        Task {
            let coordinates = await coordinates(for: cleanAddress)
            savedRestaurant.latitude = coordinates?.latitude
            savedRestaurant.longitude = coordinates?.longitude
        }
    }

    private func normalizedWebsite(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }

    private func coordinates(for address: String) async -> CLLocationCoordinate2D? {
        do {
            if #available(iOS 26.0, *) {
                guard let request = MKGeocodingRequest(addressString: address) else { return nil }
                return try await request.mapItems.first?.location.coordinate
            } else {
                return try await CLGeocoder()
                    .geocodeAddressString(address)
                    .first?.location?.coordinate
            }
        } catch {
            return nil
        }
    }
}
