//
//  ImportView.swift
//  Pulsar
//
//  Activity import from files and connected services
//

import SwiftUI
import UniformTypeIdentifiers

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
            // Simulate parsing progress
            for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                try? await Task.sleep(for: .milliseconds(100))
                await MainActor.run {
                    importProgress = progress
                }
            }
            
            // Create preview
            let preview = ImportedActivityPreview(
                name: url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " "),
                type: .run,
                distanceMeters: 8543,
                durationSeconds: 2820,
                elevationGainMeters: 89,
                startDate: Date(),
                coordinates: SampleData.generateSampleRoute()
            )
            
            await MainActor.run {
                isImporting = false
                importedActivity = preview
                showActivityPreview = true
                HapticFeedback.notification(.success)
            }
        }
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
