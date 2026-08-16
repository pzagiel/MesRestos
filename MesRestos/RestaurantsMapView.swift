import SwiftUI
import SwiftData
import MapKit

struct RestaurantsMapView: View {
    @Query(sort: \Restaurant.name) private var restaurants: [Restaurant]

    let focusedRestaurant: Restaurant

    @State private var mapPosition: MapCameraPosition
    @State private var visibleMapRegion: MKCoordinateRegion

    init(focusedRestaurant: Restaurant) {
        self.focusedRestaurant = focusedRestaurant

        let center = CLLocationCoordinate2D(
            latitude: focusedRestaurant.latitude ?? 50.8503,
            longitude: focusedRestaurant.longitude ?? 4.3517
        )
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
        _mapPosition = State(initialValue: .region(region))
        _visibleMapRegion = State(initialValue: region)
    }

    var body: some View {
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
                                .overlay(
                                    Circle().stroke(
                                        restaurant.persistentModelID == focusedRestaurant.persistentModelID
                                            ? .orange
                                            : .white,
                                        lineWidth: 3
                                    )
                                )
                                .shadow(radius: 3, y: 2)
                        }
                        .accessibilityLabel(restaurant.name)
                    }
                }
            }
        }
        .navigationTitle(focusedRestaurant.name)
        .navigationBarTitleDisplayMode(.inline)
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
            .padding(12)
        }
    }

    private func zoomMap(by factor: Double) {
        let latitudeDelta = min(max(visibleMapRegion.span.latitudeDelta * factor, 0.002), 60)
        let longitudeDelta = min(max(visibleMapRegion.span.longitudeDelta * factor, 0.002), 60)
        let region = MKCoordinateRegion(
            center: visibleMapRegion.center,
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
        visibleMapRegion = region
        withAnimation {
            mapPosition = .region(region)
        }
    }
}
