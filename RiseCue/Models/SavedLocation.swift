import Foundation
import CoreLocation

/// When to wake relative to sunrise
enum AlarmTiming: String, Codable, CaseIterable, Identifiable {
    case nauticalDawn = "Nautical Dawn"
    case civilDawn = "Civil Dawn"
    case sunrise = "Sunrise"
    case afterSunrise = "After Sunrise"

    var id: String { rawValue }

    /// User-friendly description
    var description: String {
        switch self {
        case .nauticalDawn:
            return "Sky begins to lighten"
        case .civilDawn:
            return "Soft pre-sunrise glow"
        case .sunrise:
            return "Sun crosses the horizon"
        case .afterSunrise:
            return "10 minutes after sunrise"
        }
    }

    /// SF Symbol icon for this timing
    var icon: String {
        switch self {
        case .nauticalDawn:
            return "sparkles"
        case .civilDawn:
            return "sun.haze"
        case .sunrise:
            return "sunrise"
        case .afterSunrise:
            return "sunrise.fill"
        }
    }

    /// Approximate minutes before actual sunrise (for display)
    var approximateMinutesBefore: Int {
        switch self {
        case .nauticalDawn: return 60  // ~1 hour before
        case .civilDawn: return 30     // ~30 min before
        case .sunrise: return 0
        case .afterSunrise: return -10 // 10 min after
        }
    }
}

struct SavedLocation: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var isSelected: Bool

    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isSelected = isSelected
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

class LocationStore: ObservableObject {
    @Published var savedLocations: [SavedLocation] = []
    @Published var alarmTiming: AlarmTiming = .sunrise
    @Published var alarmRepeats: Bool = true  // Whether alarm auto-schedules for next day

    private let locationsKey = "SavedLocations"
    private let timingKey = "AlarmTiming"
    private let repeatsKey = "AlarmRepeats"

    init() {
        loadLocations()
        loadAlarmTiming()
        loadAlarmRepeats()
    }

    var selectedLocation: SavedLocation? {
        savedLocations.first(where: { $0.isSelected })
    }

    func addLocation(_ location: SavedLocation) {
        savedLocations.append(location)
        saveLocations()
    }

    func deleteLocation(at offsets: IndexSet) {
        savedLocations.remove(atOffsets: offsets)
        saveLocations()
    }

    func deleteLocation(_ location: SavedLocation) {
        savedLocations.removeAll(where: { $0.id == location.id })
        saveLocations()
    }

    func selectLocation(_ location: SavedLocation) {
        for index in savedLocations.indices {
            savedLocations[index].isSelected = (savedLocations[index].id == location.id)
        }
        saveLocations()
    }

    func updateAlarmTiming(_ timing: AlarmTiming) {
        alarmTiming = timing
        UserDefaults.standard.set(timing.rawValue, forKey: timingKey)
    }

    func updateAlarmRepeats(_ repeats: Bool) {
        alarmRepeats = repeats
        UserDefaults.standard.set(repeats, forKey: repeatsKey)
    }

    private func saveLocations() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: locationsKey)
        }
    }

    private func loadLocations() {
        if let data = UserDefaults.standard.data(forKey: locationsKey),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            savedLocations = decoded
        }
    }

    private func loadAlarmTiming() {
        if let timingString = UserDefaults.standard.string(forKey: timingKey) {
            // Handle migration from old values
            if timingString == "Before Sunrise" {
                alarmTiming = .civilDawn
                UserDefaults.standard.set(AlarmTiming.civilDawn.rawValue, forKey: timingKey)
            } else if timingString == "After Sunrise" {
                alarmTiming = .afterSunrise
            } else if let timing = AlarmTiming(rawValue: timingString) {
                alarmTiming = timing
            }
        }
    }

    private func loadAlarmRepeats() {
        // Default to true if not set
        if UserDefaults.standard.object(forKey: repeatsKey) != nil {
            alarmRepeats = UserDefaults.standard.bool(forKey: repeatsKey)
        } else {
            alarmRepeats = true
        }
    }
}
