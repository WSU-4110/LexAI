//
//  LocationManager.swift
//  LexAI_iOS
//

import Combine
import CoreLocation

// Uses a single CLGeocoder instance to avoid deprecation warnings
// and improve performance.
final class LocationManager: NSObject, ObservableObject {
    @Published var locationString: String = ""
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

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
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let str: String
            if let placemark = placemarks?.first {
                let city = placemark.locality
                    ?? placemark.subAdministrativeArea
                    ?? placemark.administrativeArea
                    ?? ""
                let country = placemark.isoCountryCode ?? ""
                if !city.isEmpty, !country.isEmpty {
                    str = "\(city), \(country)"
                } else if !city.isEmpty {
                    str = city
                } else if !country.isEmpty {
                    str = country
                } else {
                    str = ""
                }
            } else {
                str = ""
            }
            DispatchQueue.main.async {
                self.locationString = str
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
