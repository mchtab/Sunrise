# RiseCue

A beautiful iOS app that wakes you naturally with the sunrise. Built with SwiftUI and AlarmKit for reliable, system-level alarms.

![iOS 26+](https://img.shields.io/badge/iOS-26%2B-blue)
![Swift 5](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Wake with the Sun** - Alarm automatically adjusts to your local sunrise time
- **Flexible Timing** - Choose from 4 wake-up options:
  - Nautical Dawn (~60 min before sunrise)
  - Civil Dawn (~30 min before sunrise)
  - Sunrise (at sunrise)
  - After Sunrise (10 min after)
- **Multiple Locations** - Save and switch between different locations
- **Daily Auto-Repeat** - Automatically schedules tomorrow's alarm
- **Adaptive UI** - Beautiful interface that changes with the time of day
- **Reliable Alarms** - Uses AlarmKit for system-level alarms that fire even when the app is closed

## Screenshots

*Coming soon*

## Requirements

- iOS 26.0+
- Xcode 16.0+
- Swift 5.0+

## Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/RiseCue.git
```

2. Open `Sunrise.xcodeproj` in Xcode

3. Select your development team in Signing & Capabilities

4. Build and run on a device or simulator (iOS 26+)

## Permissions

- **Location** - To calculate accurate sunrise times for your area
- **Alarms** - For system-level alarm scheduling via AlarmKit

## How It Works

1. Grant location and alarm permissions
2. Add your location (GPS or manual coordinates)
3. Choose your preferred alarm timing in Settings
4. Tap "Set Alarm" to activate
5. Wake naturally with the sunrise!

The app fetches sunrise data from the [sunrise-sunset.org API](https://sunrise-sunset.org/api) and uses AlarmKit to schedule reliable system-level alarms.

## Architecture

The app follows MVVM architecture:

```
RiseCue/
├── Sunrise.xcodeproj/
├── Sunrise/
│   ├── SunriseApp.swift        # App entry point
│   ├── ContentView.swift        # Main interface
│   ├── SunriseViewModel.swift   # State management
│   ├── Theme.swift              # Design system
│   ├── Models/
│   │   ├── SavedLocation.swift  # Location model
│   │   └── SunriseAlarmData.swift
│   ├── Views/
│   │   ├── SettingsView.swift
│   │   └── LocationManagementView.swift
│   ├── Services/
│   │   ├── LocationManager.swift
│   │   ├── SunriseService.swift
│   │   └── AlarmKitManager.swift
│   └── Assets.xcassets/
└── README.md
```

## Acknowledgments

- Sun times data provided by [sunrise-sunset.org](https://sunrise-sunset.org)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

Built with ☀️ by Michael Chen
