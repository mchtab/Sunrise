import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var locationStore: LocationStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var appearAnimation = false
    private let timePhase = TimePhase.current()

    var body: some View {
        let isTablet = horizontalSizeClass == .regular

        NavigationView {
            ZStack {
                // Background - adaptive to time
                adaptiveBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header illustration
                        settingsHeader
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)

                        // Settings cards
                        VStack(spacing: 20) {
                            alarmTimingCard
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)

                            repeatAlarmCard
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 25)

                            aboutCard
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 30)
                        }
                        .frame(maxWidth: isTablet ? 500 : .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.adaptiveText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.adaptiveAccent)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Adaptive Background
    @ViewBuilder
    private var adaptiveBackground: some View {
        switch timePhase {
        case .night:
            LinearGradient(
                colors: [Color.nightDeep, Color.nightIndigo, Color.nightPurple.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .dusk:
            LinearGradient(
                colors: [Color.nightPurple.opacity(0.6), Color.duskPurple, Color.duskPink.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            Color.dawnCream
        }
    }

    // MARK: - Settings Header (Adaptive)
    private var settingsHeader: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk

        return VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (isNightMode ? Color.moonGlow : Color.sunGold).opacity(0.3),
                                (isNightMode ? Color.nightPurple : Color.dawnPeach).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.adaptiveGradientAccent)
            }

            Text("Customize your wake")
                .dawnDisplayMediumOnGradient()
        }
        .padding(.top, 20)
    }

    // MARK: - Alarm Timing Card (Adaptive)
    private var alarmTimingCard: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk

        return VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill((isNightMode ? Color.moonGlow : Color.sunGold).opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "clock")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isNightMode ? .moonGlow : .sunGold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Alarm Timing")
                        .dawnHeadline()

                    Text("When should we wake you?")
                        .dawnCaption()
                }

                Spacer()
            }

            // Timing options as a vertical list
            VStack(spacing: 8) {
                ForEach(AlarmTiming.allCases) { timing in
                    timingOption(timing)
                }
            }

            // Description of selected timing
            HStack(spacing: 10) {
                Image(systemName: locationStore.alarmTiming.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.adaptiveAccent)
                    .frame(width: 24)

                Text(locationStore.alarmTiming.description)
                    .dawnBody()
                    .lineSpacing(5)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isNightMode ? Color.white.opacity(0.08) : Color.dawnLavender.opacity(0.2))
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.adaptiveCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.adaptiveCardBorder, lineWidth: isNightMode ? 1 : 0)
                )
                .shadow(color: Color.adaptiveShadow, radius: 20, x: 0, y: 8)
        )
    }

    private func timingOption(_ timing: AlarmTiming) -> some View {
        let isSelected = locationStore.alarmTiming == timing
        let isNightMode = timePhase == .night || timePhase == .dusk

        return Button(action: {
            HapticFeedback.selection.trigger()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                locationStore.updateAlarmTiming(timing)
            }
        }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.adaptiveAccent : Color.adaptiveAccent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: timing.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : .adaptiveAccent)
                }

                // Label and approximate time
                VStack(alignment: .leading, spacing: 2) {
                    Text(timing.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.adaptiveText)

                    Text(timingSubtitle(for: timing))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.adaptiveTextSecondary)
                }

                Spacer()

                // Checkmark for selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.adaptiveAccent)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ?
                          (isNightMode ? Color.white.opacity(0.12) : Color.adaptiveAccent.opacity(0.1)) :
                          Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color.adaptiveAccent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(timing.rawValue), \(timing.description)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// Generate subtitle showing approximate time relative to sunrise
    private func timingSubtitle(for timing: AlarmTiming) -> String {
        let minutes = timing.approximateMinutesBefore
        if minutes > 0 {
            return "~\(minutes) min before sunrise"
        } else if minutes < 0 {
            return "~\(abs(minutes)) min after sunrise"
        } else {
            return "At sunrise"
        }
    }

    // MARK: - Repeat Alarm Card (Adaptive)
    private var repeatAlarmCard: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk
        let repeatColor = isNightMode ?
            Color(red: 0.55, green: 0.65, blue: 0.75) : // Muted blue for night
            Color.mistBlue

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(repeatColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "repeat")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(repeatColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Alarm")
                        .dawnHeadline()

                    Text("Auto-schedule for tomorrow")
                        .dawnCaption()
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { locationStore.alarmRepeats },
                    set: { locationStore.updateAlarmRepeats($0) }
                ))
                .tint(repeatColor)
                .labelsHidden()
            }

            if locationStore.alarmRepeats {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(repeatColor.opacity(0.8))

                    Text("After your alarm fires, we'll automatically schedule the next day's sunrise alarm.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.adaptiveTextSecondary)
                        .lineSpacing(4)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isNightMode ? Color.white.opacity(0.06) : repeatColor.opacity(0.08))
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.adaptiveCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.adaptiveCardBorder, lineWidth: isNightMode ? 1 : 0)
                )
                .shadow(color: Color.adaptiveShadow, radius: 20, x: 0, y: 8)
        )
        .animation(.easeInOut(duration: 0.2), value: locationStore.alarmRepeats)
    }

    // MARK: - About Card (Adaptive)
    private var aboutCard: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk

        // Adaptive nature color
        let natureColor = isNightMode ?
            Color(red: 0.55, green: 0.70, blue: 0.65) : // Muted teal for night
            Color.softSage

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(natureColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "leaf")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(natureColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("About RiseCue")
                        .dawnHeadline()

                    Text("Wake naturally, live fully")
                        .dawnCaption()
                }

                Spacer()
            }

            Text("RiseCue helps you align your sleep cycle with natural light patterns. Waking with the sun has been shown to improve mood, energy levels, and overall well-being.")
                .dawnBody()
                .lineSpacing(6)

            // API Attribution
            Link(destination: URL(string: "https://sunrise-sunset.org")!) {
                HStack(spacing: 8) {
                    Image(systemName: "sun.horizon")
                        .font(.system(size: 14))
                        .foregroundColor(natureColor)

                    Text("Sun times by sunrise-sunset.org")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(natureColor)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(natureColor.opacity(0.6))
                }
                .frame(minHeight: 44)
            }

            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.adaptiveAccent.opacity(0.6))

                Text("Version 1.0")
                    .font(DawnTypography.captionSmall)
                    .foregroundColor(.adaptiveTextSecondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.adaptiveCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.adaptiveCardBorder, lineWidth: isNightMode ? 1 : 0)
                )
                .shadow(color: Color.adaptiveShadow, radius: 20, x: 0, y: 8)
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(LocationStore())
    }
}
