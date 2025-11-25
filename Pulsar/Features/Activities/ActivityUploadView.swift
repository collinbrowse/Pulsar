//
//  ActivityUploadView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ActivityUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @State private var isImporting = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var importedActivity: Activity?
    
    private let activityService = ActivityService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Upload Activity")
                        .font(.title2.bold())
                    
                    Text("Import your workout from GPX, TCX, or FIT files")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Upload Options
                VStack(spacing: 16) {
                    // File Upload Button
                    Button(action: { isImporting = true }) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text("Choose File")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("Choose File")
                    
                    // HealthKit Import Button
                    Button(action: importFromHealthKit) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Import from Apple Health")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("Import from Apple Health")
                    
                    // Coming Soon: Strava
                    HStack {
                        Image(systemName: "link.circle.fill")
                        Text("Connect Strava")
                            .font(.headline)
                        Spacer()
                        Text("Coming Soon")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                
                // Error Message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }
                
                // Processing Indicator
                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Processing activity...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Supported Formats
                VStack(spacing: 8) {
                    Text("Supported Formats")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        FormatBadge(name: "GPX")
                        FormatBadge(name: "TCX")
                        FormatBadge(name: "FIT")
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [
                    UTType(filenameExtension: "gpx")!,
                    UTType(filenameExtension: "tcx")!,
                    UTType(filenameExtension: "fit")!
                ],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Activity Imported!", isPresented: $showSuccess) {
                Button("View Activity") {
                    // TODO: Navigate to activity detail
                    dismiss()
                }
                Button("Upload Another") {
                    showSuccess = false
                    errorMessage = nil
                }
                Button("Done") {
                    dismiss()
                }
            } message: {
                if let activity = importedActivity {
                    Text("\(activity.name) was successfully imported!")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        errorMessage = nil
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            processFile(url)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func processFile(_ url: URL) {
        guard let userId = appState.currentUserId else {
            errorMessage = "You must be signed in to upload activities"
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    throw ActivityServiceError.invalidFileData
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Parse the activity
                let activity = try await activityService.parseActivityFile(from: url, userId: userId)
                
                // Save to SwiftData
                try await activityService.saveActivity(activity, modelContext: modelContext)
                
                await MainActor.run {
                    importedActivity = activity
                    isProcessing = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    private func importFromHealthKit() {
        // TODO: Implement HealthKit import in next step
        errorMessage = "HealthKit import coming soon!"
    }
}

// MARK: - Supporting Views

struct FormatBadge: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.caption2.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }
}

#Preview {
    ActivityUploadView()
        .modelContainer(for: Activity.self, inMemory: true)
        .environment(AppState())
}
