import Foundation
import AlarmKit
import SwiftUI

// MARK: - Helper Extensions

extension AlarmButton {
    static var stopButton: AlarmButton {
        AlarmButton(text: "Stop", textColor: .white, systemImageName: "xmark.circle.fill")
    }

    static var snoozeButton: AlarmButton {
        AlarmButton(text: "Snooze", textColor: .orange, systemImageName: "zzz")
    }
}

/// Manages sunrise alarms using AlarmKit (iOS 26+)
@MainActor
class AlarmKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var currentAlarm: Alarm?

    private let manager = AlarmManager.shared
    private var alarmID: UUID?

    // Persistent storage key for alarm ID
    private let alarmIDKey = "com.archerfish.risecue.currentAlarmID"

    init() {
        // Restore alarm ID from storage
        if let storedIDString = UserDefaults.standard.string(forKey: alarmIDKey),
           let storedID = UUID(uuidString: storedIDString) {
            alarmID = storedID
        }
        Task {
            await checkAuthorizationStatus()
            await observeAlarms()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        switch manager.authorizationState {
        case .notDetermined:
            do {
                let state = try await manager.requestAuthorization()
                isAuthorized = state == .authorized
                return isAuthorized
            } catch {
                print("AlarmKit authorization error: \(error)")
                return false
            }
        case .authorized:
            isAuthorized = true
            return true
        case .denied:
            isAuthorized = false
            return false
        @unknown default:
            return false
        }
    }

    func checkAuthorizationStatus() async {
        isAuthorized = manager.authorizationState == .authorized
    }

    // MARK: - Alarm Scheduling

    /// Schedule a sunrise alarm for a specific time
    func scheduleAlarm(
        at fireDate: Date,
        isBefore: Bool,
        locationName: String
    ) async throws -> Bool {
        // Cancel existing alarm first
        await cancelAlarm()

        // Create alarm presentation
        let alertTitle: LocalizedStringResource = isBefore ? "Sunrise Soon" : "Sunrise!"
        let alertContent = AlarmPresentation.Alert(title: alertTitle, stopButton: .stopButton)

        // Create alarm attributes with metadata
        let metadata = SunriseAlarmData(isBefore: isBefore, locationName: locationName)
        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alertContent),
            metadata: metadata,
            tintColor: .orange
        )

        // Create a new alarm ID
        let newAlarmID = UUID()

        do {
            // Schedule the alarm using .alarm configuration for fixed time
            let schedule = Alarm.Schedule.fixed(fireDate)
            let alarm = try await manager.schedule(
                id: newAlarmID,
                configuration: .alarm(schedule: schedule, attributes: attributes)
            )

            // Store the alarm ID for later reference
            alarmID = newAlarmID
            UserDefaults.standard.set(newAlarmID.uuidString, forKey: alarmIDKey)

            currentAlarm = alarm
            print("Successfully scheduled sunrise alarm for \(fireDate)")
            return true
        } catch {
            print("Failed to schedule alarm: \(error)")
            throw error
        }
    }

    // MARK: - Alarm Cancellation

    func cancelAlarm() async {
        guard let id = alarmID else { return }

        do {
            try await manager.cancel(id: id)
            print("Cancelled alarm \(id)")
        } catch {
            print("Failed to cancel alarm: \(error)")
        }

        alarmID = nil
        currentAlarm = nil
        UserDefaults.standard.removeObject(forKey: alarmIDKey)
    }

    // MARK: - Alarm Observation

    private func observeAlarms() async {
        for await alarms in manager.alarmUpdates {
            // Update current alarm state if our alarm is in the list
            if let id = alarmID {
                currentAlarm = alarms.first { $0.id == id }

                // If our alarm is no longer in the list, it was dismissed
                if currentAlarm == nil {
                    alarmID = nil
                    UserDefaults.standard.removeObject(forKey: alarmIDKey)
                }
            }
        }
    }

    // MARK: - Helpers

    var hasActiveAlarm: Bool {
        currentAlarm != nil
    }
}
