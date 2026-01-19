import Foundation
import AlarmKit

/// Metadata for sunrise alarm, shared between app and widget extension
nonisolated struct RiseCueAlarmData: AlarmMetadata {
    /// Whether this alarm is before or after sunrise
    let isBefore: Bool
    /// The location name for display
    let locationName: String

    init(isBefore: Bool = true, locationName: String = "") {
        self.isBefore = isBefore
        self.locationName = locationName
    }
}
