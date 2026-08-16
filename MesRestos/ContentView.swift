import SwiftUI
import SwiftData
import MapKit

private enum RestaurantViewMode: String, CaseIterable {
    case list = "Liste"
    case map = "Carte"
}

private struct RestaurantImportRequest: Identifiable {
    let id = UUID()
    let jsonText: String
    let sourceName: String?
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Restaurant.name) private var restaurants: [Restaurant]

    @State private var searchText = ""
    @State private var selectedCuisine = "Toutes"
    @State private var showingAddRestaurant = false
    @State private var importRequest: RestaurantImportRequest?
    @State private var fileImportError: String?
    @State private var viewMode: RestaurantViewMode = .list
    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
    ))
    @State private var visibleMapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
    )
    @State private var hasCenteredOnUser = false
    @StateObject private var locationManager = LocationManager()

    private var cuisines: [String] {
        ["Toutes"] + Set(restaurants.map(\.cuisine)).sorted()
    }

    private var filteredRestaurants: [Restaurant] {
        restaurants.filter { restaurant in
            let matchesCuisine = selectedCuisine == "Toutes" || restaurant.cuisine == selectedCuisine
            let matchesSearch = searchText.isEmpty
                || containsSearchText(restaurant.name)
                || containsSearchText(restaurant.address)
                || containsSearchText(restaurant.cuisine)
                || containsSearchText(restaurant.comment)
            return matchesCuisine && matchesSearch
        }
    }

    private func containsSearchText(_ value: String) -> Bool {
        value.range(
            of: searchText,
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        ) != nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if restaurants.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun restaurant", systemImage: "fork.knife.circle")
                    } description: {
                        Text("Ajoutez les adresses que vous avez envie de découvrir.")
                    } actions: {
                        Button("Ajouter un restaurant") {
                            showingAddRestaurant = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 0) {
                        Picker("Affichage", selection: $viewMode) {
                            ForEach(RestaurantViewMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode == .list ? "list.bullet" : "map")
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        if viewMode == .list {
                            restaurantList
                        } else {
                            restaurantMap
                        }
                    }
                }
            }
            .navigationTitle("Mes restaurants")
            .searchable(text: $searchText, prompt: "Nom, adresse ou cuisine")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddRestaurant = true
                        } label: {
                            Label("Ajouter manuellement", systemImage: "square.and.pencil")
                        }

                        Button {
                            importRequest = RestaurantImportRequest(jsonText: "", sourceName: nil)
                        } label: {
                            Label("Importer une sélection", systemImage: "doc.badge.plus")
                        }
                    } label: {
                        Label("Ajouter", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRestaurant) {
                RestaurantFormView()
            }
            .sheet(item: $importRequest) { request in
                RestaurantJSONImportView(
                    initialJSON: request.jsonText,
                    sourceName: request.sourceName
                )
            }
            .onOpenURL(perform: openRestaurantDocument)
            .alert("Fichier impossible à ouvrir", isPresented: Binding(
                get: { fileImportError != nil },
                set: { if !$0 { fileImportError = nil } }
            )) {
                Button("OK", role: .cancel) { fileImportError = nil }
            } message: {
                Text(fileImportError ?? "Erreur inconnue")
            }
            .task {
                await DefaultRestaurants.insertIfNeeded(in: modelContext)
            }
            .onChange(of: viewMode) { _, mode in
                if mode == .map {
                    locationManager.requestLocation()
                    focusMapOnSearchResult()
                }
            }
            .onChange(of: searchText) { _, _ in
                guard viewMode == .map else { return }
                focusMapOnSearchResult()
            }
            .onChange(of: locationManager.location) { _, location in
                guard let location, !hasCenteredOnUser else { return }
                hasCenteredOnUser = true
                mapPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
                ))
            }
        }
    }

    private func openRestaurantDocument(_ url: URL) {
        guard url.isFileURL else {
            fileImportError = "Le lien reçu ne correspond pas à un fichier Mes Restos."
            return
        }

        let hasSecurityAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize, fileSize > 5_000_000 {
                throw RestaurantDocumentError.fileTooLarge
            }

            let data = try Data(contentsOf: url)
            guard let jsonText = String(data: data, encoding: .utf8) else {
                throw RestaurantDocumentError.invalidEncoding
            }

            _ = try RestaurantJSONImporter.parse(jsonText)
            importRequest = RestaurantImportRequest(
                jsonText: jsonText,
                sourceName: url.deletingPathExtension().lastPathComponent
            )
        } catch {
            fileImportError = (error as? LocalizedError)?.errorDescription
                ?? "Le contenu de ce fichier n’est pas compatible avec Mes Restos."
        }
    }

    private var restaurantMap: some View {
        Map(position: $mapPosition) {
            UserAnnotation()

            ForEach(restaurants) { restaurant in
                if let latitude = restaurant.latitude, let longitude = restaurant.longitude {
                    Annotation(
                        restaurant.name,
                        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    ) {
                        NavigationLink {
                            RestaurantDetailView(restaurant: restaurant)
                        } label: {
                            Image(systemName: "fork.knife")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(.indigo.gradient, in: Circle())
                                .overlay(Circle().stroke(.white, lineWidth: 3))
                                .shadow(radius: 3, y: 2)
                        }
                        .accessibilityLabel(restaurant.name)
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .continuous) { context in
            visibleMapRegion = context.region
        }
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: 8) {
                Button {
                    zoomMap(by: 0.5)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 30, height: 30)
                        .background(.regularMaterial, in: Circle())
                }
                Button {
                    zoomMap(by: 2)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 30, height: 30)
                        .background(.regularMaterial, in: Circle())
                }
            }
            .font(.caption.bold())
            .buttonStyle(.plain)
            .padding(.trailing, 12)
            .padding(.bottom, 70)
        }
        .overlay(alignment: .bottom) {
            if locationManager.authorizationStatus == .denied
                || locationManager.authorizationStatus == .restricted {
                Label("Localisation désactivée — les restaurants restent visibles", systemImage: "location.slash")
                    .font(.caption)
                    .padding(10)
                    .background(.regularMaterial, in: Capsule())
                    .padding()
            }
        }
    }

    private func zoomMap(by factor: Double) {
        let latitudeDelta = min(max(visibleMapRegion.span.latitudeDelta * factor, 0.002), 60)
        let longitudeDelta = min(max(visibleMapRegion.span.longitudeDelta * factor, 0.002), 60)
        let region = MKCoordinateRegion(
            center: visibleMapRegion.center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
        visibleMapRegion = region
        withAnimation {
            mapPosition = .region(region)
        }
    }

    private func focusMapOnSearchResult() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let restaurant = filteredRestaurants.first,
              let latitude = restaurant.latitude,
              let longitude = restaurant.longitude else { return }

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
        visibleMapRegion = region
        withAnimation {
            mapPosition = .region(region)
        }
    }

    private var restaurantList: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(cuisines, id: \.self) { cuisine in
                            Button(cuisine) { selectedCuisine = cuisine }
                                .buttonStyle(.bordered)
                                .tint(selectedCuisine == cuisine ? .orange : .secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
            }

            Section("\(filteredRestaurants.count) adresse\(filteredRestaurants.count > 1 ? "s" : "")") {
                ForEach(filteredRestaurants) { restaurant in
                    NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                    } label: {
                        RestaurantRow(restaurant: restaurant)
                    }
                }
                .onDelete(perform: deleteRestaurants)
            }
        }
        .overlay {
            if filteredRestaurants.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private func deleteRestaurants(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredRestaurants[index])
        }
    }
}

private enum RestaurantDocumentError: LocalizedError {
    case fileTooLarge
    case invalidEncoding

    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "Le fichier dépasse la taille maximale autorisée de 5 Mo."
        case .invalidEncoding:
            return "Le fichier doit contenir du texte JSON encodé en UTF-8."
        }
    }
}

private struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "fork.knife")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                Text(restaurant.cuisine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(restaurant.address, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if restaurant.status == "Favori" {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                    .accessibilityLabel("Favori")
            }

            if restaurant.rating == 0 {
                Text("À noter")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            } else {
                Label(restaurant.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
