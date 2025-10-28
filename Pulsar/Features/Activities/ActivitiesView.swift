//
//  ActivitiesView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftUI
import SwiftData
import MapKit

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Query(sort: \Activity.startDate, order: .reverse) private var activities: [Activity]
    
    @State private var showUpload = false
    
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
                    Button(action: { showUpload = true }) {
                        Image(systemName: "plus")
                    }
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
        .navigationDestination(for: Activity.self) { activity in
            ActivityDetailView(activity: activity)
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
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        return String(format: "%.2f km", km)
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

#Preview {
    ActivitiesView()
        .modelContainer(for: Activity.self, inMemory: true)
        .environment(AppState())
}

