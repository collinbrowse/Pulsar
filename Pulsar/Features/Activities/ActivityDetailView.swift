//
//  ActivityDetailView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftUI
import MapKit

struct ActivityDetailView: View {
    let activity: Activity
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: activity.activityType.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text(activity.name)
                        .font(.title.bold())
                    
                    Text(activity.startDate.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Map Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay {
                        VStack {
                            Image(systemName: "map.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Route map will appear here")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(title: "Distance", value: formatDistance(activity.distance), icon: "location.fill")
                    StatCard(title: "Duration", value: formatDuration(activity.duration), icon: "clock.fill")
                    
                    if let avgSpeed = activity.avgSpeed {
                        StatCard(title: "Avg Speed", value: formatSpeed(avgSpeed), icon: "speedometer")
                    }
                    
                    if let elevation = activity.elevationGain {
                        StatCard(title: "Elevation", value: formatElevation(elevation), icon: "arrow.up.right")
                    }
                    
                    if let avgHR = activity.avgHeartRate {
                        StatCard(title: "Avg HR", value: "\(avgHR) bpm", icon: "heart.fill")
                    }
                    
                    if let avgPower = activity.avgPower {
                        StatCard(title: "Avg Power", value: "\(Int(avgPower))w", icon: "bolt.fill")
                    }
                }
                .padding(.horizontal)
                
                // Source Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Details")
                        .font(.headline)
                    
                    DetailRow(label: "Source", value: activity.source.displayName)
                    if let fileName = activity.originalFileName {
                        DetailRow(label: "File", value: fileName)
                    }
                    DetailRow(label: "Type", value: activity.activityType.displayName)
                    DetailRow(label: "Privacy", value: activity.isPrivate ? "Private" : "Public")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helpers
    
    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        return String(format: "%.2f km", km)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func formatSpeed(_ metersPerSecond: Double) -> String {
        let kmh = metersPerSecond * 3.6
        return String(format: "%.1f km/h", kmh)
    }
    
    private func formatElevation(_ meters: Double) -> String {
        return String(format: "%.0f m", meters)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        ActivityDetailView(activity: Activity(
            userID: "test",
            name: "Morning Run",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        ))
    }
}

