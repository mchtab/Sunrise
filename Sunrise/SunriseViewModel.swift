import Foundation
import SwiftUI
import CoreLocation
import Combine
import AlarmKit

@MainActor
class SunriseViewModel: ObservableObject {
    @Published var sunTimes: SunTimes?
    @Published var alarmTime: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var alarmEnabled = false
    @Published var currentLocationName: String?

    private let locationManager = LocationManager()
    private let sunriseService = SunriseService()
    private let alarmManager = AlarmKitManager()
    private var cancellables = Set<AnyCancellable>()

    var locationStore: LocationStore?

    /// Convenience accessor for sunrise time (backward compatibility)
    var sunriseTime: Date? { sunTimes?.sunrise }

    /// Convenience accessor for sunset time
    var sunsetTime: Date? { sunTimes?.sunset }

    init() {
        setupObservers()
        setupAlarmObserver()
    }

    private func setupObservers() {
        locationManager.$location
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                if let location = location {
                    self?.fetchSunTimesForDisplay(latitude: location.latitude, longitude: location.longitude)
                }
            }.store(in: &cancellables)
    }

    private func setupAlarmObserver() {
        // Observe alarm manager state changes
        alarmManager.$currentAlarm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alarm in
                self?.alarmEnabled = alarm != nil
            }.store(in: &cancellables)
    }

    func getCurrentLocation(completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        locationManager.requestLocation(completion: completion)
    }

    func updateSelectedLocation(_ location: SavedLocation) {
        currentLocationName = location.name
        fetchSunTimesForDisplay(latitude: location.latitude, longitude: location.longitude)
    }

    func requestPermissions() {
        locationManager.requestPermission()

        Task {
            let granted = await alarmManager.requestAuthorization()
            if granted {
                print("AlarmKit permission granted")
            }
        }
    }

    /// Check if AlarmKit is authorized
    var isAlarmAuthorized: Bool {
        alarmManager.isAuthorized
    }

    // MARK: - Fetch Sun Times for Display

    func refreshSunriseData() {
        guard let locationStore = locationStore, let selectedLocation = locationStore.selectedLocation else {
            return
        }
        fetchSunTimesForDisplay(latitude: selectedLocation.latitude, longitude: selectedLocation.longitude)
    }

    private func fetchSunTimesForDisplay(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil

        // Fetch tomorrow's sun times for display (next upcoming sunrise)
        sunriseService.fetchSunTimes(latitude: latitude, longitude: longitude) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let sunTimes):
                    self.sunTimes = sunTimes

                    // If alarm is enabled, update the alarm time based on current timing preference
                    if self.alarmEnabled, let locationStore = self.locationStore {
                        self.alarmTime = sunTimes.alarmTime(for: locationStore.alarmTiming)
                    }

                case .failure(let error):
                    self.errorMessage = "Failed to fetch sunrise time: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Fetch sun times for a specific date (used for rescheduling)
    private func fetchSunTimesForDate(_ date: Date, latitude: Double, longitude: Double) async throws -> SunTimes {
        return try await withCheckedThrowingContinuation { continuation in
            sunriseService.fetchSunTimes(latitude: latitude, longitude: longitude, for: date) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Alarm Management

    func setupAlarm() {
        guard let locationStore = locationStore, let selectedLocation = locationStore.selectedLocation else {
            errorMessage = "Please select a location first"
            return
        }

        guard let sunTimes = sunTimes else {
            // Need to fetch sun times first
            isLoading = true
            sunriseService.fetchSunTimes(latitude: selectedLocation.latitude, longitude: selectedLocation.longitude) { [weak self] result in
                guard let self = self else { return }

                Task { @MainActor in
                    switch result {
                    case .success(let sunTimes):
                        self.sunTimes = sunTimes
                        await self.scheduleAlarm(with: sunTimes)
                    case .failure(let error):
                        self.isLoading = false
                        self.errorMessage = "Failed to fetch sunrise time: \(error.localizedDescription)"
                    }
                }
            }
            return
        }

        Task {
            await scheduleAlarm(with: sunTimes)
        }
    }

    private func scheduleAlarm(with sunTimes: SunTimes) async {
        guard let locationStore = locationStore, let selectedLocation = locationStore.selectedLocation else {
            isLoading = false
            errorMessage = "Location store not initialized"
            return
        }

        let alarmDate = sunTimes.alarmTime(for: locationStore.alarmTiming)
        self.alarmTime = alarmDate

        let isBefore = locationStore.alarmTiming != .afterSunrise
        let locationName = selectedLocation.name

        do {
            let success = try await alarmManager.scheduleAlarm(
                at: alarmDate,
                isBefore: isBefore,
                locationName: locationName
            )

            isLoading = false
            if success {
                alarmEnabled = true
                errorMessage = nil
            } else {
                errorMessage = "Failed to schedule alarm"
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to schedule alarm: \(error.localizedDescription)"
        }
    }

    /// Reschedule alarm for the next day (called after alarm fires if repeating is enabled)
    func rescheduleForNextDay() async {
        guard let locationStore = locationStore,
              let selectedLocation = locationStore.selectedLocation,
              locationStore.alarmRepeats else {
            return
        }

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        do {
            let sunTimes = try await fetchSunTimesForDate(tomorrow, latitude: selectedLocation.latitude, longitude: selectedLocation.longitude)
            self.sunTimes = sunTimes
            await scheduleAlarm(with: sunTimes)
        } catch {
            errorMessage = "Failed to reschedule alarm: \(error.localizedDescription)"
        }
    }

    func cancelAlarm() {
        Task {
            await alarmManager.cancelAlarm()
            alarmEnabled = false
            alarmTime = nil
        }
    }

    // MARK: - Test Alarm

    /// Schedule a test alarm that fires in a few seconds (for testing)
    func scheduleTestAlarm(delaySeconds: TimeInterval = 10) {
        let testFireDate = Date().addingTimeInterval(delaySeconds)
        let locationName = locationStore?.selectedLocation?.name ?? "Test Location"

        Task {
            // First ensure we have authorization
            let authorized = await alarmManager.requestAuthorization()
            print("AlarmKit authorized: \(authorized)")

            guard authorized else {
                errorMessage = "AlarmKit not authorized. Please enable in Settings."
                print("AlarmKit authorization denied")
                return
            }

            do {
                print("Scheduling test alarm for: \(testFireDate)")
                let success = try await alarmManager.scheduleAlarm(
                    at: testFireDate,
                    isBefore: false,
                    locationName: locationName
                )

                if success {
                    alarmTime = testFireDate
                    alarmEnabled = true
                    errorMessage = nil
                    print("Test alarm scheduled successfully for \(testFireDate)")
                } else {
                    errorMessage = "Failed to schedule test alarm"
                    print("scheduleAlarm returned false")
                }
            } catch {
                errorMessage = "Test alarm error: \(error.localizedDescription)"
                print("Test alarm error: \(error)")
            }
        }
    }
}
