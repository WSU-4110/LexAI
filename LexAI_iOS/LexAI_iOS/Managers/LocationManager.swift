//
//  LocationManager.swift
//  LexAI_iOS
//
//  Created by Sara Al-hachami 03/24/2026
//

import Foundation
import CoreLocation

// LocationManager handles all Core Location functionality for the app.
// It conforms to CLLocationManagerDelegate to receive location updates
// and authorization changes directly from the system.
// It is an ObservableObject so SwiftUI views can react to published changes.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    // The underlying CLLocationManager that communicates with iOS location services.
    private let manager = CLLocationManager()

    // The human-readable location string shown in the sidebar (e.g. "Detroit, MI").
    // Published so any observing view updates automatically when this changes.
    @Published var locationName: String = ""

    // Tracks the current authorization status so the sidebar can show
    // the correct UI state (enable button, location label, or unavailable message).
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        // Assign self as the delegate so this class receives all location callbacks.
        manager.delegate = self
        // Hundred meters is accurate enough for city-level display and saves battery.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // Read the current status immediately so the UI is correct on first render.
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public

    // Called when the user taps "Enable location for better advice" in the sidebar.
    // Triggers the iOS permission prompt if status is notDetermined,
    // or silently fetches location if permission was already granted.
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - CLLocationManagerDelegate

    // Called by iOS whenever the user changes location permissions.
    // Updates the published status and kicks off a location fetch if now authorized.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse ||
           authorizationStatus == .authorizedAlways {
            // Request a single one-time location fix.
            manager.requestLocation()
        }
    }

    // Called when iOS successfully retrieves coordinates.
    // Passes the result to CLGeocoder to convert lat/lng into a city and state string.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self,
                  let placemark = placemarks?.first,
                  error == nil else { return }

            let city  = placemark.locality ?? ""
            let state = placemark.administrativeArea ?? ""

            // CLGeocoder returns on a background thread, so dispatch back to main
            // before updating the published property to keep UI updates safe.
            DispatchQueue.main.async {
                self.locationName = [city, state]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
            }
        }
    }

    // Called if the location request fails (e.g. no signal, simulator with no location set).
    // Logs the error without crashing or showing anything disruptive to the user.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error: \(error.localizedDescription)")
    }
}