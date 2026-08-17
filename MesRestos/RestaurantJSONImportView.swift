import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import UIKit

struct RestaurantImportCandidate: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let cuisine: String
    let status: String
    let isFavorite: Bool
    let rating: Double
    let comment: String
    let phone: String
    let website: String
    let foodingURL: String
    let latitude: Double?
    let longitude: Double?
    let issues: [String]

    var isValid: Bool { issues.isEmpty }
}

enum RestaurantJSONImportError: LocalizedError {
    case empty
    case unsupportedVersion(Int)
    case invalidFormat
    case noRestaurants

    var errorDescription: String? {
        switch self {
        case .empty:
            return "Collez d’abord des données JSON."
        case .unsupportedVersion(let version):
            return "La version JSON \(version) n’est pas prise en charge. La version attendue est 1."
        case .invalidFormat:
            return "Le JSON n’a pas le format attendu. Vérifiez les accolades, guillemets et noms de champs."
        case .noRestaurants:
            return "Le JSON ne contient aucun restaurant."
        }
    }
}

enum RestaurantJSONImporter {
    private struct Document: Decodable {
        let version: Int
        let restaurants: [RawRestaurant]
    }

    private struct RawRestaurant: Decodable {
        let nom: String?
        let adresse: String?
        let cuisine: String?
        let statut: String?
        let favori: Bool?
        let note: Double?
        let commentaire: String?
        let telephone: String?
        let siteWeb: String?
        let lienFooding: String?
        let localisation: RawLocation?

        enum CodingKeys: String, CodingKey {
            case nom, adresse, cuisine, statut, favori, note, commentaire, telephone, localisation
            case siteWeb = "site_web"
            case lienFooding = "lien_fooding"
        }
    }

    private struct RawLocation: Decodable {
        let latitude: Double?
        let longitude: Double?
    }

    static func parse(_ text: String) throws -> [RestaurantImportCandidate] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, let data = trimmedText.data(using: .utf8) else {
            throw RestaurantJSONImportError.empty
        }

        let decoder = JSONDecoder()
        let rawRestaurants: [RawRestaurant]

        if let document = try? decoder.decode(Document.self, from: data) {
            guard document.version == 1 else {
                throw RestaurantJSONImportError.unsupportedVersion(document.version)
            }
            rawRestaurants = document.restaurants
        } else if let array = try? decoder.decode([RawRestaurant].self, from: data) {
            rawRestaurants = array
        } else if let restaurant = try? decoder.decode(RawRestaurant.self, from: data) {
            rawRestaurants = [restaurant]
        } else {
            throw RestaurantJSONImportError.invalidFormat
        }

        guard !rawRestaurants.isEmpty else {
            throw RestaurantJSONImportError.noRestaurants
        }

        return rawRestaurants.map(makeCandidate)
    }

    private static func makeCandidate(from raw: RawRestaurant) -> RestaurantImportCandidate {
        var issues: [String] = []
        let name = clean(raw.nom)
        let address = clean(raw.adresse)

        if name.isEmpty { issues.append("Le nom est obligatoire.") }
        if address.isEmpty { issues.append("L’adresse est obligatoire.") }

        let rating = raw.note ?? 0
        if !(0...5).contains(rating) {
            issues.append("La note doit être comprise entre 0 et 5.")
        }

        let status: String
        let legacyFavorite = folded(clean(raw.statut)) == "favori"
        switch folded(clean(raw.statut)) {
        case "", "aucun", "reference": status = "Aucun"
        case "a tester": status = "À tester"
        case "favori": status = "Aucun"
        default:
            status = "Aucun"
            issues.append("Le statut doit être « Aucun » ou « À tester ».")
        }

        let website = validatedURL(raw.siteWeb, field: "site_web", issues: &issues)
        let foodingURL = validatedURL(raw.lienFooding, field: "lien_fooding", issues: &issues)

        var latitude: Double?
        var longitude: Double?
        if let location = raw.localisation {
            if let lat = location.latitude, let lon = location.longitude {
                if (-90...90).contains(lat), (-180...180).contains(lon) {
                    latitude = lat
                    longitude = lon
                } else {
                    issues.append("Les coordonnées de localisation ne sont pas valides.")
                }
            } else if location.latitude != nil || location.longitude != nil {
                issues.append("La latitude et la longitude doivent être fournies ensemble.")
            }
        }

        return RestaurantImportCandidate(
            name: name,
            address: address,
            cuisine: clean(raw.cuisine).isEmpty ? "Autre" : clean(raw.cuisine),
            status: status,
            isFavorite: raw.favori ?? legacyFavorite,
            rating: (0...5).contains(rating) ? rating : 0,
            comment: clean(raw.commentaire),
            phone: clean(raw.telephone),
            website: website,
            foodingURL: foodingURL,
            latitude: latitude,
            longitude: longitude,
            issues: issues
        )
    }

    private static func clean(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func folded(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    private static func validatedURL(
        _ value: String?,
        field: String,
        issues: inout [String]
    ) -> String {
        let original = clean(value)
        guard !original.isEmpty else { return "" }
        let normalized = original.contains("://") ? original : "https://\(original)"
        guard let components = URLComponents(string: normalized),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              components.host != nil else {
            issues.append("Le champ \(field) ne contient pas une adresse web valide.")
            return ""
        }
        return normalized
    }
}

struct RestaurantJSONImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingRestaurants: [Restaurant]

    @State private var jsonText = ""
    @State private var candidates: [RestaurantImportCandidate] = []
    @State private var errorMessage: String?
    @State private var importDuplicates = false
    @State private var saveError: String?
    @FocusState private var jsonEditorIsFocused: Bool

    private let sourceName: String?

    init(initialJSON: String = "", sourceName: String? = nil) {
        _jsonText = State(initialValue: initialJSON)
        self.sourceName = sourceName
    }

    private var isFileImport: Bool {
        sourceName != nil
    }

    private var duplicateIDs: Set<UUID> {
        let existingNames = Set(existingRestaurants.map { normalized($0.name) })
        let existingAddresses = Set(existingRestaurants.map { normalized($0.address) })
        return Set(candidates.compactMap { candidate in
            let sameName = !candidate.name.isEmpty && existingNames.contains(normalized(candidate.name))
            let sameAddress = !candidate.address.isEmpty && existingAddresses.contains(normalized(candidate.address))
            return sameName || sameAddress ? candidate.id : nil
        })
    }

    private var importableCandidates: [RestaurantImportCandidate] {
        candidates.filter { candidate in
            candidate.isValid && (importDuplicates || !duplicateIDs.contains(candidate.id))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if !isFileImport {
                    Section("Données JSON") {
                        TextEditor(text: $jsonText)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(height: 220)
                            .focused($jsonEditorIsFocused)
                            .accessibilityLabel("Données JSON à importer")

                        HStack {
                            Button("Coller", systemImage: "doc.on.clipboard") {
                                jsonText = UIPasteboard.general.string ?? ""
                                validateAndDismissKeyboard()
                            }
                            Spacer()
                            Button("Exemple") { jsonText = Self.exampleJSON }
                            Button("Effacer", role: .destructive) {
                                jsonText = ""
                                candidates = []
                                errorMessage = nil
                            }
                        }

                        Button("Vérifier les données", systemImage: "checkmark.circle") {
                            validateAndDismissKeyboard()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                if !candidates.isEmpty {
                    Section {
                        summary
                        if !duplicateIDs.isEmpty {
                            Toggle("Importer aussi les doublons", isOn: $importDuplicates)
                        }
                    } header: {
                        Text("Aperçu")
                    } footer: {
                        Text("Sans coordonnées, l’adresse sera géocodée automatiquement après l’import. La localisation reste facultative.")
                    }

                    Section("Restaurants") {
                        ForEach(candidates) { candidate in
                            candidateRow(candidate)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(sourceName ?? "Importer une sélection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if candidates.isEmpty {
                        if !isFileImport {
                            Button("Vérifier") { validateAndDismissKeyboard() }
                                .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button("Importer") {
                            jsonEditorIsFocused = false
                            importRestaurants()
                        }
                        .disabled(importableCandidates.isEmpty)
                    }
                }
                if !isFileImport {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Vérifier") { validateAndDismissKeyboard() }
                        Spacer()
                        Button("Terminé") { jsonEditorIsFocused = false }
                    }
                }
            }
            .alert("Import impossible", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Erreur inconnue")
            }
            .task {
                if !jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   candidates.isEmpty {
                    validate()
                }
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("\(candidates.count) restaurant(s) détecté(s)", systemImage: "fork.knife")
            Label("\(importableCandidates.count) prêt(s) à importer", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
            if !duplicateIDs.isEmpty {
                Label("\(duplicateIDs.count) doublon(s) détecté(s)", systemImage: "doc.on.doc")
                    .foregroundStyle(.orange)
            }
            let invalidCount = candidates.filter { !$0.isValid }.count
            if invalidCount > 0 {
                Label("\(invalidCount) entrée(s) à corriger", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private func candidateRow(_ candidate: RestaurantImportCandidate) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(candidate.name.isEmpty ? "Restaurant sans nom" : candidate.name)
                .font(.headline)
            if !candidate.address.isEmpty {
                Text(candidate.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !candidate.issues.isEmpty {
                ForEach(candidate.issues, id: \.self) { issue in
                    Label(issue, systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } else if duplicateIDs.contains(candidate.id) {
                Label("Déjà présent dans l’application", systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Label("Prêt à importer", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }

    private func validateAndDismissKeyboard() {
        validate()
        jsonEditorIsFocused = false
    }

    private func validate() {
        do {
            candidates = try RestaurantJSONImporter.parse(jsonText)
            errorMessage = nil
            importDuplicates = false
        } catch {
            candidates = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func importRestaurants() {
        let selected = importableCandidates
        var inserted: [Restaurant] = []

        for candidate in selected {
            let restaurant = Restaurant(
                name: candidate.name,
                address: candidate.address,
                rating: candidate.rating,
                cuisine: candidate.cuisine,
                comment: candidate.comment,
                website: candidate.website,
                foodingURL: candidate.foodingURL,
                phone: candidate.phone,
                status: candidate.status,
                isFavorite: candidate.isFavorite,
                latitude: candidate.latitude,
                longitude: candidate.longitude
            )
            modelContext.insert(restaurant)
            inserted.append(restaurant)
        }

        do {
            try modelContext.save()
        } catch {
            inserted.forEach(modelContext.delete)
            saveError = "Les restaurants n’ont pas pu être enregistrés : \(error.localizedDescription)"
            return
        }

        let restaurantsToGeocode = inserted.filter { $0.latitude == nil || $0.longitude == nil }
        Task { @MainActor in
            for restaurant in restaurantsToGeocode {
                if let coordinate = await coordinates(for: restaurant.address) {
                    restaurant.latitude = coordinate.latitude
                    restaurant.longitude = coordinate.longitude
                }
            }
            try? modelContext.save()
        }
        dismiss()
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func coordinates(for address: String) async -> CLLocationCoordinate2D? {
        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        if #available(iOS 26.0, *) {
            guard let request = MKGeocodingRequest(addressString: address),
                  let item = try? await request.mapItems.first else { return nil }
            return item.location.coordinate
        } else {
            guard let placemark = try? await CLGeocoder().geocodeAddressString(address).first,
                  let coordinate = placemark.location?.coordinate else { return nil }
            return coordinate
        }
    }

    private static let exampleJSON = """
    {
      "version": 1,
      "restaurants": [
        {
          "nom": "Exemple Restaurant",
          "adresse": "Place du Châtelain 7, 1050 Ixelles, Belgique",
          "cuisine": "Italienne",
          "statut": "Aucun",
          "favori": false,
          "note": 0,
          "commentaire": "À découvrir.",
          "telephone": "+32 2 000 00 00",
          "site_web": "https://example.com",
          "lien_fooding": ""
        }
      ]
    }
    """
}
