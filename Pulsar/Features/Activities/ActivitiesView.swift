//
//  ActivitiesView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import MapKit
import SwiftData
import SwiftUI

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Query(sort: \Activity.startDate, order: .reverse) private var activities: [Activity]
    
    @State private var showUpload = false
    @State private var isSyncing = false
    
    var body: some View {
        NavigationStack {
            Group {
                if activities.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
            .navigationTitle("Activities")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showUpload = true }, label: {
                        Image(systemName: "plus")
                    })
                    .accessibilityIdentifier("Upload Activity")
                }
            }
            .sheet(isPresented: $showUpload) {
                ActivityUploadView()
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Activities", systemImage: "figure.run.circle")
        } description: {
            Text("Upload your first activity to get started")
        } actions: {
            Button("Upload Activity") {
                showUpload = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var activityList: some View {
        List {
            ForEach(activities) { activity in
                NavigationLink(value: activity) {
                    ActivityRow(activity: activity)
                }
            }
            .onDelete(perform: deleteActivities)
        }
        .refreshable {
            await syncActivities()
        }
        .navigationDestination(for: Activity.self) { activity in
            ActivityDetailViewWithLoading(activity: activity)
        }
    }
    
    private func syncActivities() async {
        guard let userId = appState.currentUserId else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try await ActivityService.shared.syncActivitiesFromBackend(
                for: userId,
                modelContext: modelContext
            )
        } catch {
            // Silently fail - user can retry
            print("Failed to sync activities: \(error.localizedDescription)")
        }
    }
    
    private func deleteActivities(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let activity = activities[index]
                try? await ActivityService.shared.deleteActivity(activity, modelContext: modelContext)
            }
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: Activity
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var useMetric: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Activity Icon
            Image(systemName: activity.activityType.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            // Activity Info
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label(formatDistance(activity.distance), systemImage: "location.fill")
                    Label(formatDuration(activity.duration), systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Text(activity.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .onAppear {
            updateMetricPreference()
        }
    }
    
    private func updateMetricPreference() {
        guard let userId = appState.currentUserId else {
            useMetric = false
            return
        }
        
        let descriptor = FetchDescriptor<Profile>(
            predicate: #Predicate<Profile> { profile in
                profile.userId == userId
            }
        )
        
        if let profile = try? modelContext.fetch(descriptor).first {
            useMetric = profile.useMetricUnits
        } else {
            useMetric = false
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        UnitFormatter.shared.formatDistance(meters, useMetric: useMetric)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Activity Detail View With Loading

struct ActivityDetailViewWithLoading: View {
    let activity: Activity
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task {
                        // Small delay to show loading indicator
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        isLoading = false
                    }
            } else {
                ActivityDetailView(activity: activity)
            }
        }
    }
}

#Preview {
    ActivitiesView()
        .modelContainer(for: Activity.self, inMemory: true)
        .environment(AppState())
}
