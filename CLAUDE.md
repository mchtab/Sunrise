# Sunrise Alarm App - Development Context

## Overview

Sunrise is a SwiftUI iOS app that wakes users with the sunrise. It features a calm, meditative UI with a day/night cycle that adapts the entire interface based on the time of day. The app uses AlarmKit (iOS 26+) for reliable system-level alarms.

## Architecture

**Pattern:** MVVM (Model-View-ViewModel)

### Core Files

| File | Purpose |
|------|---------|
| `SunriseApp.swift` | App entry point, AppDelegate for background tasks, AlarmKit authorization |
| `ContentView.swift` | Main home screen with alarm controls, onboarding, success toasts |
| `SunriseViewModel.swift` | Central state management, coordinates services, alarm scheduling |
| `Theme.swift` | Design system: colors, typography, components, day/night cycle, accessibility |

### Models (`Models/`)

- `SavedLocation.swift` - Location model + `LocationStore` (UserDefaults persistence) + `AlarmTiming` enum

### Views (`Views/`)

- `SettingsView.swift` - Alarm timing configuration (4 options: nautical dawn to after sunrise)
- `LocationManagementView.swift` - Location CRUD + `AddLocationView`

### Services (`Services/`)

- `LocationManager.swift` - CoreLocation wrapper
- `SunriseService.swift` - Fetches from sunrise-sunset.org API, returns `SunTimes` struct
- `NotificationManager.swift` - Local notification scheduling (legacy)
- `AlarmKitManager.swift` - AlarmKit wrapper for system-level alarms

## Design System (Theme.swift)

### Adaptive Day/Night Cycle

The app uses `TimePhase` enum to detect current time:
- **Night** (9 PM - 5 AM): Dark indigo sky, stars, crescent moon, light text
- **Dawn** (5 AM - 8 AM): Peach/lavender gradient, golden sun glow
- **Day** (8 AM - 6 PM): Light blue sky, warm accents
- **Dusk** (6 PM - 9 PM): Purple/orange sunset, dark text on light cards

### Dual Color System

The app uses separate color systems for text on gradient backgrounds vs text on cards:

```swift
// TEXT ON CARDS (used in card content)
Color.adaptiveText           // Primary text on cards
Color.adaptiveTextSecondary  // Muted text on cards
Color.adaptiveAccent         // Accent color on cards

// TEXT ON GRADIENT (used in headers, sky backgrounds)
Color.adaptiveGradientText           // Primary text on gradient
Color.adaptiveGradientTextSecondary  // Muted text on gradient
Color.adaptiveGradientAccent         // Accent color on gradient

// SURFACES
Color.adaptiveCardBackground // Card surfaces (translucent)
Color.adaptiveCardBorder     // Borders (visible at night)
Color.adaptiveShadow         // Shadow intensity
```

**Important:** Dusk mode uses DARK text on cards (since cards are light/translucent) but LIGHT text on gradient backgrounds.

### Typography (DawnTypography)

- **Display fonts:** SF Serif (light weight) for headlines
- **UI fonts:** SF Pro Rounded for body text

Standard modifiers (for card content):
- `.dawnDisplayLarge()`, `.dawnDisplayMedium()`, `.dawnHeadline()`, `.dawnBody()`, `.dawnCaption()`

Gradient modifiers (for text on sky/gradient backgrounds):
- `.dawnDisplayLargeOnGradient()`, `.dawnDisplayMediumOnGradient()`, `.dawnTitleOnGradient()`, `.dawnCaptionOnGradient()`

### Accessibility Features

```swift
// Haptic feedback
HapticFeedback.light.trigger()
HapticFeedback.success.trigger()
HapticFeedback.selection.trigger()

// Reduce Motion support
@Environment(\.accessibilityReduceMotion) var reduceMotion
.reduceMotionSensitive(reduceMotion)  // Modifier to honor preference

// Loading states
TimeDisplaySkeleton()  // Skeleton placeholder for time cards
```

### Key Components

- `DawnSkyBackground` - Animated celestial background with stars/moon/sun (honors Reduce Motion)
- `BreathingSun` - Animated sun visualization
- `CalmCardModifier` - Glass-morphic card style (`.calmCard()`)
- `SoftButtonStyle` - Gradient buttons
- `TimeDisplay` - Time card component with relative time ("in 6 hours")
- `TimeDisplaySkeleton` - Loading placeholder

## Alarm System

### AlarmTiming Options

```swift
enum AlarmTiming: String, Codable, CaseIterable {
    case nauticalDawn = "Nautical Dawn"   // ~60 min before sunrise
    case civilDawn = "Civil Dawn"         // ~30 min before sunrise
    case sunrise = "Sunrise"              // At sunrise
    case afterSunrise = "After Sunrise"   // 10 min after sunrise
}
```

### SunTimes Struct

```swift
struct SunTimes {
    let nauticalDawn: Date
    let civilDawn: Date
    let sunrise: Date
    let solarNoon: Date
    let sunset: Date
    let civilDusk: Date
    let nauticalDusk: Date

    func alarmTime(for timing: AlarmTiming) -> Date
}
```

### Daily Auto-Repeat

- `LocationStore.alarmRepeats: Bool` - Whether alarm auto-schedules for next day
- `SunriseViewModel.rescheduleForNextDay()` - Fetches tomorrow's sun times and reschedules
- Background refresh task updates alarm daily

## API

Uses [sunrise-sunset.org/api](https://sunrise-sunset.org/api):
- No API key required
- Returns ISO 8601 timestamps
- Returns all twilight times (astronomical, nautical, civil dawn/dusk)
- Endpoint: `https://api.sunrise-sunset.org/json?lat={lat}&lng={lng}&formatted=0&date={date}`

## Key Implementation Details

### Date Parsing

`SunriseService.swift` includes `parseISO8601Date()` that handles multiple date formats since the API response format can vary.

### AlarmKit Integration

- Uses `AlarmKit` framework for iOS 26+ system-level alarms
- `AlarmKitManager` handles authorization, scheduling, and cancellation
- Alarms fire even when app is terminated
- Background task (`BGAppRefreshTask`) reschedules daily

### Alarm Sound

Custom alarm sound at `alarm.caf` (converted from MP3, under 30 seconds for iOS limit).

## Build Requirements

- iOS 26.0+ (for AlarmKit)
- Xcode 16.0+
- Swift 5.0+

## Testing

### Testing Night Mode
1. Settings > General > Date & Time
2. Turn off "Set Automatically"
3. Set time to 10:00 PM or later

### Testing Dusk Mode
Set time to 7:00 PM to verify dark text on light cards.

### Testing Reduce Motion
1. Settings > Accessibility > Motion > Reduce Motion
2. Verify animations are disabled/reduced

## Common Tasks

### Adding a new adaptive color
1. Add cases to each `TimePhase` in the computed property in `Theme.swift` Color extension
2. If for gradient backgrounds, add to `adaptiveGradient*` properties
3. If for card content, add to `adaptive*` properties

### Updating a view for night mode
1. Add `private let timePhase = TimePhase.current()`
2. Use `Color.adaptive*` properties for card content
3. Use `Color.adaptiveGradient*` for text on sky/gradient backgrounds
4. Add borders for night: `.stroke(Color.adaptiveCardBorder, lineWidth: isNightMode ? 1 : 0)`

### Adding a new screen
1. Create in `Views/` folder
2. Use `DawnSkyBackground()` or `adaptiveBackground` for background
3. Use `*OnGradient()` typography modifiers for headers on gradient
4. Use standard dawn typography modifiers for card content
5. Use `SoftButtonStyle` for buttons
6. Use `.calmCard()` for card containers
7. Add haptic feedback for interactions: `HapticFeedback.selection.trigger()`

### Adding accessibility
1. Add `.accessibilityLabel()` and `.accessibilityHint()` to interactive elements
2. Use `@Environment(\.accessibilityReduceMotion)` for animations
3. Apply `.reduceMotionSensitive()` modifier to animated views
