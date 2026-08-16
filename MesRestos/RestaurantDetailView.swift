import SwiftUI
import MapKit
import UIKit

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @State private var showingEditRestaurant = false
    @State private var showingNavigationOptions = false

    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude = restaurant.latitude, let longitude = restaurant.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func mapPosition(for coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let coordinate {
                    Map(initialPosition: mapPosition(for: coordinate)) {
                        Marker(restaurant.name, coordinate: coordinate)
                            .tint(.orange)
                    }
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    ContentUnavailableView {
                        Label("Carte indisponible", systemImage: "map")
                    } description: {
                        Text("La localisation n’a pas pu être trouvée à partir de cette adresse.")
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(restaurant.name)
                            .font(.largeTitle.bold())
                        Spacer()
                        if restaurant.rating == 0 {
                            Text("À noter")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                        } else {
                            Label("\(restaurant.rating, specifier: "%.1f")", systemImage: "star.fill")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }
                    }

                    Label(restaurant.cuisine, systemImage: "fork.knife")
                    if coordinate != nil {
                        Button {
                            showingNavigationOptions = true
                        } label: {
                            HStack {
                                Label(restaurant.address, systemImage: "mappin.and.ellipse")
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Label(restaurant.address, systemImage: "mappin.and.ellipse")
                    }
                    Label(
                        restaurant.status,
                        systemImage: restaurant.status == "Favori" ? "heart.fill" : "bookmark"
                    )
                    .foregroundStyle(restaurant.status == "Favori" ? .pink : .secondary)

                    if let websiteURL = URL(string: restaurant.website), !restaurant.website.isEmpty {
                        Link(destination: websiteURL) {
                            Label("Visiter le site web", systemImage: "safari")
                        }
                    }

                    if let foodingURL = URL(string: restaurant.foodingURL), !restaurant.foodingURL.isEmpty {
                        Link(destination: foodingURL) {
                            Label("Voir la fiche sur Le Fooding", systemImage: "fork.knife.circle")
                        }
                        .tint(.indigo)
                    }

                    if let phoneURL = phoneURL {
                        Link(destination: phoneURL) {
                            Label(restaurant.phone, systemImage: "phone.fill")
                        }
                    }

                    if !restaurant.comment.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Remarque", systemImage: "text.bubble")
                                .font(.headline)
                            Text(restaurant.comment)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    }

                    if coordinate != nil {
                        Button {
                            showingNavigationOptions = true
                        } label: {
                            Label("Itinéraire", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.large)
                        .padding(.top, 6)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Modifier") { showingEditRestaurant = true }
        }
        .sheet(isPresented: $showingEditRestaurant) {
            RestaurantFormView(restaurant: restaurant)
        }
        .confirmationDialog(
            "Choisir une application d’itinéraire",
            isPresented: $showingNavigationOptions,
            titleVisibility: .visible
        ) {
            Button("Plans") { openInAppleMaps() }
            Button("Google Maps") { openInGoogleMaps() }
            Button("Waze") { openInWaze() }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text(restaurant.name)
        }
    }

    private func openInAppleMaps() {
        guard let coordinate else { return }
        let item: MKMapItem
        if #available(iOS 26.0, *) {
            item = MKMapItem(
                location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                address: nil
            )
        } else {
            item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        }
        item.name = restaurant.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func openInGoogleMaps() {
        guard let coordinate else { return }
        let destination = "\(coordinate.latitude),\(coordinate.longitude)"
        guard let appURL = URL(string: "comgooglemaps://?daddr=\(destination)&directionsmode=driving"),
              let webURL = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(destination)&travelmode=driving") else { return }
        open(appURL, fallback: webURL)
    }

    private func openInWaze() {
        guard let coordinate else { return }
        let destination = "\(coordinate.latitude),\(coordinate.longitude)"
        guard let appURL = URL(string: "waze://?ll=\(destination)&navigate=yes"),
              let webURL = URL(string: "https://waze.com/ul?ll=\(destination)&navigate=yes") else { return }
        open(appURL, fallback: webURL)
    }

    private func open(_ appURL: URL, fallback webURL: URL) {
        UIApplication.shared.open(appURL, options: [:]) { opened in
            if !opened {
                UIApplication.shared.open(webURL)
            }
        }
    }

    private var phoneURL: URL? {
        let allowed = restaurant.phone.filter { $0.isNumber || $0 == "+" }
        guard !allowed.isEmpty else { return nil }
        return URL(string: "tel:\(allowed)")
    }
}
