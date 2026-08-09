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

}
