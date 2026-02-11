//
//  ImportView.swift
//  Pulsar
//
//  Activity import from files and connected services
//

import SwiftUI
import UniformTypeIdentifiers
import CoreLocation

// MARK: - GPX Parser

/// Parses GPX (GPS Exchange Format) files to extract track data
final class GPXParser: NSObject, XMLParserDelegate, @unchecked Sendable {
    
    struct ParsedGPX: Sendable {
        let name: String?
        let coordinates: [Coordinate]
        let startTime: Date?
        let endTime: Date?
        let distanceMeters: Double
        let elevationGainMeters: Double
        let durationSeconds: Int
    }
    
    enum ParseError: LocalizedError {
        case invalidData
        case parsingFailed(String)
        case noTrackPoints
        
        var errorDescription: String? {
            switch self {
            case .invalidData:
                return "The file does not contain valid GPX data"
            case .parsingFailed(let message):
                return "Failed to parse GPX: \(message)"
            case .noTrackPoints:
                return "No track points found in GPX file"
            }
        }
    }
    
    private var coordinates: [Coordinate] = []
    private var trackName: String?
    private var currentElement: String = ""
    private var currentLatitude: Double?
    private var currentLongitude: Double?
    private var currentElevation: Double?
    private var currentTime: Date?
    private var currentText: String = ""
    private var parseError: Error?
    
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    /// Parse GPX data from a URL
    func parse(url: URL) async throws -> ParsedGPX {
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw ParseError.invalidData
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let data = try Data(contentsOf: url)
        return try await parse(data: data)
    }
    
    /// Parse GPX data from raw bytes
    func parse(data: Data) async throws -> ParsedGPX {
        coordinates = []
        trackName = nil
        parseError = nil
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        let success = parser.parse()
        
        if let error = parseError {
            throw error
        }
        
        if !success {
            throw ParseError.parsingFailed(parser.parserError?.localizedDescription ?? "Unknown error")
        }
        
        guard !coordinates.isEmpty else {
            throw ParseError.noTrackPoints
        }
        
        // Calculate stats from parsed coordinates
        let stats = calculateStats(from: coordinates)
        
        return ParsedGPX(
            name: trackName,
            coordinates: coordinates,
            startTime: coordinates.first?.time,
            endTime: coordinates.last?.time,
            distanceMeters: stats.distance,
            elevationGainMeters: stats.elevationGain,
            durationSeconds: stats.duration
        )
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        currentText = ""
        
        if elementName == "trkpt" || elementName == "rtept" || elementName == "wpt" {
            // Track point, route point, or waypoint
            if let latStr = attributeDict["lat"], let lat = Double(latStr),
               let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                currentLatitude = lat
                currentLongitude = lon
            }
            currentElevation = nil
            currentTime = nil
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "name":
            // Only capture the track name, not segment or waypoint names
            if trackName == nil {
                trackName = trimmedText
            }
            
        case "ele":
            currentElevation = Double(trimmedText)
            
        case "time":
            currentTime = Self.iso8601Formatter.date(from: trimmedText) ?? Self.iso8601FormatterNoFraction.date(from: trimmedText)
            
        case "trkpt", "rtept":
            // End of a track or route point
            if let lat = currentLatitude, let lon = currentLongitude {
                let coord = Coordinate(
                    latitude: lat,
                    longitude: lon,
                    elevation: currentElevation,
                    time: currentTime
                )
                coordinates.append(coord)
            }
            currentLatitude = nil
            currentLongitude = nil
            currentElevation = nil
            currentTime = nil
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = ParseError.parsingFailed(parseError.localizedDescription)
    }
    
    // MARK: - Stats Calculation
    
    private struct TrackStats {
        let distance: Double
        let elevationGain: Double
        let duration: Int
    }
    
    private func calculateStats(from coordinates: [Coordinate]) -> TrackStats {
        var totalDistance: Double = 0
        var totalElevationGain: Double = 0
        
        for i in 1..<coordinates.count {
            let prev = coordinates[i - 1]
            let curr = coordinates[i]
            
            // Calculate distance using Haversine formula
            let distance = haversineDistance(
                lat1: prev.latitude, lon1: prev.longitude,
                lat2: curr.latitude, lon2: curr.longitude
            )
            totalDistance += distance
            
            // Calculate elevation gain (only positive changes)
            if let prevEle = prev.elevation, let currEle = curr.elevation {
                let elevationDiff = currEle - prevEle
                if elevationDiff > 0 {
                    totalElevationGain += elevationDiff
                }
            }
        }
        
        // Calculate duration from timestamps if available
        var duration: Int = 0
        if let startTime = coordinates.first?.time, let endTime = coordinates.last?.time {
            duration = Int(endTime.timeIntervalSince(startTime))
        }
        
        return TrackStats(
            distance: totalDistance,
            elevationGain: totalElevationGain,
            duration: duration
        )
    }
    
    /// Haversine formula to calculate distance between two coordinates in meters
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius: Double = 6371000 // meters
        
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showFilePicker = false
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @State private var importedActivity: ImportedActivityPreview?
    @State private var showActivityPreview = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.pulsarPrimary.opacity(0.15))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(Color.pulsarPrimary)
                        }
                        
                        Text("Import Activity")
                            .font(.displaySmall)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text("Import activities from files or connected services")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // Import options
                    VStack(spacing: Spacing.md) {
                        // File import
                        ImportOptionCard(
                            icon: "doc.badge.plus",
                            title: "Import File",
                            subtitle: "GPX, TCX, or FIT files",
                            color: .pulsarPrimary
                        ) {
                            showFilePicker = true
                        }
                        
                        // Health import
                        ImportOptionCard(
                            icon: "heart.fill",
                            title: "Apple Health",
                            subtitle: "Sync workouts from Health app",
                            color: .pulsarError
                        ) {
                            importFromHealth()
                        }
                        
                        // Manual entry
                        ImportOptionCard(
                            icon: "pencil.line",
                            title: "Manual Entry",
                            subtitle: "Log an activity manually",
                            color: .activityRide
                        ) {
                            // Show manual entry form
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    // Recent imports
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Recent Imports")
                            .font(.headlineMedium)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, Spacing.md)
                        
                        VStack(spacing: Spacing.xs) {
                            RecentImportRow(
                                name: "Morning_Run.gpx",
                                date: Date().addingTimeInterval(-86400),
                                status: .success
                            )
                            
                            RecentImportRow(
                                name: "Weekend_Ride.fit",
                                date: Date().addingTimeInterval(-172800),
                                status: .success
                            )
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    // Supported formats
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Supported Formats")
                            .font(.headlineMedium)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, Spacing.md)
                        
                        HStack(spacing: Spacing.md) {
                            FormatBadge(format: "GPX", description: "GPS Exchange")
                            FormatBadge(format: "TCX", description: "Training Center")
                            FormatBadge(format: "FIT", description: "Flexible & Interop")
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    Spacer(minLength: Spacing.xxxl)
                }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.bodyMedium)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [
                UTType(filenameExtension: "gpx") ?? .data,
                UTType(filenameExtension: "tcx") ?? .data,
                UTType(filenameExtension: "fit") ?? .data
            ],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showActivityPreview) {
            if let preview = importedActivity {
                ActivityPreviewView(preview: preview) {
                    saveActivity()
                }
            }
        }
        .alert("Import Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred during import")
        }
        .overlay {
            if isImporting {
                ImportProgressView(progress: importProgress)
            }
        }
    }
    
    // MARK: - Import Logic
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFile(url)
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func importFile(_ url: URL) {
        isImporting = true
        importProgress = 0
        
        Task {
            do {
                // Update progress - starting
                await MainActor.run { importProgress = 0.1 }
                
                // Determine file type and parse accordingly
                let fileExtension = url.pathExtension.lowercased()
                
                let preview: ImportedActivityPreview
                
                switch fileExtension {
                case "gpx":
                    preview = try await parseGPXFile(url)
                case "tcx":
                    // TCX parsing not yet implemented - show placeholder
                    preview = createPlaceholderPreview(from: url, fileType: "TCX")
                case "fit":
                    // FIT parsing not yet implemented - show placeholder
                    preview = createPlaceholderPreview(from: url, fileType: "FIT")
                default:
                    throw GPXParser.ParseError.invalidData
                }
                
                await MainActor.run {
                    importProgress = 1.0
                    isImporting = false
                    importedActivity = preview
                    showActivityPreview = true
                    HapticFeedback.notification(.success)
                }
                
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.notification(.error)
                }
            }
        }
    }
    
    private func parseGPXFile(_ url: URL) async throws -> ImportedActivityPreview {
        await MainActor.run { importProgress = 0.3 }
        
        let parser = GPXParser()
        let gpxData = try await parser.parse(url: url)
        
        await MainActor.run { importProgress = 0.7 }
        
        // Determine activity type based on filename or default to run
        let activityType = guessActivityType(from: url)
        
        // Use parsed name or fall back to filename
        let name = gpxData.name ?? url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
        
        await MainActor.run { importProgress = 0.9 }
        
        return ImportedActivityPreview(
            name: name,
            type: activityType,
            distanceMeters: gpxData.distanceMeters,
            durationSeconds: gpxData.durationSeconds,
            elevationGainMeters: gpxData.elevationGainMeters > 0 ? gpxData.elevationGainMeters : nil,
            startDate: gpxData.startTime ?? Date(),
            coordinates: gpxData.coordinates
        )
    }
    
    private func createPlaceholderPreview(from url: URL, fileType: String) -> ImportedActivityPreview {
        // For unsupported file types, create a placeholder until parsing is implemented
        ImportedActivityPreview(
            name: url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " "),
            type: .run,
            distanceMeters: 0,
            durationSeconds: 0,
            elevationGainMeters: nil,
            startDate: Date(),
            coordinates: []
        )
    }
    
    private func guessActivityType(from url: URL) -> ActivityType {
        let filename = url.lastPathComponent.lowercased()
        
        if filename.contains("run") || filename.contains("jog") {
            return .run
        } else if filename.contains("ride") || filename.contains("bike") || filename.contains("cycle") {
            return .ride
        } else if filename.contains("walk") {
            return .walk
        } else if filename.contains("hike") {
            return .hike
        } else if filename.contains("swim") {
            return .swim
        }
        
        return .run // Default to run
    }
    
    private func importFromHealth() {
        // In production, request HealthKit permissions and import
        HapticFeedback.impact(.light)
    }
    
    private func saveActivity() {
        dismiss()
        HapticFeedback.notification(.success)
    }
}

// MARK: - Supporting Views

struct ImportOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headlineSmall)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(subtitle)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}

struct RecentImportRow: View {
    let name: String
    let date: Date
    let status: ImportStatus
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: status == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(status == .success ? Color.pulsarSuccess : Color.pulsarError)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}

enum ImportStatus {
    case success
    case failed
}

struct FormatBadge: View {
    let format: String
    let description: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(format)
                .font(.labelLarge)
                .foregroundStyle(Color.textPrimary)
            
            Text(description)
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

struct ImportProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Importing...")
                    .font(.headlineSmall)
                    .foregroundStyle(.white)
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.pulsarPrimary)
                    .frame(width: 200)
                
                Text("\(Int(progress * 100))%")
                    .font(.labelMedium)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        }
    }
}

// MARK: - Activity Preview

struct ImportedActivityPreview {
    let name: String
    let type: ActivityType
    let distanceMeters: Double
    let durationSeconds: Int
    let elevationGainMeters: Double?
    let startDate: Date
    let coordinates: [Coordinate]
    
    var formattedDistance: String {
        String(format: "%.2f km", distanceMeters / 1000)
    }
    
    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        let seconds = durationSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct ActivityPreviewView: View {
    let preview: ImportedActivityPreview
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var activityName: String = ""
    @State private var activityType: ActivityType = .run
    @State private var visibility: Visibility = .publicVisible
    @State private var description: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Map preview
                    if !preview.coordinates.isEmpty {
                        RoutePreview(coordinates: preview.coordinates)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                            .padding(.horizontal, Spacing.md)
                    }
                    
                    // Stats
                    HStack(spacing: Spacing.sm) {
                        StatCard(title: "Distance", value: preview.formattedDistance, icon: "ruler", color: .pulsarPrimary)
                        StatCard(title: "Time", value: preview.formattedDuration, icon: "clock", color: .activityRide)
                        if let elevation = preview.elevationGainMeters {
                            StatCard(title: "Elevation", value: String(format: "%.0f m", elevation), icon: "arrow.up.right", color: .activityHike)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    // Form
                    VStack(spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Activity Name")
                                .font(.labelMedium)
                                .foregroundStyle(Color.textSecondary)
                            
                            TextField("Name your activity", text: $activityName)
                                .font(.bodyMedium)
                                .padding(Spacing.sm)
                                .background(Color.elevatedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Activity Type")
                                .font(.labelMedium)
                                .foregroundStyle(Color.textSecondary)
                            
                            Picker("Type", selection: $activityType) {
                                ForEach(ActivityType.allCases, id: \.self) { type in
                                    Label(type.displayName, systemImage: type.icon).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(Spacing.sm)
                            .background(Color.elevatedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Visibility")
                                .font(.labelMedium)
                                .foregroundStyle(Color.textSecondary)
                            
                            Picker("Visibility", selection: $visibility) {
                                ForEach(Visibility.allCases, id: \.self) { vis in
                                    Label(vis.displayName, systemImage: vis.icon).tag(vis)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(Spacing.sm)
                            .background(Color.elevatedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Description (optional)")
                                .font(.labelMedium)
                                .foregroundStyle(Color.textSecondary)
                            
                            TextField("How was your activity?", text: $description, axis: .vertical)
                                .lineLimit(3...5)
                                .font(.bodyMedium)
                                .padding(Spacing.sm)
                                .background(Color.elevatedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    // Save button
                    PrimaryButton("Save Activity", icon: "checkmark") {
                        onSave()
                        dismiss()
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    Spacer(minLength: Spacing.xxxl)
                }
                .padding(.top, Spacing.md)
            }
            .navigationTitle("Review Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            activityName = preview.name
            activityType = preview.type
        }
    }
}

#Preview {
    ImportView()
}
