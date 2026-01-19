import SwiftUI
import CoreLocation

struct LocationManagementView: View {
    @EnvironmentObject var locationStore: LocationStore
    @EnvironmentObject var viewModel: SunriseViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var showingAddLocation = false
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
                    VStack(spacing: 24) {
                        // Header
                        locationHeader
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)

                        // Locations list
                        if locationStore.savedLocations.isEmpty {
                            emptyStateView
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                        } else {
                            locationsListView
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .frame(maxWidth: isTablet ? 500 : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.adaptiveAccent)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Locations")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.adaptiveText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddLocation = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.adaptiveAccent)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Add location")
                }
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView()
                    .environmentObject(locationStore)
                    .environmentObject(viewModel)
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

    // MARK: - Location Header (Adaptive)
    private var locationHeader: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk
        let accentColor = isNightMode ? Color.moonGlow : Color.mistBlue

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.3),
                                (isNightMode ? Color.nightPurple : Color.dawnLavender).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "map")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(accentColor)
            }

            VStack(spacing: 6) {
                Text("Your places")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundColor(.adaptiveGradientText)

                Text("Where will you watch the sunrise?")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.adaptiveGradientTextSecondary)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Empty State (Adaptive)
    private var emptyStateView: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk

        return VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "location.slash")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.adaptiveTextSecondary.opacity(0.5))

                VStack(spacing: 8) {
                    Text("No locations yet")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.adaptiveText)

                    Text("Add your first location to start\nwaking with the sunrise")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.vertical, 40)

            Button(action: { showingAddLocation = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Location")
                }
            }
            .buttonStyle(SoftButtonStyle(isPrimary: true))
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

    // MARK: - Locations List
    private var locationsListView: some View {
        VStack(spacing: 12) {
            ForEach(locationStore.savedLocations) { location in
                LocationCard(location: location) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        locationStore.selectLocation(location)
                        viewModel.updateSelectedLocation(location)
                    }
                } onDelete: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        locationStore.deleteLocation(location)
                    }
                }
            }
        }
    }
}

// MARK: - Location Card (Adaptive)
struct LocationCard: View {
    let location: SavedLocation
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteConfirmation = false
    private let timePhase = TimePhase.current()

    var body: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk

        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Location icon
                ZStack {
                    Circle()
                        .fill(location.isSelected ? Color.adaptiveAccent.opacity(0.15) : (isNightMode ? Color.white.opacity(0.1) : Color.dawnPeach.opacity(0.3)))
                        .frame(width: 48, height: 48)

                    Image(systemName: location.isSelected ? "mappin.circle.fill" : "mappin.circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(location.isSelected ? .adaptiveAccent : .adaptiveTextSecondary)
                }

                // Location details
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.adaptiveText)

                    Text(coordinateString)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.adaptiveTextSecondary)
                }

                Spacer()

                // Selection indicator or delete button
                if location.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isNightMode ? Color(red: 0.55, green: 0.70, blue: 0.65) : .softSage)
                } else {
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.adaptiveTextSecondary.opacity(0.6))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(isNightMode ? Color.white.opacity(0.08) : Color.dawnRose.opacity(0.1))
                            )
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete \(location.name)")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.adaptiveCardBackground)
                    .shadow(color: Color.adaptiveShadow, radius: location.isSelected ? 15 : 10, x: 0, y: location.isSelected ? 6 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(location.isSelected ? Color.adaptiveAccent.opacity(0.3) : Color.adaptiveCardBorder, lineWidth: location.isSelected ? 2 : (isNightMode ? 1 : 0))
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog("Delete Location", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \(location.name)?")
        }
    }

    private var coordinateString: String {
        let latDir = location.latitude >= 0 ? "N" : "S"
        let lonDir = location.longitude >= 0 ? "E" : "W"
        return String(format: "%.2f°%@ %.2f°%@", abs(location.latitude), latDir, abs(location.longitude), lonDir)
    }
}

// MARK: - Add Location View (Adaptive)
struct AddLocationView: View {
    @EnvironmentObject var locationStore: LocationStore
    @EnvironmentObject var viewModel: SunriseViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var locationName = ""
    @State private var useCurrentLocation = true
    @State private var manualLatitude = ""
    @State private var manualLongitude = ""
    @State private var isGettingLocation = false
    @State private var errorMessage: String?
    @State private var appearAnimation = false
    private let timePhase = TimePhase.current()

    var body: some View {
        let isTablet = horizontalSizeClass == .regular

        NavigationView {
            ZStack {
                adaptiveBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        addLocationHeader
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)

                        // Form cards
                        VStack(spacing: 20) {
                            nameCard
                            methodCard

                            if !useCurrentLocation {
                                coordinatesCard
                            }

                            if let error = errorMessage {
                                errorCard(message: error)
                            }
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)

                        // Save button
                        saveButton
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 30)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .frame(maxWidth: isTablet ? 500 : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.adaptiveTextSecondary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("New Location")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.adaptiveText)
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

    // MARK: - Header (Adaptive)
    private var addLocationHeader: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk
        let accentColor = isNightMode ? Color(red: 0.55, green: 0.70, blue: 0.65) : Color.softSage

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.3),
                                (isNightMode ? Color.nightPurple : Color.dawnPeach).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(accentColor)
            }

            Text("Add a new place")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundColor(.adaptiveGradientText)
        }
        .padding(.top, 10)
    }

    // MARK: - Name Card (Adaptive)
    private var nameCard: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk

        return VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Location Name")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.adaptiveText)
            } icon: {
                Image(systemName: "textformat")
                    .font(.system(size: 14))
                    .foregroundColor(.adaptiveAccent)
            }

            TextField("e.g., Home, Beach House, Office", text: $locationName)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.adaptiveText)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isNightMode ? Color.white.opacity(0.08) : Color.dawnPeach.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isNightMode ? Color.white.opacity(0.15) : Color.dawnRose.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.adaptiveCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.adaptiveCardBorder, lineWidth: isNightMode ? 1 : 0)
                )
                .shadow(color: Color.adaptiveShadow, radius: 15, x: 0, y: 6)
        )
    }

    // MARK: - Method Card (Adaptive)
    private var methodCard: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk
        let locationColor = isNightMode ? Color(red: 0.55, green: 0.70, blue: 0.65) : Color.softSage
        let manualColor = isNightMode ? Color.moonGlow : Color.mistBlue

        return VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Location Method")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.adaptiveText)
            } icon: {
                Image(systemName: "location.viewfinder")
                    .font(.system(size: 14))
                    .foregroundColor(.adaptiveAccent)
            }

            // Toggle card
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    useCurrentLocation.toggle()
                }
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(useCurrentLocation ? locationColor.opacity(0.2) : (isNightMode ? Color.white.opacity(0.1) : Color.dawnLavender.opacity(0.3)))
                            .frame(width: 44, height: 44)

                        Image(systemName: useCurrentLocation ? "location.fill" : "keyboard")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(useCurrentLocation ? locationColor : manualColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(useCurrentLocation ? "Use Current Location" : "Enter Manually")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.adaptiveText)

                        Text(useCurrentLocation ? "We'll detect where you are now" : "Type in coordinates yourself")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.adaptiveTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.adaptiveTextSecondary.opacity(0.5))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isNightMode ? Color.white.opacity(0.05) : Color.dawnCream)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.adaptiveCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.adaptiveCardBorder, lineWidth: isNightMode ? 1 : 0)
                )
                .shadow(color: Color.adaptiveShadow, radius: 15, x: 0, y: 6)
        )
    }

    // MARK: - Coordinates Card (Adaptive)
    private var coordinatesCard: some View {
        let isNightMode = timePhase == .night || timePhase == .dusk

        return VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Coordinates")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.adaptiveText)
            } icon: {
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundColor(.adaptiveAccent)
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Text("Lat")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.adaptiveTextSecondary)
                        .frame(width: 30)

                    TextField("e.g., 40.7128", text: $manualLatitude)
                        .font(.system(size: 15, weight: .regular, design: .monospaced))
                        .foregroundColor(.adaptiveText)
                        .keyboardType(.decimalPad)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isNightMode ? Color.white.opacity(0.08) : Color.dawnPeach.opacity(0.15))
                        )
                }

                HStack(spacing: 12) {
                    Text("Lon")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.adaptiveTextSecondary)
                        .frame(width: 30)

                    TextField("e.g., -74.0060", text: $manualLongitude)
                        .font(.system(size: 15, weight: .regular, design: .monospaced))
                        .foregroundColor(.adaptiveText)
                        .keyboardType(.decimalPad)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isNightMode ? Color.white.opacity(0.08) : Color.dawnPeach.opacity(0.15))
                        )
                }
            }

            Text("Latitude: -90 to 90 • Longitude: -180 to 180")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.adaptiveTextSecondary.opacity(0.7))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.adaptiveCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.adaptiveCardBorder, lineWidth: isNightMode ? 1 : 0)
                )
                .shadow(color: Color.adaptiveShadow, radius: 15, x: 0, y: 6)
        )
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Error Card (Adaptive)
    private func errorCard(message: String) -> some View {
        let isNightMode = timePhase == .night || timePhase == .dusk

        return HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.adaptiveAccent)

            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.adaptiveText.opacity(0.8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isNightMode ? Color.adaptiveAccent.opacity(0.15) : Color.dawnRose.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.adaptiveAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveLocation) {
            HStack(spacing: 10) {
                if isGettingLocation {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                }
                Text(isGettingLocation ? "Getting Location..." : "Save Location")
            }
        }
        .buttonStyle(SoftButtonStyle(isPrimary: true))
        .disabled(locationName.isEmpty || isGettingLocation)
        .opacity(locationName.isEmpty ? 0.6 : 1)
        .padding(.top, 8)
    }

    // MARK: - Save Logic
    private func saveLocation() {
        errorMessage = nil

        guard !locationName.isEmpty else {
            errorMessage = "Please enter a location name"
            return
        }

        if useCurrentLocation {
            isGettingLocation = true
            viewModel.getCurrentLocation { result in
                isGettingLocation = false

                switch result {
                case .success(let coordinate):
                    let newLocation = SavedLocation(
                        name: locationName,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        isSelected: locationStore.savedLocations.isEmpty
                    )
                    locationStore.addLocation(newLocation)
                    if locationStore.savedLocations.count == 1 {
                        viewModel.updateSelectedLocation(newLocation)
                    }
                    dismiss()

                case .failure(let error):
                    errorMessage = "Failed to get location: \(error.localizedDescription)"
                }
            }
        } else {
            guard let lat = Double(manualLatitude), let lon = Double(manualLongitude),
                  lat >= -90, lat <= 90, lon >= -180, lon <= 180 else {
                errorMessage = "Please enter valid coordinates"
                return
            }

            let newLocation = SavedLocation(
                name: locationName,
                latitude: lat,
                longitude: lon,
                isSelected: locationStore.savedLocations.isEmpty
            )
            locationStore.addLocation(newLocation)
            if locationStore.savedLocations.count == 1 {
                viewModel.updateSelectedLocation(newLocation)
            }
            dismiss()
        }
    }
}

// MARK: - Previews
struct LocationManagementView_Previews: PreviewProvider {
    static var previews: some View {
        LocationManagementView()
            .environmentObject(LocationStore())
            .environmentObject(SunriseViewModel())
    }
}
