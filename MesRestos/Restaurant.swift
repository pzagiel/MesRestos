import Foundation
import SwiftData

@Model
final class Restaurant {
    var name: String
    var address: String
    var rating: Double
    var cuisine: String
    var comment: String = ""
    var website: String = ""
    var phone: String = ""
    var status: String = "À tester"
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date

    init(
        name: String,
        address: String,
        rating: Double,
        cuisine: String,
        comment: String = "",
        website: String = "",
        phone: String = "",
        status: String = "À tester",
        latitude: Double? = nil,
        longitude: Double? = nil,
        createdAt: Date = .now
    ) {
        self.name = name
        self.address = address
        self.rating = rating
        self.cuisine = cuisine
        self.comment = comment
        self.website = website
        self.phone = phone
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
}
