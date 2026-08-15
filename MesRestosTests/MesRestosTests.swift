//
//  MesRestosTests.swift
//  MesRestosTests
//
//  Created by patrick zagiel on 09/08/2026.
//

import Testing
@testable import TestAI1

struct MesRestosTests {

    @Test func restaurantKeepsProvidedValues() {
        let restaurant = Restaurant(
            name: "La Table",
            address: "1 rue du Centre",
            rating: 4.5,
            cuisine: "Française",
            comment: "Très bon accueil",
            latitude: 50.8503,
            longitude: 4.3517
        )

        #expect(restaurant.name == "La Table")
        #expect(restaurant.rating == 4.5)
        #expect(restaurant.cuisine == "Française")
        #expect(restaurant.comment == "Très bon accueil")
        #expect(restaurant.latitude == 50.8503)
    }

    @Test func restaurantCanBeSavedWithoutLocation() {
        let restaurant = Restaurant(
            name: "Adresse à vérifier",
            address: "Une adresse inconnue",
            rating: 3,
            cuisine: "Autre"
        )

        #expect(restaurant.latitude == nil)
        #expect(restaurant.longitude == nil)
    }

    @Test func jsonImportParsesACompleteDocument() throws {
        let json = #"""
        {
          "version": 1,
          "restaurants": [{
            "nom": "La Table JSON",
            "adresse": "1 rue du Centre, Bruxelles",
            "cuisine": "Italienne",
            "statut": "Favori",
            "note": 4.5,
            "site_web": "latable.example",
            "localisation": { "latitude": 50.85, "longitude": 4.35 }
          }]
        }
        """#

        let candidates = try RestaurantJSONImporter.parse(json)

        #expect(candidates.count == 1)
        #expect(candidates[0].name == "La Table JSON")
        #expect(candidates[0].status == "Favori")
        #expect(candidates[0].website == "https://latable.example")
        #expect(candidates[0].latitude == 50.85)
        #expect(candidates[0].isValid)
    }

    @Test func jsonImportReportsMissingRequiredFields() throws {
        let candidates = try RestaurantJSONImporter.parse(#"[{"cuisine":"Belge"}]"#)

        #expect(candidates.count == 1)
        #expect(!candidates[0].isValid)
        #expect(candidates[0].issues.count == 2)
    }

}
