import SwiftUI
import SwiftData
import MapKit

private enum RestaurantViewMode: String, CaseIterable {
    case list = "Liste"
    case map = "Carte"
}

private enum RestaurantSortOption: String, CaseIterable {
    case name = "Nom"
    case distance = "Distance"
    case rating = "Note"

    var systemImage: String {
        switch self {
        case .name: "textformat.abc"
        case .distance: "location"
        case .rating: "star"
        }
    }
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
    @State private var selectedCountries: Set<String> = []
    @State private var selectedCities: Set<String> = []
    @State private var selectedGuides: Set<String> = []
    @State private var selectedTracking: Set<String> = []
    @State private var selectedCuisines: Set<String> = []
    @State private var showingFilters = false
    @State private var showingAddRestaurant = false
    @State private var importRequest: RestaurantImportRequest?
    @State private var fileImportError: String?
    @State private var viewMode: RestaurantViewMode = .list
    @State private var sortOption: RestaurantSortOption = .name
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
        Set(restaurants.map(\.cuisine).filter { !$0.isEmpty }).sorted()
    }

    private var cities: [String] {
        guard !selectedCountries.isEmpty else { return [] }
        return Set(restaurants.filter { selectedCountries.contains($0.country) }
            .map(\.city).filter { !$0.isEmpty }).sorted()
    }

    private var countries: [String] {
        Set(restaurants.map(\.country).filter { !$0.isEmpty }).sorted()
    }

    private var activeFilterCount: Int {
        selectedCountries.count + selectedCities.count + selectedGuides.count
            + selectedTracking.count + selectedCuisines.count
    }

    private var filteredRestaurants: [Restaurant] {
        let matchingRestaurants = restaurants.filter { restaurant in
            let matchesCountry = selectedCountries.isEmpty || selectedCountries.contains(restaurant.country)
            let matchesCity = selectedCities.isEmpty || selectedCities.contains(restaurant.city)
            let matchesCuisine = selectedCuisines.isEmpty || selectedCuisines.contains(restaurant.cuisine)
            let matchesGuide = selectedGuides.isEmpty
                || (selectedGuides.contains("Le Fooding") && !restaurant.foodingURL.isEmpty)
            let matchesTracking = selectedTracking.isEmpty
                || (selectedTracking.contains("À tester") && restaurant.status == "À tester")
                || (selectedTracking.contains("Favoris") && restaurant.isFavorite)
                || (selectedTracking.contains("Sans suivi")
                    && restaurant.status != "À tester" && !restaurant.isFavorite)
            let matchesSearch = searchText.isEmpty
                || containsSearchText(restaurant.name)
                || containsSearchText(restaurant.address)
                || containsSearchText(restaurant.city)
                || containsSearchText(restaurant.country)
                || containsSearchText(restaurant.cuisine)
                || containsSearchText(restaurant.comment)
            return matchesCountry && matchesCity && matchesCuisine && matchesGuide
                && matchesTracking && matchesSearch
        }

        return matchingRestaurants.sorted { first, second in
            switch sortOption {
            case .name:
                return compareNames(first, second)
            case .distance:
                let firstDistance = distance(to: first)
                let secondDistance = distance(to: second)
                switch (firstDistance, secondDistance) {
                case let (first?, second?) where first != second:
                    return first < second
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return compareNames(first, second)
                }
            case .rating:
                if first.rating != second.rating {
                    return first.rating > second.rating
                }
                return compareNames(first, second)
            }
        }
    }

    private func compareNames(_ first: Restaurant, _ second: Restaurant) -> Bool {
        first.name.localizedStandardCompare(second.name) == .orderedAscending
    }

    private func distance(to restaurant: Restaurant) -> CLLocationDistance? {
        guard let userLocation = locationManager.location,
              let latitude = restaurant.latitude,
              let longitude = restaurant.longitude else { return nil }
        return userLocation.distance(from: CLLocation(latitude: latitude, longitude: longitude))
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

                        filterBar

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
                        ForEach(RestaurantSortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                Label(option.rawValue, systemImage: option.systemImage)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortOption.rawValue)
                                .font(.caption)
                        }
                    }
                    .accessibilityLabel("Tri actuel : \(sortOption.rawValue)")
                    .accessibilityHint("Modifie l’ordre des restaurants")
                }

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
            .sheet(isPresented: $showingFilters) {
                RestaurantFiltersView(
                    countries: countries,
                    cities: cities,
                    cuisines: cuisines,
                    selectedCountries: $selectedCountries,
                    selectedCities: $selectedCities,
                    selectedGuides: $selectedGuides,
                    selectedTracking: $selectedTracking,
                    selectedCuisines: $selectedCuisines
                )
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
                locationManager.requestLocation()
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

            ForEach(filteredRestaurants) { restaurant in
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
            Section("\(filteredRestaurants.count) adresse\(filteredRestaurants.count > 1 ? "s" : "")") {
                ForEach(filteredRestaurants) { restaurant in
                    NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                    } label: {
                        RestaurantRow(
                            restaurant: restaurant,
                            userLocation: locationManager.location
                        )
                    }
                }
                .onDelete(perform: deleteRestaurants)
            }
        }
        .overlay {
            if filteredRestaurants.isEmpty {
                ContentUnavailableView(
                    "Aucun restaurant",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Modifiez la recherche ou les filtres sélectionnés.")
                )
            }
        }
    }

    private var filterBar: some View {
        HStack {
            Button {
                showingFilters = true
            } label: {
                Label(
                    activeFilterCount == 0 ? "Filtres" : "Filtres (\(activeFilterCount))",
                    systemImage: "line.3.horizontal.decrease"
                )
            }
            .buttonStyle(.bordered)
            .tint(activeFilterCount == 0 ? .secondary : .orange)

            Spacer()

            if activeFilterCount > 0 {
                Text("\(filteredRestaurants.count) résultat\(filteredRestaurants.count > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Effacer") {
                    clearFilters()
                }
                .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func clearFilters() {
        selectedCities.removeAll()
        selectedCountries.removeAll()
        selectedGuides.removeAll()
        selectedTracking.removeAll()
        selectedCuisines.removeAll()
    }

    private func deleteRestaurants(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredRestaurants[index])
        }
    }
}

private struct RestaurantFiltersView: View {
    @Environment(\.dismiss) private var dismiss

    let countries: [String]
    let cities: [String]
    let cuisines: [String]
    @Binding var selectedCountries: Set<String>
    @Binding var selectedCities: Set<String>
    @Binding var selectedGuides: Set<String>
    @Binding var selectedTracking: Set<String>
    @Binding var selectedCuisines: Set<String>

    private var activeFilterCount: Int {
        selectedCountries.count + selectedCities.count + selectedGuides.count
            + selectedTracking.count + selectedCuisines.count
    }

    var body: some View {
        NavigationStack {
            List {
                FilterSection(
                    title: "Pays",
                    options: countries,
                    selection: $selectedCountries
                )

                if selectedCountries.isEmpty {
                    Section("Ville") {
                        Label("Choisissez d’abord un pays", systemImage: "globe.europe.africa")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    FilterSection(
                        title: "Ville",
                        options: cities,
                        selection: $selectedCities
                    )
                }

                FilterSection(
                    title: "Guide",
                    options: ["Le Fooding"],
                    selection: $selectedGuides
                )

                FilterSection(
                    title: "Suivi",
                    options: ["À tester", "Favoris", "Sans suivi"],
                    selection: $selectedTracking
                )

                FilterSection(
                    title: "Type de cuisine",
                    options: cuisines,
                    selection: $selectedCuisines
                )
            }
            .navigationTitle("Filtrer les restaurants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if activeFilterCount > 0 {
                        Button("Tout effacer", role: .destructive) {
                            selectedCountries.removeAll()
                            selectedCities.removeAll()
                            selectedGuides.removeAll()
                            selectedTracking.removeAll()
                            selectedCuisines.removeAll()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("Les choix d’une même rubrique s’additionnent. Les cinq rubriques se combinent entre elles.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
            .onChange(of: selectedCountries) { _, _ in
                selectedCities = selectedCities.intersection(Set(cities))
            }
        }
    }
}

private struct FilterSection: View {
    let title: String
    let options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        Section {
            ForEach(options, id: \.self) { option in
                Button {
                    if selection.contains(option) {
                        selection.remove(option)
                    } else {
                        selection.insert(option)
                    }
                } label: {
                    HStack {
                        Text(option)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection.contains(option) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            HStack {
                Text(title)
                Spacer()
                if !selection.isEmpty {
                    Text("\(selection.count) sélectionné\(selection.count > 1 ? "s" : "")")
                        .textCase(nil)
                }
            }
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
    let userLocation: CLLocation?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 8) {
                    if restaurant.status == "À tester" {
                        Image(systemName: "bookmark")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("À tester")
                    }

                    if restaurant.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                            .accessibilityLabel("Favori")
                    }

                    if restaurant.rating == 0 {
                        Text("Non noté")
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                            Text(ratingText)
                        }
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                    }

                    if !restaurant.foodingURL.isEmpty {
                        Text("Fooding")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Color(red: 0, green: 0.62, blue: 0.78),
                                in: Capsule()
                            )
                            .accessibilityLabel("Référencé par Le Fooding")
                    }

                    if let distanceText {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                            Text(distanceText)
                        }
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityLabel("À \(distanceText)")
                    }
                }
                .font(.system(size: 12))
                .frame(height: 18, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        }
        .frame(minHeight: 46)
        .padding(.vertical, 2)
    }

    private var ratingText: String {
        return "\(restaurant.rating.formatted(.number.precision(.fractionLength(1)))) / 5"
    }

    private var distanceText: String? {
        guard let userLocation,
              let latitude = restaurant.latitude,
              let longitude = restaurant.longitude else { return nil }

        let restaurantLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distance = userLocation.distance(from: restaurantLocation)
        guard distance.isFinite, distance >= 0 else { return nil }

        if distance < 1_000 {
            let roundedMeters = (distance / 10).rounded() * 10
            return "\(Int(roundedMeters)) m"
        }

        let kilometers = distance / 1_000
        return kilometers.formatted(.number.precision(.fractionLength(kilometers < 10 ? 1 : 0))) + " km"
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
