import Foundation
import SwiftData

@Model
final class Restaurant {
    var name: String
    var address: String
    var city: String = ""
    var country: String = ""
    var rating: Double
    var cuisine: String
    var comment: String = ""
    var website: String = ""
    var foodingURL: String = ""
    var phone: String = ""
    var status: String = "Aucun"
    var isFavorite: Bool = false
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date

    init(
        name: String,
        address: String,
        city: String = "",
        country: String = "",
        rating: Double,
        cuisine: String,
        comment: String = "",
        website: String = "",
        foodingURL: String = "",
        phone: String = "",
        status: String = "Aucun",
        isFavorite: Bool = false,
        latitude: Double? = nil,
        longitude: Double? = nil,
        createdAt: Date = .now
    ) {
        self.name = name
        self.address = address
        self.city = city.isEmpty ? RestaurantCityResolver.city(from: address) : city
        self.country = country.isEmpty ? RestaurantCityResolver.country(from: address) : country
        self.rating = rating
        self.cuisine = cuisine
        self.comment = comment
        self.website = website
        self.foodingURL = foodingURL
        self.phone = phone
        self.status = status
        self.isFavorite = isFavorite
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
}

enum RestaurantCityResolver {
    static func city(from address: String) -> String {
        var parts = address
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard parts.count >= 2 else { return "" }

        let countries = ["belgique", "belgium", "italie", "italy", "france", "pays-bas", "netherlands"]
        if let last = parts.last,
           countries.contains(last.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()) {
            parts.removeLast()
        }

        while let last = parts.last,
              last.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased().hasPrefix("province of ") {
            parts.removeLast()
        }

        guard let cityPart = parts.last else { return "" }
        let extracted = cityPart
            .replacingOccurrences(of: #"^\d{4,5}\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+[A-Z]{2}$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return canonicalCity(extracted)
    }

    static func country(from address: String) -> String {
        guard let lastPart = address.split(separator: ",").last else { return "" }
        let value = lastPart.trimmingCharacters(in: .whitespacesAndNewlines)
        return canonicalCountry(value)
    }

    static func canonicalCountry(_ value: String) -> String {
        switch folded(value) {
        case "belgique", "belgium": return "Belgique"
        case "italie", "italy", "italia": return "Italie"
        case "france": return "France"
        case "pays-bas", "netherlands", "nederland": return "Pays-Bas"
        default: return value
        }
    }

    static func canonicalCity(_ value: String) -> String {
        let cleaned = value
            .replacingOccurrences(of: #"^\d{4,5}\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+[A-Z]{2}$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch folded(cleaned) {
        case "sienne", "siena": return "Siena"
        case "bruxelles", "brussels", "brussel": return "Bruxelles"
        case "montepulciano stazione": return "Montepulciano"
        case "montefollonico": return "Torrita di Siena"
        case "la dogana", "camucia": return "Cortona"
        case "farniole": return "Foiano della Chiana"
        case "guazzino": return "Sinalunga"
        case "cortona, province of arezzo": return "Cortona"
        default: return cleaned
        }
    }

    private static func folded(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}
