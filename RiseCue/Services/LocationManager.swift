import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private var locationCompletion: ((Result<CLLocationCoordinate2D, Error>) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation(completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        self.locationCompletion = completion

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            completion(.failure(NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location permission denied"])))
        @unknown default:
            completion(.failure(NSError(domain: "LocationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status"])))
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.location = location.coordinate
            self.locationCompletion?(.success(location.coordinate))
            self.locationCompletion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationCompletion?(.failure(error))
            self.locationCompletion = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                if self.locationCompletion != nil {
                    manager.requestLocation()
                }
            }
        }
    }
}
