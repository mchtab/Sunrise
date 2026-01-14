import SwiftUI
import AlarmKit
import BackgroundTasks

@main
struct SunriseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var locationStore = LocationStore()
    @StateObject private var viewModel = SunriseViewModel()

    init() {
        let locationStore = LocationStore()
        let viewModel = SunriseViewModel()
        viewModel.locationStore = locationStore
        _locationStore = StateObject(wrappedValue: locationStore)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(locationStore)
                .task {
                    // Request AlarmKit authorization on launch
                    await requestAlarmAuthorization()
                }
        }
    }

    private func requestAlarmAuthorization() async {
        let manager = AlarmManager.shared
        if manager.authorizationState == .notDetermined {
            do {
                let state = try await manager.requestAuthorization()
                print("AlarmKit authorization: \(state)")
            } catch {
                print("AlarmKit authorization error: \(error)")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        registerBackgroundTasks()
        return true
    }

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.sunrise.app.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        let locationStore = LocationStore()
        let sunriseService = SunriseService()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        guard let selectedLocation = locationStore.selectedLocation else {
            task.setTaskCompleted(success: false)
            return
        }

        // Fetch tomorrow's sun times and reschedule alarm using AlarmKit
        sunriseService.fetchSunTimes(latitude: selectedLocation.latitude, longitude: selectedLocation.longitude) { result in
            Task { @MainActor in
                switch result {
                case .success(let sunTimes):
                    let alarmDate = sunTimes.alarmTime(for: locationStore.alarmTiming)
                    let alarmManager = AlarmKitManager()
                    do {
                        _ = try await alarmManager.scheduleAlarm(
                            at: alarmDate,
                            isBefore: locationStore.alarmTiming != .afterSunrise,
                            locationName: selectedLocation.name
                        )
                        task.setTaskCompleted(success: true)
                    } catch {
                        print("Background alarm scheduling failed: \(error)")
                        task.setTaskCompleted(success: false)
                    }
                case .failure:
                    task.setTaskCompleted(success: false)
                }
            }
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.sunrise.app.refresh")
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 12, to: Date())

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}
