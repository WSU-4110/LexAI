//
//  LocationManager.swift
//  LexAI_iOS
//Sara

import Combine
import CoreLocation
import MapKit

// Uses a single CLGeocoder instance to avoid deprecation warnings
// and improve performance.
// turns coordinates into words the chat can actually use (S)
final class LocationManager: NSObject, ObservableObject {
    @Published var locationString: String = ""
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        applyAuthorizationState()
    }

    private func applyAuthorizationState() {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        // Use MapKit reverse geocoding to avoid deprecated CLGeocoder
        let coordinate = location.coordinate

        // Create a reverse geocode request using MKLocalSearch
        let request = MKLocalSearch.Request()
        request.pointOfInterestFilter = nil
        request.naturalLanguageQuery = nil
        // Set a very small region around the coordinate to bias the search
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        request.region = MKCoordinateRegion(center: coordinate, span: span)

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self else { return }

            // If error occurred or no map items, clear the string
            guard error == nil, let item = response?.mapItems.first else {
                DispatchQueue.main.async {
                    self.locationString = ""
                }
                return
            }

            // Prefer new iOS 26 APIs: address, addressRepresentations, and location
            var derivedCity: String = ""
            var derivedCountry: String = ""

            if let addr = item.address {
                // MKAddress exposes string summaries, not separate city/country fields
                let short = addr.shortAddress ?? ""
                let full = addr.fullAddress
                let summary = short.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? full : short
                let parts = summary.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 2 {
                    derivedCity = parts[0]
                    derivedCountry = parts[parts.count - 1]
                } else if let first = parts.first, !first.isEmpty {
                    derivedCity = first
                }
            }

            func finish(with city: String, country: String) {
                let str: String
                if !city.isEmpty, !country.isEmpty {
                    str = "\(city), \(country)"
                } else if !city.isEmpty {
                    str = city
                } else if !country.isEmpty {
                    str = country
                } else {
                    str = ""
                }
                DispatchQueue.main.async {
                    self.locationString = str
                }
            }

            if !derivedCity.isEmpty || !derivedCountry.isEmpty {
                finish(with: derivedCity, country: derivedCountry)
            } else {
                let loc = item.location
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(loc) { placemarks, _ in
                    let p = placemarks?.first
                    let city = p?.locality
                        ?? p?.subAdministrativeArea
                        ?? p?.administrativeArea
                        ?? ""
                    let country = p?.isoCountryCode ?? p?.country ?? ""
                    finish(with: city, country: country)
                }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.applyAuthorizationState()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // no fix yet; GPS is still thinking (S)
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
        }
        reverseGeocode(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _ = error
    }
}
