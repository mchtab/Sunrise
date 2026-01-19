import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: RiseCueViewModel
    @EnvironmentObject var locationStore: LocationStore
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var showingLocationManagement = false
    @State private var showingSettings = false
    @State private var appearAnimation = false
    @State private var showSuccessToast = false
    @State private var toastMessage = ""

    /// Determines if this is a first-time user (no locations set up)
    private var isFirstTimeUser: Bool {
        locationStore.savedLocations.isEmpty
    }

    var body: some View {
        let isTablet = horizontalSizeClass == .regular
        let maxWidth: CGFloat = isTablet ? 600 : .infinity

        ZStack {
            // Animated dawn sky background - fills entire screen
            DawnSkyBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with controls
                    headerSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : -20)
                        .padding(.top, 16)

                    Spacer()
                        .frame(height: isTablet ? 60 : 40)

                    // Main content area - show onboarding or main UI
                    if isFirstTimeUser {
                        onboardingSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .frame(maxWidth: maxWidth)
                    } else {
                        VStack(spacing: isTablet ? 50 : 36) {
                            // Sun visualization
                            sunSection
                                .opacity(appearAnimation ? 1 : 0)
                                .scaleEffect(appearAnimation ? 1 : 0.8)

                            // Location indicator
                            if let locationName = viewModel.currentLocationName {
                                locationIndicator(name: locationName)
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(y: appearAnimation ? 0 : 20)
                            }

                            // Time cards with loading skeletons
                            if viewModel.isLoading {
                                loadingSkeletonSection(isTablet: isTablet)
                            } else {
                                timeCardsSection(isTablet: isTablet)
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(y: appearAnimation ? 0 : 30)
                            }

                            // Error message with recovery action
                            if let errorMessage = viewModel.errorMessage {
                                errorSection(message: errorMessage)
                            }
                        }
                        .frame(maxWidth: maxWidth)

                        Spacer()
                            .frame(height: isTablet ? 60 : 40)

                        // Action buttons
                        actionSection(isTablet: isTablet)
                            .frame(maxWidth: maxWidth)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 40)
                    }

                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, isTablet ? 40 : 24)
            }
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }

            // Success toast overlay
            if showSuccessToast {
                successToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showingLocationManagement) {
            LocationManagementView()
                .environmentObject(locationStore)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(locationStore)
        }
        .onAppear {
            viewModel.requestPermissions()
            if let selectedLocation = locationStore.selectedLocation {
                viewModel.updateSelectedLocation(selectedLocation)
            }

            let animation: Animation = reduceMotion ? .easeOut(duration: 0.3) : .easeOut(duration: 1.2).delay(0.2)
            withAnimation(animation) {
                appearAnimation = true
            }
        }
        .onChange(of: viewModel.alarmEnabled) { _, newValue in
            if newValue {
                showToast("Alarm set successfully")
            }
        }
    }

    // MARK: - Toast Helper
    private func showToast(_ message: String) {
        HapticFeedback.success.trigger()
        toastMessage = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showSuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSuccessToast = false
            }
        }
    }

    // MARK: - Success Toast View
    private var successToast: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)

                Text(toastMessage)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.softSage)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            )
            .padding(.top, 60)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Success: \(toastMessage)")
        .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Onboarding Section (First-Time Users)
    private var onboardingSection: some View {
        let timePhase = TimePhase.current()
        let isNightMode = timePhase == .night || timePhase == .dusk

        return VStack(spacing: 32) {
            // Welcome illustration
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.sunGold.opacity(0.3),
                                    Color.dawnRose.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.sunGold)
                        .shadow(color: .sunGold.opacity(0.5), radius: 20)
                }

                VStack(spacing: 12) {
                    Text("Wake with the sun")
                        .dawnDisplayLarge()

                    Text("Start your mornings aligned with\nnature's rhythm")
                        .font(DawnTypography.subheadline)
                        .foregroundColor(.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            // Setup steps
            VStack(spacing: 16) {
                onboardingStep(
                    number: 1,
                    title: "Add your location",
                    description: "We'll find your local sunrise time",
                    icon: "mappin.circle.fill",
                    isComplete: false
                )

                onboardingStep(
                    number: 2,
                    title: "Set your alarm",
                    description: "Choose before or after sunrise",
                    icon: "bell.circle.fill",
                    isComplete: false
                )

                onboardingStep(
                    number: 3,
                    title: "Wake naturally",
                    description: "Your alarm adjusts with the seasons",
                    icon: "sun.max.circle.fill",
                    isComplete: false
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.adaptiveCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.adaptiveCardBorder, lineWidth: isNightMode ? 1 : 0)
                    )
                    .shadow(color: Color.adaptiveShadow, radius: 20, x: 0, y: 8)
            )

            // Get started button
            Button(action: {
                HapticFeedback.medium.trigger()
                showingLocationManagement = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                    Text("Get Started")
                }
            }
            .buttonStyle(SoftButtonStyle(isPrimary: true))
            .accessibilityHint("Opens location setup to begin using the app")
        }
        .padding(.vertical, 20)
    }

    private func onboardingStep(number: Int, title: String, description: String, icon: String, isComplete: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.adaptiveAccent.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.adaptiveAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.adaptiveText)

                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.adaptiveTextSecondary)
            }

            Spacer()

            Text("\(number)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.adaptiveTextSecondary.opacity(0.5))
        }
    }

    // MARK: - Loading Skeleton Section
    private func loadingSkeletonSection(isTablet: Bool) -> some View {
        Group {
            if isTablet {
                HStack(spacing: 20) {
                    TimeDisplaySkeleton()
                }
            } else {
                VStack(spacing: 16) {
                    TimeDisplaySkeleton()
                }
            }
        }
    }

    // MARK: - Header Section (directly on gradient, not on card)
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingText)
                    .dawnCaptionOnGradient()
                Text("RiseCue")
                    .dawnTitleOnGradient()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(greetingText). RiseCue alarm app")

            Spacer()

            HStack(spacing: 12) {
                CalmIconButton(icon: "mappin.circle") {
                    HapticFeedback.light.trigger()
                    showingLocationManagement = true
                }
                .accessibilityLabel("Manage locations")
                .accessibilityHint("Opens location management screen")

                CalmIconButton(icon: "slider.horizontal.3") {
                    HapticFeedback.light.trigger()
                    showingSettings = true
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens alarm timing settings")
            }
        }
        .padding(.top, 16)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    // MARK: - Sun Section (Adaptive)
    private var sunSection: some View {
        let timePhase = TimePhase.current()

        return VStack(spacing: 28) {
            // Show sun during day phases, subtle glow at night
            if timePhase == .night {
                // Night: Show a peaceful sleeping indicator
                nightCelestialView
            } else {
                BreathingSun(size: 100)
                    .frame(height: 180)
            }

            // Taglines are directly on gradient
            VStack(spacing: 10) {
                Text(timePhase == .night ? "Rest peacefully" : "Wake with the sun")
                    .dawnDisplayLargeOnGradient()

                Text(timePhase == .night ? "Your sunrise alarm is set" : "Align your rhythm with nature")
                    .dawnSubheadlineOnGradient()
            }
        }
    }

    private var nightCelestialView: some View {
        ZStack {
            // Soft glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.moonGlow.opacity(0.2),
                            Color.moonGlow.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)

            // Stars around
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(Color.starWhite)
                    .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                    .offset(
                        x: cos(Double(i) * .pi / 4) * 70,
                        y: sin(Double(i) * .pi / 4) * 70
                    )
                    .opacity(0.6)
            }

            // Small moon icon
            Image(systemName: "moon.fill")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.moonGlow)
                .shadow(color: .moonGlow.opacity(0.5), radius: 20)
        }
        .frame(height: 180)
    }

    // MARK: - Location Indicator (Adaptive)
    private func locationIndicator(name: String) -> some View {
        let timePhase = TimePhase.current()

        return HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .font(.system(size: 12))
                .foregroundColor(.adaptiveAccent)

            Text(name)
                .dawnCaption()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.adaptiveCardBackground)
                .overlay(
                    Capsule()
                        .stroke(Color.adaptiveCardBorder, lineWidth: timePhase == .night ? 1 : 0)
                )
                .shadow(color: Color.adaptiveShadow, radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Loading Section (Adaptive) - Deprecated, use loadingSkeletonSection instead
    private var loadingSection: some View {
        loadingSkeletonSection(isTablet: false)
    }

    // MARK: - Time Cards Section
    private func timeCardsSection(isTablet: Bool) -> some View {
        Group {
            if isTablet {
                HStack(spacing: 20) {
                    timeCards
                }
            } else {
                VStack(spacing: 16) {
                    timeCards
                }
            }
        }
    }

    @ViewBuilder
    private var timeCards: some View {
        if let sunriseTime = viewModel.sunriseTime {
            TimeDisplay(
                time: sunriseTime,
                label: "Next Sunrise",
                icon: "sun.horizon.fill"
            )
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
        }

        if viewModel.alarmEnabled, let alarmTime = viewModel.alarmTime {
            TimeDisplay(
                time: alarmTime,
                label: "Alarm Set",
                icon: "bell.fill"
            )
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
        }
    }

    // MARK: - Error Section (Adaptive) with Recovery Action
    private func errorSection(message: String) -> some View {
        let timePhase = TimePhase.current()
        let isNightMode = timePhase == .night || timePhase == .dusk

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.adaptiveAccent)

                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.adaptiveText.opacity(0.8))
                    .multilineTextAlignment(.leading)

                Spacer()
            }

            // Retry button for error recovery
            Button(action: {
                HapticFeedback.light.trigger()
                viewModel.refreshSunriseData()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Try Again")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.adaptiveAccent)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.adaptiveAccent.opacity(0.15))
                )
            }
            .frame(minHeight: 44)
            .accessibilityLabel("Retry loading sunrise data")
            .accessibilityHint("Attempts to fetch sunrise time again")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isNightMode ? Color.adaptiveAccent.opacity(0.15) : Color.dawnRose.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.adaptiveAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: - Action Section
    private func actionSection(isTablet: Bool) -> some View {
        VStack(spacing: 16) {
            if locationStore.savedLocations.isEmpty {
                // No locations - show add location (shouldn't happen with onboarding)
                Button(action: {
                    HapticFeedback.medium.trigger()
                    showingLocationManagement = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add Your Location")
                    }
                }
                .buttonStyle(SoftButtonStyle(isPrimary: true))
                .accessibilityHint("Opens location setup to add your first location")

            } else if !viewModel.alarmEnabled {
                // Has location, no alarm set
                Button(action: {
                    HapticFeedback.medium.trigger()
                    viewModel.setupAlarm()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 18))
                        Text("Set Alarm")
                    }
                }
                .buttonStyle(SoftButtonStyle(isPrimary: true))
                .accessibilityLabel("Set sunrise alarm")
                .accessibilityHint("Schedules an alarm to wake you with the sunrise")

                // Test alarm button
                Button(action: {
                    HapticFeedback.light.trigger()
                    viewModel.scheduleTestAlarm(delaySeconds: 10)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.and.waves.left.and.right")
                            .font(.system(size: 16))
                        Text("Test Alarm (10s)")
                    }
                }
                .buttonStyle(SoftButtonStyle(isPrimary: false))
                .accessibilityLabel("Test alarm in 10 seconds")
                .accessibilityHint("Triggers a test alarm in 10 seconds to preview the alarm sound")

            } else {
                // Alarm is set - show status and cancel option
                alarmStatusBadge

                Button(action: {
                    HapticFeedback.warning.trigger()
                    viewModel.cancelAlarm()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 16))
                        Text("Cancel Alarm")
                    }
                }
                .buttonStyle(SoftButtonStyle(isPrimary: false))
                .accessibilityLabel("Cancel alarm")
                .accessibilityHint("Removes the scheduled sunrise alarm")
            }
        }
    }

    private var alarmStatusBadge: some View {
        let timePhase = TimePhase.current()
        let isNightMode = timePhase == .night || timePhase == .dusk

        // Adaptive success color
        let successColor = isNightMode ?
            Color(red: 0.55, green: 0.70, blue: 0.65) : // Muted teal for night
            Color.softSage

        // Calculate relative time for accessibility
        let relativeTime: String = {
            guard let alarmTime = viewModel.alarmTime else { return "" }
            let interval = alarmTime.timeIntervalSince(Date())
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            if hours > 0 {
                return "in \(hours) hours and \(minutes) minutes"
            } else {
                return "in \(minutes) minutes"
            }
        }()

        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(successColor.opacity(0.3))
                    .frame(width: 36, height: 36)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(successColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Alarm Active")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.adaptiveText)

                Text("You'll wake with the sunrise")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.adaptiveTextSecondary)
            }

            Spacer()

            // Pulsing indicator
            Circle()
                .fill(successColor)
                .frame(width: 8, height: 8)
                .shadow(color: successColor.opacity(0.5), radius: 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(successColor.opacity(isNightMode ? 0.15 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(successColor.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Alarm is active. You'll wake with the sunrise \(relativeTime)")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = RiseCueViewModel()
        let locationStore = LocationStore()
        viewModel.locationStore = locationStore

        return Group {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(locationStore)
                .previewDevice("iPhone 15 Pro")
                .previewDisplayName("iPhone")

            ContentView()
                .environmentObject(viewModel)
                .environmentObject(locationStore)
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .previewDisplayName("iPad")
        }
    }
}
