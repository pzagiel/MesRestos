import Foundation
import SwiftData

@Model
final class Restaurant {
    var name: String
    var address: String
    var city: String = ""
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

        guard let cityPart = parts.last else { return "" }
        return cityPart
            .replacingOccurrences(of: #"^\d{4,5}\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
