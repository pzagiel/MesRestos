import Foundation
import MapKit
import CoreLocation
import SwiftData

@MainActor
enum DefaultRestaurants {
    private static let seedKey = "hasSeededFoodingRestaurantsV13"

    private struct Seed {
        let name: String
        let address: String
        let cuisine: String
        var comment: String = "Sélection Le Fooding — à découvrir."
        var website: String = ""
        var foodingURL: String = ""
        var phone: String = ""
        var rating: Double = 0
        var status: String = "Aucun"
        var isFavorite: Bool = false
        var latitude: Double? = nil
        var longitude: Double? = nil
    }

    private struct ItalianRestaurantDocument: Decodable {
        let restaurants: [ItalianRestaurant]
    }

    private struct ItalianRestaurant: Decodable {
        let nom: String
        let adresse: String
        let cuisine: String?
        let statut: String?
        let note: Double?
        let commentaire: String?
        let telephone: String?
        let siteWeb: String?
        let lienFooding: String?
        let localisation: ItalianLocation?

        enum CodingKeys: String, CodingKey {
            case nom, adresse, cuisine, statut, note, commentaire, telephone, localisation
            case siteWeb = "site_web"
            case lienFooding = "lien_fooding"
        }
    }

    private struct ItalianLocation: Decodable {
        let latitude: Double?
        let longitude: Double?
    }

    private static let curatedRestaurants = [
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

    private static let foodingBrusselsRestaurants = [
        Seed(name: "Ajiyoshi", address: "Quai aux Briques 32, 1000 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/ajiyoshi", latitude: 50.8517218, longitude: 4.3476813),
        Seed(name: "Albert", address: "Mont des Arts 28, 1000 Bruxelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/albert", latitude: 50.8432348, longitude: 4.3570704),
        Seed(name: "Alley Mian", address: "Rue de l'Ecuyer 45, 1000 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/alley-mian", latitude: 50.8487749, longitude: 4.3545569),
        Seed(name: "Amakara", address: "Rue du Doyenné 40, Uccle, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/amakara", latitude: 50.8067222, longitude: 4.3377043),
        Seed(name: "Anju", address: "Rue de la Source 73, 1060 Saint-Gilles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/anju", latitude: 50.83095580000001, longitude: 4.353268700000001),
        Seed(name: "Asturias", address: "Rue de l'Argonne 14, 1060 Saint-Gilles, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/asturias", latitude: 50.8384405, longitude: 4.338363),
        Seed(name: "Au Repos de la Montagne", address: "Montagne de Saint-Job 39, 1180 Uccle, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/au-repos-de-la-montagne", latitude: 50.7933341, longitude: 4.365810699999999),
        Seed(name: "Au Stekerlapatte", address: "Rue des Prêtres 4, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/au-stekerlapatte", latitude: 50.8352651, longitude: 4.3493976),
        Seed(name: "Auntie Café", address: "Rue Grétry 25, 1000 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/auntie-cafe", latitude: 50.8494105, longitude: 4.3512985),
        Seed(name: "Babam", address: "Avenue du Bois de la Cambre 25, 1170 Watermael-Boitsfort, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/babam", latitude: 50.8096087, longitude: 4.3957299),
        Seed(name: "Baladi", address: "Rue des Chapeliers 6, 1000 Bruxelles, Belgique", cuisine: "Moyen-Orientale", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/baladi", latitude: 50.8460797, longitude: 4.352909299999999),
        Seed(name: "Bar Billie", address: "Rue Sainte-Catherine 42, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/bar-billie", latitude: 50.8501444, longitude: 4.3473986),
        Seed(name: "Barge", address: "Boulevard d'Ypres 33, 1000 Bruxelles, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/barge", latitude: 50.8569384, longitude: 4.3469411),
        Seed(name: "Barkboy", address: "Rue de l'Enseignement 20, 1000 Bruxelles, Belgique", cuisine: "Café et brunch", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/barkboy", latitude: 50.8481631, longitude: 4.3635547),
        Seed(name: "Batch", address: "Chaussée de Waterloo 559, 1050 Ixelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/batch", latitude: 50.8191998, longitude: 4.361247000000001),
        Seed(name: "Bautier Café", address: "Chaussée de Forest 314, 1190 Forest, Bruxelles, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/bautier", latitude: 50.82547640000001, longitude: 4.3372186),
        Seed(name: "Beaucoup Fish", address: "Rue Van Gaver 2, 1000 Bruxelles, Belgique", cuisine: "Autre", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/beaucoup-fish", latitude: 50.8557773, longitude: 4.3512202),
        Seed(name: "Beijingya", address: "Rue Melsens 8, 1000 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/beijingya", latitude: 50.8502276, longitude: 4.349219),
        Seed(name: "Belle Lurette", address: "Avenue Adolphe Demeur 57, 1060 Saint-Gilles, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/belle-lurette", latitude: 50.8253062, longitude: 4.344141899999999),
        Seed(name: "Beyrouth", address: "Bergensesteenweg 80, 1070 Anderlecht, Belgique", cuisine: "Moyen-Orientale", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/beyrouth", latitude: 50.84362549999999, longitude: 4.3340315),
        Seed(name: "Biga", address: "Place Colignon 18, 1030 Schaerbeek, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/biga", latitude: 50.8670963, longitude: 4.3741619),
        Seed(name: "Bintje", address: "Rue Simonis 62, 1050 Ixelles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/bintje", latitude: 50.8255335, longitude: 4.3604331),
        Seed(name: "Bisous", address: "Rue du Bailli 35, 1050 Ixelles, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/bisous", latitude: 50.8265109, longitude: 4.3615129),
        Seed(name: "Bombay BBQ", address: "Chaussée d'Ixelles 280, Ixelles, Belgique", cuisine: "Indienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/bombay-bbq", latitude: 50.8292594, longitude: 4.3704151),
        Seed(name: "Brut", address: "Rue Antoine Labarre 49, 1050 Ixelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/brut", latitude: 50.8254135, longitude: 4.3756787),
        Seed(name: "Café Boudin", address: "Rue Ravenstein 20, 1000 Bruxelles, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/cafe-boudin", latitude: 50.8446038, longitude: 4.359213899999999),
        Seed(name: "Café Circus", address: "Place de Londres 7, 1050 Ixelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/cafe-circus", latitude: 50.8378143, longitude: 4.3684275),
        Seed(name: "Café Palto", address: "Place Saint-Lambert 8, 1020 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/cafe-palto", latitude: 50.89033260000001, longitude: 4.3442519),
        Seed(name: "Café des Minimes", address: "Rue des Minimes 60, 1000 Bruxelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/cafe-des-minimes", latitude: 50.8393002, longitude: 4.352894),
        Seed(name: "Certo", address: "Rue Longue Vie 48, Ixelles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/certo", latitude: 50.8357261, longitude: 4.366640299999999),
        Seed(name: "Chana", address: "Parvis de Saint-Gilles 24, 1060 Saint-Gilles, Belgique", cuisine: "Indienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/chana", latitude: 50.8308447, longitude: 4.345757799999999),
        Seed(name: "Charivari", address: "Rue de la Croix de Pierre 34, 1060 Saint-Gilles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/charivari", latitude: 50.8305809, longitude: 4.3510715),
        Seed(name: "Chaudron", address: "Rue du Chaudron 20, 1070 Anderlecht, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/chaudron", latitude: 50.8264608, longitude: 4.2689921),
        Seed(name: "Chez Diallo", address: "Chaussée d'Anvers 84, 1000 Bruxelles, Belgique", cuisine: "Africaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/chez-diallo", latitude: 50.8600326, longitude: 4.3550965),
        Seed(name: "Chez Luma", address: "Rue de la Fauvette 17, 1180 Uccle, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/chez-luma", latitude: 50.7983026, longitude: 4.3381512),
        Seed(name: "Chez Monsieur Yang", address: "Chaussée de Boondael 320, 1050 Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/chez-monsieur-yang", latitude: 50.8185924, longitude: 4.3843746),
        Seed(name: "Chez Richard", address: "Rue des Minimes 2, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/chez-richard", latitude: 50.8412709, longitude: 4.3539572),
        Seed(name: "Chez/Bij Jansens & Jansens", address: "Zuidlaan 90, 1000 Brussel, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/chez-bij-jansens-jansens-2", latitude: 50.8375575, longitude: 4.342073399999999),
        Seed(name: "Churrasqueira Portugalia", address: "Chaussée de Waterloo 30, 1060 Saint-Gilles, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/churrasqueira-portugalia", latitude: 50.8316555, longitude: 4.3449592),
        Seed(name: "Cipiace", address: "Parvis de Saint-Gilles 49A, 1060 Saint-Gilles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/cipiace", latitude: 50.830551, longitude: 4.345956399999999),
        Seed(name: "Coin Coin", address: "Avenue Jules de Trooz 13, 1150 Woluwe-Saint-Pierre, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/coin-coin", latitude: 50.83565120000001, longitude: 4.4290413),
        Seed(name: "Correspondance", address: "Rue Picard 9, Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/correspondance", latitude: 50.8639896, longitude: 4.3450064),
        Seed(name: "Cosmos", address: "Rue du Trône 65, 1050 Ixelles, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/cosmos", latitude: 50.83817120000001, longitude: 4.368359799999999),
        Seed(name: "Da Long Yi", address: "Quai au Bois à Brûler 55, 1000 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/da-long-yi", latitude: 50.85318239999999, longitude: 4.3476884),
        Seed(name: "Daily 3000", address: "Rue Antoine Bréart 20a, 1060 Saint-Gilles, Belgique", cuisine: "Café et brunch", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/daily-3000", latitude: 50.8239521, longitude: 4.3494253),
        Seed(name: "Damn Good Café", address: "Rue Saint-Jean Népomucène 10, 1000 Bruxelles, Belgique", cuisine: "Café et brunch", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/damn-good-cafe", latitude: 50.8556706, longitude: 4.354134),
        Seed(name: "Dastaan", address: "Avenue Georges Henri 373, Saint-Lambert 1200 Woluwe-Saint-Lambert, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/dastaan", latitude: 50.8428642, longitude: 4.4089193),
        Seed(name: "Eight", address: "Rue du Pépin 48, 1000 Bruxelles, Belgique", cuisine: "Café et brunch", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/eight", latitude: 50.8389751, longitude: 4.3604164),
        Seed(name: "Elbow Lunch Counter", address: "Rue de la Paix 32, 1050 Ixelles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/elbow-lunch-counter", latitude: 50.8361419, longitude: 4.3654908),
        Seed(name: "Eliane", address: "Rue Saint-Laurent 36, 1000 Bruxelles, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/eliane", latitude: 50.8507235, longitude: 4.359947399999999),
        Seed(name: "Entre-Nous", address: "Rue de Mérode 29, 1060 Saint-Gilles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/entre-nous", latitude: 50.8358743, longitude: 4.3398618),
        Seed(name: "Entropy", address: "Place Saint-Géry 22, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/entropy", latitude: 50.8477153, longitude: 4.3469547),
        Seed(name: "Epicerie Nomad", address: "Rue Keyenveld 56, 1050 Ixelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/epicerie-nomad", latitude: 50.8346007, longitude: 4.361715400000001),
        Seed(name: "Era", address: "Rue du Fossé aux Loups 46, 1000 Bruxelles, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/era", latitude: 50.8500443, longitude: 4.355799999999999),
        Seed(name: "Familia", address: "Chaussée de Bruxelles 181, 1190 Forest, Belgique", cuisine: "Autre", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/familia", latitude: 50.81409379999999, longitude: 4.325476),
        Seed(name: "Fava", address: "Boulevard de Waterloo 113, 1000 Bruxelles, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/fava", latitude: 50.8335605, longitude: 4.348684599999999),
        Seed(name: "Fernand Obb", address: "Rue de Tamines 27, 1060 Saint-Gilles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/fernand-obb", latitude: 50.8260055, longitude: 4.3474941),
        Seed(name: "Fight Club", address: "Chaussée de Waterloo 50, 1060 Saint-Gilles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/fight-club", latitude: 50.8311224, longitude: 4.3448246),
        Seed(name: "Fish Tank", address: "Rue Haute 246, 1000 Bruxelles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/fish-tank", latitude: 50.8367329, longitude: 4.3485013),
        Seed(name: "Flamme", address: "Rue de Roumanie 56, 1060 Saint-Gilles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/flamme", latitude: 50.8272006, longitude: 4.349842),
        Seed(name: "Flipper's", address: "Rue Lesbroussart 13, 1050 Ixelles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/flippers", latitude: 50.82791, longitude: 4.3704505),
        Seed(name: "Flâne", address: "Rue des Trois Tilleuls 1, 1170 Watermael-Boitsfort, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/winery", latitude: 50.7992795, longitude: 4.4181659),
        Seed(name: "Frangines", address: "Rue de Stalle 110, 1180 Uccle, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/frangines", latitude: 50.7969432, longitude: 4.3302775),
        Seed(name: "Frank", address: "Rue des Princes 14, 1000 Bruxelles, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/frank", latitude: 50.8499002, longitude: 4.3546084),
        Seed(name: "Frasca", address: "Rue de Florence 21, 1050 Ixelles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/frasca", latitude: 50.8293869, longitude: 4.3593221),
        Seed(name: "Friture René", address: "Place de la Résistance 14, 1070 Anderlecht, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/friture-rene", latitude: 50.83578960000001, longitude: 4.3111618),
        Seed(name: "Garage-à-Manger", address: "Rue Washington 185, 1050 Ixelles, Belgique", cuisine: "Autre", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/garage-a-manger", latitude: 50.8191543, longitude: 4.3627383),
        Seed(name: "Gazzetta", address: "Rue de la Longue Haie 12, 1050 Ixelles, Bruxelles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/gazzetta", latitude: 50.83154039999999, longitude: 4.3605569),
        Seed(name: "Gazzosa", address: "Rue Saint-Jean 17, 1000 Bruxelles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/gazzosa", latitude: 50.8445195, longitude: 4.3548779),
        Seed(name: "Gourmets Everyday", address: "Rue des Poissonniers 10, 1000 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/gourmets-everyday", latitude: 50.8491796, longitude: 4.3487275),
        Seed(name: "Grabuge", address: "Chaussée de Waterloo 179, 1060 Saint-Gilles, Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/grabuge-3", latitude: 50.826444, longitude: 4.345461900000001),
        Seed(name: "Gratin", address: "Place du Châtelain 47, 1050 Ixelles, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/gratin", latitude: 50.8249878, longitude: 4.3611946),
        Seed(name: "Groseille", address: "Chaussée de Louvain 309, 1030 Schaerbeek, Bruxelles, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/groseille", latitude: 50.8520724, longitude: 4.3859165),
        Seed(name: "Hanoi Station", address: "Avenue des Celtes 6, 1040 Etterbeek, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/hanoi-station", latitude: 50.8387968, longitude: 4.398547800000001),
        Seed(name: "Hau", address: "Avenue Salomé 1, 1150 Woluwe-Saint-Pierre, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/hau", latitude: 50.8311844, longitude: 4.4547062),
        Seed(name: "Henri", address: "Rue de Flandre 113, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/henri", latitude: 50.8530293, longitude: 4.3450618),
        Seed(name: "Holy Smoke", address: "Avenue de la Porte de Hal 9, 1060 Saint-Gilles, Bruxelles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/holy-smoke", latitude: 50.8326167, longitude: 4.3438873),
        Seed(name: "Honest", address: "Rue du Croissant 34, 1190 Forest, Belgique", cuisine: "Café et brunch", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/honest", latitude: 50.8282104, longitude: 4.3326592),
        Seed(name: "Horia", address: "Borgwal 7, 1000 Bruxelles, Belgique", cuisine: "Africaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/horia", latitude: 50.8476412, longitude: 4.3484143),
        Seed(name: "Huimian", address: "Chaussée de Boondael 272, 1050 Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/huimian", latitude: 50.8195612, longitude: 4.3829635),
        Seed(name: "In't Spinnekopke", address: "Place du Jardin aux Fleurs 1, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/int-spinnekopke", latitude: 50.84805619999999, longitude: 4.3437902),
        Seed(name: "Iyagi", address: "Rue Longue Vie 40, 1050 Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/iyagi", latitude: 50.83595159999999, longitude: 4.3663547),
        Seed(name: "Jayu", address: "Rue de Flandre 19, 1000 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/jayu", latitude: 50.85109509999999, longitude: 4.3469722),
        Seed(name: "Kaiju", address: "Chaussée de Charleroi 132, Saint-Gilles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/kaiju", latitude: 50.8271536, longitude: 4.355335600000001),
        Seed(name: "Kamo", address: "Chaussée de Waterloo 550A, 1050 Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/kamo", latitude: 50.8193998, longitude: 4.3614894),
        Seed(name: "Kamoun", address: "Rue de la Levure 29, 1050 Ixelles, Belgique", cuisine: "Moyen-Orientale", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/kamoun", latitude: 50.8283067, longitude: 4.375899899999999),
        Seed(name: "Kartouche", address: "Rue Defacqz 58, 1050 Ixelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/kartouche", latitude: 50.8276179, longitude: 4.3591961),
        Seed(name: "Kitsune Burger", address: "Petite Rue des Bouchers 25, 1000 Bruxelles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/kitsune-burger", latitude: 50.8478596, longitude: 4.3537778),
        Seed(name: "Kline", address: "Rue de Flandre 162, 1000 Bruxelles, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/kline", latitude: 50.8529279, longitude: 4.343556200000001),
        Seed(name: "Klok", address: "Place Rouppe 10, 1000 Bruxelles, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/klok", latitude: 50.843005, longitude: 4.3463237),
        Seed(name: "Konchu", address: "Rue Ernest Solvay 20, 1050 Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/konchu", latitude: 50.8363024, longitude: 4.364491399999999),
        Seed(name: "Kookoo", address: "Rue de la Victoire 232, 1060 Saint-Gilles, Belgique", cuisine: "Café et brunch", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/kookoo", latitude: 50.8258442, longitude: 4.354503200000001),
        Seed(name: "Kosto", address: "Quai des Péniches 35, 1000 Bruxelles, Belgique", cuisine: "Café et brunch", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/kosto", latitude: 50.8617735, longitude: 4.3500279),
        Seed(name: "Koul", address: "Quai du Hainaut 7, 1080 Molenbeek-Saint-Jean, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/koul", latitude: 50.852881, longitude: 4.3402755),
        Seed(name: "Kras Mat", address: "Avenue Louis Bertrand 61, 1030 Schaerbeek, Bruxelles, Belgique", cuisine: "Autre", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/kras-mat", latitude: 50.8634278, longitude: 4.3763497),
        Seed(name: "L'Altitude", address: "Avenue Molière 2, 1190 Forest, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/laltitude", latitude: 50.8155617, longitude: 4.339934899999999),
        Seed(name: "L'Express", address: "Rue des Chapeliers 8, 1000 Bruxelles, Belgique", cuisine: "Moyen-Orientale", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/lexpress", latitude: 50.8460429, longitude: 4.352867),
        Seed(name: "L'Horloge du Sud", address: "Rue du Trône 141, 1050 Ixelles, Bruxelles, Belgique", cuisine: "Africaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/lhorloge-du-sud", latitude: 50.8358898, longitude: 4.3711681),
        Seed(name: "L'Épicerie", address: "Rue du Page 66, 1050 Ixelles, Belgique", cuisine: "Autre", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/lepicerie", latitude: 50.8225038, longitude: 4.358066099999999),
        Seed(name: "La Bonne Chère", address: "Rue Notre-Seigneur 19, 1000 Bruxelles, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/la-bonne-chere", latitude: 50.8403731, longitude: 4.3503258),
        Seed(name: "La Bottega Della Pizza", address: "Avenue Ducpétiaux 39, 1060 Saint-Gilles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/la-bottega-della-pizza", latitude: 50.8235471, longitude: 4.3514832),
        Seed(name: "La Charcuterie", address: "Avenue Paul Dejaer 16, 1060 Saint-Gilles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/la-charcuterie", latitude: 50.8263003, longitude: 4.3450407),
        Seed(name: "La Général", address: "Rue General Patton 24, 1050 Ixelles, Bruxelles, Belgique", cuisine: "Latino-américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-generale", latitude: 50.81708709999999, longitude: 4.3677947),
        Seed(name: "La Sardine du Marseillais", address: "Rue Blaes 159, 1000 Bruxelles, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/la-sardine-du-marseillais", latitude: 50.8375389, longitude: 4.346894499999999),
        Seed(name: "La Stazione Alimentari", address: "Chaussée d'Alsemberg 411, 1180 Uccle, Bruxelles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/la-stazione-alimentari", latitude: 50.81394220000001, longitude: 4.338893000000001),
        Seed(name: "Lafeh", address: "Rue de la Fourche 2, 1000 Bruxelles, Belgique", cuisine: "Moyen-Orientale", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/lafeh", latitude: 50.84816989999999, longitude: 4.352435),
        Seed(name: "Le 203", address: "Chaussée de Waterloo 203, 1060 Saint-Gilles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-203", latitude: 50.8259207, longitude: 4.346475499999999),
        Seed(name: "Le Charlu", address: "Sint-Jobsesteenweg 676, 1180 Uccle, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-charlu", latitude: 50.7949534, longitude: 4.3649392),
        Seed(name: "Le Corbier", address: "Rue des Minimes 51, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-corbier", latitude: 50.839619, longitude: 4.352668299999999),
        Seed(name: "Le Dillens", address: "Place Julien Dillens 11, 1060 Saint-Gilles, Belgique", cuisine: "Café et brunch", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-dillens", latitude: 50.83175869999999, longitude: 4.3489774),
        Seed(name: "Le Fontainas", address: "Rue du Marché au Charbon 91, 1000 Bruxelles, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-fontainas", latitude: 50.8456392, longitude: 4.347773699999999),
        Seed(name: "Le Petit Bon Bon", address: "Rue Royale 103, 1000 Bruxelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-petit-bon-bon", latitude: 50.8512374, longitude: 4.3653292),
        Seed(name: "Le Petit Mercado", address: "Rue de l'Hôtel des Monnaies 82, 1060 Saint-Gilles, Belgique", cuisine: "Café et brunch", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-petit-mercado", latitude: 50.83041679999999, longitude: 4.3480869),
        Seed(name: "Le Phare du Kanaal", address: "Quai des Charbonnages 40, 1080 Molenbeek-Saint-Jean, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-phare-du-kanaal", latitude: 50.85551359999999, longitude: 4.3428601),
        Seed(name: "Le Pigeon Noir", address: "Rue Geleytsbeek 2, 1180 Uccle, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-pigeon-noir", latitude: 50.7921354, longitude: 4.348161600000001),
        Seed(name: "Le Tournant", address: "Chaussée de Wavre 168, Ixelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-tournant", latitude: 50.8357051, longitude: 4.3695761),
        Seed(name: "Le Vieux Mila", address: "Rue de Moscou 28, 1060 Saint-Gilles, Belgique", cuisine: "Africaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/le-vieux-mila", latitude: 50.8309736, longitude: 4.3460047),
        Seed(name: "Lee Chi Ko", address: "Middelweg 132C, 1130 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/lee-chi-ko", latitude: 50.8864445, longitude: 4.4203645),
        Seed(name: "Les Brassins", address: "Rue Keyenveld 36, 1050 Ixelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/les-brassins", latitude: 50.8351254, longitude: 4.3612155),
        Seed(name: "Les Brigittines", address: "Place de la Chapelle 5, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/les-brigittines", latitude: 50.841266, longitude: 4.3503582),
        Seed(name: "Les Jours de Damas", address: "Rue de l'Espérance 1, 1080 Molenbeek-Saint-Jean, Belgique", cuisine: "Moyen-Orientale", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/les-jours-de-damas", latitude: 50.85953869999999, longitude: 4.3413561),
        Seed(name: "Les Petits Bouchons", address: "Chaussée d’Alsemberg 832   1180 Uccle ", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/les-petits-bouchons", latitude: 50.7967468, longitude: 4.3359478),
        Seed(name: "Lil Bao", address: "Rue Haute 20, Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/lil-bao", latitude: 50.84172849999999, longitude: 4.352196999999999),
        Seed(name: "Little Apo", address: "Avenue Adolphe Demeur 3, 1060 Saint-Gilles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/little-apo", latitude: 50.82572, longitude: 4.3466954),
        Seed(name: "Lombric", address: "Avenue Everard 15, 1190 Forest, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/lombric", latitude: 50.816056, longitude: 4.3377409),
        Seed(name: "Lucifer Lives", address: "Rue Haute 120, 1000 Bruxelles, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/lucifer-lives", latitude: 50.8395442, longitude: 4.350990599999999),
        Seed(name: "MangiaSempre", address: "Rue des Alliés 196, 1190 Forest, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/mangiasempre", latitude: 50.82019829999999, longitude: 4.326948399999999),
        Seed(name: "Mangiavino", address: "Avenue Oscar Van Goidtsnoven 96, 1190 Forest, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/mangiavino", latitude: 50.8157867, longitude: 4.337027300000001),
        Seed(name: "Manneken Pis Café", address: "Rue des Grands Carmes 31-33, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/manneken-pis-cafe", latitude: 50.8452724, longitude: 4.3486204),
        Seed(name: "Maru", address: "Chaussée de Waterloo 510, 1050 Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/maru", latitude: 50.8200996, longitude: 4.360028),
        Seed(name: "Mauvais Choix", address: "Chaussée de Vleurgat 186, 1000 Bruxelles, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/mauvais-choix", latitude: 50.8219646, longitude: 4.3669458),
        Seed(name: "Mazmiz", address: "Rue du Taciturne 46, 1000 Bruxelles, Belgique", cuisine: "Moyen-Orientale", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/mazmiz", latitude: 50.8450305, longitude: 4.379059199999999),
        Seed(name: "Mendo", address: "Rue du Bailli 90, Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/mendo", latitude: 50.82545649999999, longitude: 4.3596675),
        Seed(name: "Mili", address: "Chaussée de Boondael 356, 1050 Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/mili", latitude: 50.8181063, longitude: 4.385746399999999),
        Seed(name: "Mine Madeh", address: "Chaussée de Wavre 390, 1040 Etterbeek, Belgique", cuisine: "Moyen-Orientale", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/mine-madeh", latitude: 50.8367196, longitude: 4.3809852),
        Seed(name: "Moutarde", address: "Rue Saint-Boniface 13, 1050 Ixelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/moutarde", latitude: 50.8360952, longitude: 4.3646457),
        Seed(name: "Munch", address: "Rue de Savoie 13, 1060 Saint-Gilles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/munch", latitude: 50.8246913, longitude: 4.347782700000001),
        Seed(name: "Môme", address: "Rue Veydt 41, 1050 Ixelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/mome", latitude: 50.8287737, longitude: 4.3582895),
        Seed(name: "Nightshop", address: "Rue de Flandre 167, 1000 Bruxelles, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/nightshop", latitude: 50.8534291, longitude: 4.343071999999999),
        Seed(name: "Nnadoz", address: "Rue Heyvaert 49, 1080 Molenbeek-Saint-Jean, Belgique", cuisine: "Africaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/nnadoz", latitude: 50.8480102, longitude: 4.3335972),
        Seed(name: "Nonbe Daigaku", address: "Avenue Adolphe Buyl 31, 1050 Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/nonbe-daigaku", latitude: 50.8172581, longitude: 4.3806132),
        Seed(name: "Nuovo Rosso", address: "Rue Bosquet 62, 1060 Saint-Gilles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/nuovo-rosso", latitude: 50.833574, longitude: 4.3525275),
        Seed(name: "Nyyó", address: "rue du Bailli 38 1050 Bruxelles  ", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/nyyo", latitude: 50.8263363, longitude: 4.3618275),
        Seed(name: "Nénu", address: "Rue Dejoncker 21, 1060 Saint-Gilles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/nenu", latitude: 50.834191, longitude: 4.3547978),
        Seed(name: "Nüetnigenough", address: "Rue du Lombard 25, 1000 Bruxelles, Belgique", cuisine: "Belge", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/nuetnigenough", latitude: 50.84582839999999, longitude: 4.3497857),
        Seed(name: "Osteria bolognese", address: "Rue de la Paix 49, 1050 Ixelles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/osteria-bolognese", latitude: 50.8363238, longitude: 4.3661517),
        Seed(name: "Panda", address: "Chaussée de Wavre 1543, 1160 Auderghem, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/panda", latitude: 50.8178001, longitude: 4.4180438),
        Seed(name: "Perruche", address: "Rue des Alliés 113, 1190 Forest, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/perruche", latitude: 50.8182395, longitude: 4.3271909),
        Seed(name: "Pho Diem Xuan", address: "Chaussée de Boondael 325, Ixelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/pho-diem-xuan", latitude: 50.8191462, longitude: 4.383095399999999),
        Seed(name: "Pinotte", address: "Rue Lesbroussart 22, 1050 Ixelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/pinotte", latitude: 50.8276338, longitude: 4.3702499),
        Seed(name: "Piola Pizza", address: "Place Saint-Josse 8, 1210 Saint-Josse-ten-Noode, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/piola-pizza", latitude: 50.84942789999999, longitude: 4.374104),
        Seed(name: "Pizza Vino", address: "Avenue des Saisons 15, 1050 Ixelles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/pizza-vino", latitude: 50.8200127, longitude: 4.3855738),
        Seed(name: "Pois Chiche", address: "Place de la Chapelle 15, 1000 Bruxelles, Belgique", cuisine: "Moyen-Orientale", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/pois-chiche", latitude: 50.8410191, longitude: 4.351293099999999),
        Seed(name: "Ptitbeur", address: "Rue Jean Robie 4, 1060 Saint-Gilles, Belgique", cuisine: "Africaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/ptitbeur", latitude: 50.8258834, longitude: 4.343618),
        Seed(name: "Pénar", address: "Place Georges Brugmann 18, 1050 Ixelles, Belgique", cuisine: "Bistronomie", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/penar", latitude: 50.8170423, longitude: 4.353468600000001),
        Seed(name: "Quartz", address: "Rue de la Réforme 22, 1050 Ixelles, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/quartz", latitude: 50.8204147, longitude: 4.356207299999999),
        Seed(name: "Racines", address: "Chaussée d'Ixelles 353, 1050 Ixelles, Belgique", cuisine: "Italienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/racines-bruxelles", latitude: 50.8281228, longitude: 4.3709326),
        Seed(name: "Rambo", address: "Pl. Albert Leemans 10, 1050 Ixelles, Bruxelles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/rambo", latitude: 50.82250149999999, longitude: 4.362980299999999),
        Seed(name: "Ramen Nobu", address: "Rue de l'Eglise 96a, 1150 Woluwe-Saint-Pierre, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/ramen-nobu", latitude: 50.84126850000001, longitude: 4.4641668),
        Seed(name: "Rascal's Café", address: "Rue de Savoie 34, 1060 Saint-Gilles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/rascals-cafe", latitude: 50.8242705, longitude: 4.3467135),
        Seed(name: "Savage", address: "Rue de la Paix 22, 1050 Ixelles, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/savage", latitude: 50.83591, longitude: 4.3651616),
        Seed(name: "Seven", address: "Rue Edith Cavell 10, Uccle, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/seven", latitude: 50.81398669999999, longitude: 4.356467299999999),
        Seed(name: "Shokudô – Urban Fish Farm", address: "Chaussée de Tervueren 95, 1160 Auderghem, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/shokudo-urban-fish-farm", latitude: 50.8162163, longitude: 4.4341243),
        Seed(name: "Solti", address: "Chaussée de Waterloo 250, 1060 Saint-Gilles, Bruxelles, Belgique", cuisine: "Autre", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/solti", latitude: 50.8260505, longitude: 4.3469148),
        Seed(name: "St Kilda", address: "Avenue Coghen 44, 1180 Uccle, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/st-kilda-bruxelles", latitude: 50.8124967, longitude: 4.3407496),
        Seed(name: "Stella", address: "Chaussée de Charleroi 91A, 1060 Saint-Gilles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/stella-2", latitude: 50.830312, longitude: 4.355956),
        Seed(name: "Strofilia", address: "Rue du Marché aux Porcs 11-13, 1000 Bruxelles, Belgique", cuisine: "Méditerranéenne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/strofilia-2", latitude: 50.8530002, longitude: 4.3460193),
        Seed(name: "Super Fourchette", address: "Rue des Hirondelles 3, 1000 Bruxelles, Belgique", cuisine: "Américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/super-fourchette", latitude: 50.8522556, longitude: 4.3527269),
        Seed(name: "Tatar", address: "Rue de l'Aqueduc 155, 1050 Ixelles, Belgique", cuisine: "Cuisine d’auteur", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/tatar", latitude: 50.823499, longitude: 4.361475599999999),
        Seed(name: "Tokidoki", address: "Chaussée d'Alsemberg 128, 1060 Saint-Gilles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/tokidoki", latitude: 50.8229571, longitude: 4.342921),
        Seed(name: "Tortilleria Benelux", address: "Place de la Reine 8, Schaerbeek, Belgique", cuisine: "Latino-américaine", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/tortilleria-benelux", latitude: 50.8595276, longitude: 4.3692513),
        Seed(name: "Winok", address: "Avenue Louis Bertrand 48, 1030 Schaerbeek, Belgique", cuisine: "Végétarienne", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/cafe-winok", latitude: 50.8638805, longitude: 4.376136199999999),
        Seed(name: "Yi Chan", address: "Rue Jules Van Praet 13, 1000 Bruxelles, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/yi-chan", latitude: 50.84834499999999, longitude: 4.348601599999999),
        Seed(name: "Yoka Tomo", address: "Avenue Félix Marchal 26, 1030 Schaerbeek, Belgique", cuisine: "Asiatique", comment: "Sélection Le Fooding Bruxelles — à découvrir.", foodingURL: "https://lefooding.com/restaurants/yoka-tomo", latitude: 50.8522626, longitude: 4.3897966),
    ]

    private static var italianRestaurants: [Seed] {
        guard let url = Bundle.main.url(
            forResource: "Restaurants_Toscane_Complet",
            withExtension: "json"
        ),
        let data = try? Data(contentsOf: url),
        let document = try? JSONDecoder().decode(ItalianRestaurantDocument.self, from: data) else {
            return []
        }

        return document.restaurants.map { restaurant in
            Seed(
                name: restaurant.nom,
                address: restaurant.adresse,
                cuisine: restaurant.cuisine ?? "Italienne",
                comment: restaurant.commentaire ?? "",
                website: restaurant.siteWeb ?? "",
                foodingURL: restaurant.lienFooding ?? "",
                phone: restaurant.telephone ?? "",
                rating: min(max(restaurant.note ?? 0, 0), 5),
                status: restaurant.statut == "À tester" ? "À tester" : "Aucun",
                isFavorite: restaurant.statut == "Favori",
                latitude: restaurant.localisation?.latitude,
                longitude: restaurant.localisation?.longitude
            )
        }
    }

    private static var restaurants: [Seed] {
        curatedRestaurants + foodingBrusselsRestaurants + italianRestaurants
    }

    static func insertIfNeeded(in modelContext: ModelContext) async {
        let existingRestaurants = (try? modelContext.fetch(FetchDescriptor<Restaurant>())) ?? []
        normalizeAsianCuisine(in: existingRestaurants)
        updateWebsites(in: existingRestaurants)
        updateFoodingLinks(in: existingRestaurants)
        updateKnownPhones(in: existingRestaurants)
        migrateIndependentTracking(in: existingRestaurants)
        normalizeKnownLocations(in: existingRestaurants)
        updateGenericItalianComments(in: existingRestaurants)

        let cloudSeedKey = "\(seedKey).iCloud"
        let cloudDefaults = NSUbiquitousKeyValueStore.default
        cloudDefaults.synchronize()

        if UserDefaults.standard.bool(forKey: seedKey) {
            cloudDefaults.set(true, forKey: cloudSeedKey)
            cloudDefaults.synchronize()
            try? modelContext.save()
            return
        }

        guard !cloudDefaults.bool(forKey: cloudSeedKey) else {
            UserDefaults.standard.set(true, forKey: seedKey)
            try? modelContext.save()
            return
        }

        UserDefaults.standard.set(true, forKey: seedKey)
        cloudDefaults.set(true, forKey: cloudSeedKey)
        cloudDefaults.synchronize()

        var existingNames = Set(existingRestaurants.map { normalized($0.name) })
        var existingAddresses = Set(existingRestaurants.map { normalized($0.address) })

        for seed in restaurants {
            let normalizedName = normalized(seed.name)
            let normalizedAddress = normalized(seed.address)
            guard !existingNames.contains(normalizedName),
                  !existingAddresses.contains(normalizedAddress) else { continue }

            let restaurant = Restaurant(
                name: seed.name,
                address: seed.address,
                city: seed.foodingURL.isEmpty
                    ? RestaurantCityResolver.city(from: seed.address)
                    : "Bruxelles",
                country: seed.foodingURL.isEmpty
                    ? RestaurantCityResolver.country(from: seed.address)
                    : "Belgique",
                rating: seed.rating,
                cuisine: seed.cuisine,
                comment: seed.comment,
                website: seed.website,
                foodingURL: seed.foodingURL,
                phone: seed.phone,
                status: seed.status,
                isFavorite: seed.isFavorite
            )
            modelContext.insert(restaurant)
            existingNames.insert(normalizedName)
            existingAddresses.insert(normalizedAddress)

            if let latitude = seed.latitude, let longitude = seed.longitude {
                restaurant.latitude = latitude
                restaurant.longitude = longitude
            } else if let coordinate = await coordinates(for: seed.address) {
                restaurant.latitude = coordinate.latitude
                restaurant.longitude = coordinate.longitude
            }
        }

        let allRestaurants = (try? modelContext.fetch(FetchDescriptor<Restaurant>())) ?? []
        updateFoodingLinks(in: allRestaurants)
        let curatedNames = Set(curatedRestaurants.map { normalized($0.name) })
        await findMissingPhones(in: allRestaurants.filter { curatedNames.contains(normalized($0.name)) })

        try? modelContext.save()
    }

    private static func normalizeKnownLocations(in restaurants: [Restaurant]) {
        for restaurant in restaurants {
            if foodingBrusselsRestaurants.contains(where: {
                normalized($0.name) == normalized(restaurant.name)
                    || normalized($0.address) == normalized(restaurant.address)
            }) {
                restaurant.city = "Bruxelles"
                restaurant.country = "Belgique"
            } else if let italianSeed = italianRestaurants.first(where: {
                normalized($0.address) == normalized(restaurant.address)
                    || normalized($0.name) == normalized(restaurant.name)
            }) {
                restaurant.city = RestaurantCityResolver.city(from: italianSeed.address)
                restaurant.country = "Italie"
            } else {
                if restaurant.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    restaurant.city = RestaurantCityResolver.city(from: restaurant.address)
                } else {
                    restaurant.city = RestaurantCityResolver.canonicalCity(restaurant.city)
                }
                if restaurant.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    restaurant.country = RestaurantCityResolver.country(from: restaurant.address)
                } else {
                    restaurant.country = RestaurantCityResolver.canonicalCountry(restaurant.country)
                }
            }
        }
    }

    private static func coordinates(for address: String) async -> CLLocationCoordinate2D? {
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

    private static func updateKnownPhones(in existingRestaurants: [Restaurant]) {
        let phones = Dictionary(uniqueKeysWithValues: curatedRestaurants.compactMap { seed in
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
        let websites = Dictionary(uniqueKeysWithValues: curatedRestaurants.compactMap { seed in
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

    private static func updateFoodingLinks(in existingRestaurants: [Restaurant]) {
        for seed in foodingBrusselsRestaurants where !seed.foodingURL.isEmpty {
            guard let restaurant = existingRestaurants.first(where: {
                normalized($0.name) == normalized(seed.name)
                    || normalized($0.address) == normalized(seed.address)
            }) else { continue }

            restaurant.foodingURL = seed.foodingURL
            if restaurant.website == seed.foodingURL {
                restaurant.website = ""
            }
        }
    }

    private static func migrateIndependentTracking(in restaurants: [Restaurant]) {
        let migrationKey = "didMigrateIndependentTrackingV1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        for restaurant in restaurants {
            if restaurant.status == "Favori" {
                restaurant.isFavorite = true
                restaurant.status = "Aucun"
            } else if !restaurant.foodingURL.isEmpty, restaurant.status == "À tester" {
                restaurant.status = "Aucun"
            }
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    private static func updateGenericItalianComments(in existingRestaurants: [Restaurant]) {
        let enrichedComments = Dictionary(
            italianRestaurants.map { seed in
                ("\(normalized(seed.name))|\(normalized(seed.address))", seed.comment)
            },
            uniquingKeysWith: { first, _ in first }
        )

        for restaurant in existingRestaurants where isReplaceableItalianSeedComment(restaurant.comment) {
            let key = "\(normalized(restaurant.name))|\(normalized(restaurant.address))"
            guard let enrichedComment = enrichedComments[key],
                  !isReplaceableItalianSeedComment(enrichedComment),
                  !enrichedComment.isEmpty else { continue }
            restaurant.comment = enrichedComment
        }
    }

    private static func isReplaceableItalianSeedComment(_ comment: String) -> Bool {
        let normalizedComment = normalized(comment)
        return normalizedComment.hasPrefix("restaurant italien;")
            || normalizedComment.hasPrefix("pizzeria;")
            || normalizedComment.hasPrefix("grill et restaurant;")
    }

    private static func normalizeAsianCuisine(in restaurants: [Restaurant]) {
        let asianRestaurantNames = ["little apo", "old boy", "thai café", "gourmets everyday"]
        for restaurant in restaurants where asianRestaurantNames.contains(restaurant.name.lowercased()) {
            restaurant.cuisine = "Asiatique"
        }
        restaurants.first { $0.name.caseInsensitiveCompare("Gelateria Giotto") == .orderedSame }?.cuisine = "Glacier"
    }

    private static func normalized(_ value: String) -> String {
        value.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
