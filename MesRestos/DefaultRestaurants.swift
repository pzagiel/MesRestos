import Foundation
import MapKit
import SwiftData

@MainActor
enum DefaultRestaurants {
    private static let seedKey = "hasSeededFoodingRestaurantsV9"

    private struct Seed {
        let name: String
        let address: String
        let cuisine: String
        var comment: String = "Sélection Le Fooding — à découvrir."
        var website: String = ""
        var phone: String = ""
    }

    private static let restaurants = [
        Seed(name: "Eight", address: "Rue du Pépin 48, 1000 Bruxelles, Belgique", cuisine: "Cuisine d’auteur", website: "https://www.instagram.com/eight.brussels/"),
        Seed(name: "Cosmos", address: "Rue du Trône 65, 1050 Bruxelles, Belgique", cuisine: "Cuisine d’auteur", website: "https://www.cosmosrestaurant.be/"),
        Seed(name: "Munch", address: "Rue de Savoie 13, 1060 Saint-Gilles, Belgique", cuisine: "Cuisine gourmande", website: "https://munchbxl.be/"),
        Seed(name: "Daily 3000", address: "Rue Antoine Bréart 20A, 1060 Saint-Gilles, Belgique", cuisine: "Cuisine gourmande", website: "https://www.instagram.com/daily_3000/"),
        Seed(name: "Frank", address: "Rue des Princes 14, 1000 Bruxelles, Belgique", cuisine: "Café et brunch", website: "https://www.frank.brussels/"),
        Seed(name: "L’Épicerie", address: "Rue du Page 66, 1050 Ixelles, Belgique", cuisine: "Table d’hôte", website: "https://www.restaurantlepicerie.com/"),
        Seed(name: "Gourmets Everyday", address: "Rue des Poissonniers 10, 1000 Bruxelles, Belgique", cuisine: "Asiatique", website: "https://www.gourmeteveryday.be/"),
        Seed(name: "Albert", address: "Mont des Arts 28, 1000 Bruxelles, Belgique", cuisine: "Néobistrot", website: "https://www.albert.brussels/"),
        Seed(name: "Le 203", address: "Chaussée de Waterloo 203, 1060 Saint-Gilles, Belgique", cuisine: "Néobistrot", website: "https://www.le203brussels.com/"),
        Seed(name: "Little Apo", address: "Avenue Adolphe Demeur 3, 1060 Saint-Gilles, Belgique", cuisine: "Asiatique", website: "http://www.littleapo.be/"),
        Seed(name: "Old Boy", address: "Rue de Tenbosch 110, 1050 Ixelles, Belgique", cuisine: "Asiatique", website: "https://oldboyrestaurant.be/"),
        Seed(name: "Thai Café", address: "Chaussée de Waterloo 412B, 1050 Ixelles, Belgique", cuisine: "Asiatique", website: "https://www.thaicafe.be/"),
        Seed(name: "Le Selecto", address: "Rue de Flandre 95-97, 1000 Bruxelles, Belgique", cuisine: "Bistronomie", website: "https://leselecto.com/"),
        Seed(name: "Gelateria Giotto", address: "Rue Washington 152, 1050 Ixelles, Belgique", cuisine: "Glacier", website: "https://www.visit.brussels/en/visitors/where-to-eat/the-best-places-to-enjoy-an-ice-cream-in-brussels"),
        Seed(name: "La Piola", address: "Rue du Page 2, 1050 Ixelles, Belgique", cuisine: "Italienne", website: "https://www.lapiola.be/"),
        Seed(name: "Maison N°7", address: "Place du Châtelain 49, 1050 Ixelles, Belgique", cuisine: "Italienne", website: "https://www.maisonnumero7.com/"),
        Seed(name: "Shi Shang", address: "Chaussée d’Alsemberg 125, 1060 Saint-Gilles, Belgique", cuisine: "Asiatique", website: "https://www.shi-shang.be/", phone: "+32 2 721 05 72"),
        Seed(name: "La Piola Pizza", address: "Place Saint-Josse 8, 1210 Saint-Josse-ten-Noode, Belgique", cuisine: "Italienne", website: "https://lapiolapizza.com/", phone: "+32 2 465 02 15"),
        Seed(name: "Biga Pizzeria", address: "Place Colignon 18, 1030 Schaerbeek, Belgique", cuisine: "Italienne", website: "https://pizzeriabiga.be/", phone: "+32 472 90 68 33"),
        Seed(name: "Ciaooo Pizzeria", address: "Avenue du Diamant 199A, 1030 Schaerbeek, Belgique", cuisine: "Italienne", website: "https://www.ciaooopizzeria.be/", phone: "+32 2 310 06 20"),
        Seed(name: "450 Gradi", address: "Avenue Émile Max 90, 1030 Schaerbeek, Belgique", cuisine: "Italienne", website: "https://www.450gradi.be/", phone: "+32 494 21 87 13"),
        Seed(
            name: "Au Village de Shanghai",
            address: "Chaussée de Helmet 318, 1030 Schaerbeek, Belgique",
            cuisine: "Asiatique",
            comment: "Très bon canard laqué.",
            website: "https://www.au-village-de-shanghai.be/",
            phone: "+32 2 215 83 37"
        ),
        Seed(
            name: "Le Guépard",
            address: "Rue de l’Aqueduc 76, 1050 Ixelles, Belgique",
            cuisine: "Française",
            comment: "La brasserie du chef Alexandre Cardoso.",
            website: "https://www.leguepard.be/",
            phone: "+32 2 751 30 16"
        ),
        Seed(
            name: "Môme",
            address: "Rue Veydt 41, 1050 Ixelles, Belgique",
            cuisine: "Bistronomie",
            comment: "Bistrot de quartier — sélection Le Fooding.",
            website: "https://www.instagram.com/momebrussels/",
            phone: "+32 492 44 91 74"
        )
    ]

    static func insertIfNeeded(in modelContext: ModelContext) async {
        let existingRestaurants = (try? modelContext.fetch(FetchDescriptor<Restaurant>())) ?? []
        normalizeAsianCuisine(in: existingRestaurants)
        updateWebsites(in: existingRestaurants)
        updateKnownPhones(in: existingRestaurants)

        guard !UserDefaults.standard.bool(forKey: seedKey) else {
            try? modelContext.save()
            return
        }
        UserDefaults.standard.set(true, forKey: seedKey)

        let existingNames = Set(existingRestaurants.map { $0.name.lowercased() })

        for seed in restaurants where !existingNames.contains(seed.name.lowercased()) {
            let restaurant = Restaurant(
                name: seed.name,
                address: seed.address,
                rating: 0,
                cuisine: seed.cuisine,
                comment: seed.comment,
                website: seed.website,
                phone: seed.phone
            )
            modelContext.insert(restaurant)

            if let request = MKGeocodingRequest(addressString: seed.address),
               let coordinate = try? await request.mapItems.first?.location.coordinate {
                restaurant.latitude = coordinate.latitude
                restaurant.longitude = coordinate.longitude
            }
        }

        let allRestaurants = (try? modelContext.fetch(FetchDescriptor<Restaurant>())) ?? []
        await findMissingPhones(in: allRestaurants)

        try? modelContext.save()
    }

    private static func updateKnownPhones(in existingRestaurants: [Restaurant]) {
        let phones = Dictionary(uniqueKeysWithValues: restaurants.compactMap { seed in
            seed.phone.isEmpty ? nil : (seed.name.lowercased(), seed.phone)
        })
        for restaurant in existingRestaurants where restaurant.phone.isEmpty {
            restaurant.phone = phones[restaurant.name.lowercased()] ?? ""
        }
    }

    private static func findMissingPhones(in restaurants: [Restaurant]) async {
        for restaurant in restaurants where restaurant.phone.isEmpty {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(restaurant.name), \(restaurant.address)"
            if let response = try? await MKLocalSearch(request: request).start(),
               let phone = response.mapItems.first?.phoneNumber,
               !phone.isEmpty {
                restaurant.phone = phone
            }
        }
    }

    private static func updateWebsites(in existingRestaurants: [Restaurant]) {
        let websites = Dictionary(uniqueKeysWithValues: restaurants.compactMap { seed in
            seed.website.isEmpty ? nil : (seed.name.lowercased(), seed.website)
        })
        for restaurant in existingRestaurants where restaurant.website.isEmpty {
            restaurant.website = websites[restaurant.name.lowercased()] ?? ""
        }
        if let selecto = existingRestaurants.first(where: {
            $0.name.caseInsensitiveCompare("Le Selecto") == .orderedSame
        }), selecto.website == "https://www.le-selecto.com/" {
            selecto.website = "https://leselecto.com/"
        }
    }

    private static func normalizeAsianCuisine(in restaurants: [Restaurant]) {
        let asianRestaurantNames = ["little apo", "old boy", "thai café", "gourmets everyday"]
        for restaurant in restaurants where asianRestaurantNames.contains(restaurant.name.lowercased()) {
            restaurant.cuisine = "Asiatique"
        }
        restaurants.first { $0.name.caseInsensitiveCompare("Gelateria Giotto") == .orderedSame }?.cuisine = "Glacier"
    }
}
