//
//  FeedActivityDetailView.swift
//  Pulsar
//
//  Detailed view of a single feed activity with map, stats, and social
//

import MapKit
import SwiftUI

struct FeedActivityDetailView: View {
    let activity: ActivityData
    
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var commentText = ""
    @State private var comments: [CommentData] = []
    @State private var showAllStats = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Map
                    if activity.hasRoute {
                        FeedActivityRouteMapView(coordinates: activity.routeCoordinates)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
                    }
                    
                    // Activity Info
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Image(systemName: activity.type.icon)
                                    .font(.title3)
                                    .foregroundStyle(activity.type.color)
                                
                                Text(activity.type.displayName)
                                    .font(.labelLarge)
                                    .foregroundStyle(activity.type.color)
                                
                                Spacer()
                                
                                Text(activity.startDate, style: .date)
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textTertiary)
                            }
                            
                            Text(activity.name)
                                .font(.headlineLarge)
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        // User info
                        HStack(spacing: Spacing.sm) {
                            AsyncProfileImage(url: activity.userAvatarURL, size: 36)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.userName)
                                    .font(.headlineSmall)
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text(activity.relativeTime)
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textTertiary)
                            }
                            
                            Spacer()
                            
                            Button {
                                // Follow user
                            } label: {
                                Text("Follow")
                                    .font(.labelMedium)
                                    .foregroundStyle(Color.pulsarPrimary)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(Color.pulsarPrimary.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                            }
                        }
                        
                        Divider()
                        
                        // Primary Stats
                        HStack(spacing: Spacing.md) {
                            StatBlock(
                                title: "Distance",
                                value: activity.formattedDistance,
                                unit: "km"
                            )
                            
                            Divider()
                                .frame(height: 50)
                            
                            StatBlock(
                                title: "Time",
                                value: activity.formattedDuration,
                                unit: ""
                            )
                            
                            if let pace = activity.formattedPace {
                                Divider()
                                    .frame(height: 50)
                                
                                StatBlock(
                                    title: "Pace",
                                    value: pace,
                                    unit: "/km"
                                )
                            }
                            
                            if let elevation = activity.formattedElevation {
                                Divider()
                                    .frame(height: 50)
                                
                                StatBlock(
                                    title: "Elevation",
                                    value: elevation,
                                    unit: "m"
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Expandable detailed stats
                        DisclosureGroup(
                            isExpanded: $showAllStats,
                            content: {
                                DetailedStatsGrid(activity: activity)
                                    .padding(.top, Spacing.md)
                            },
                            label: {
                                HStack {
                                    Text("More Stats")
                                        .font(.headlineSmall)
                                        .foregroundStyle(Color.textPrimary)
                                    Spacer()
                                }
                            }
                        )
                        .tint(Color.textSecondary)
                        
                        Divider()
                        
                        // Social Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            // Kudos and comments count
                            HStack(spacing: Spacing.lg) {
                                HStack(spacing: Spacing.xxs) {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(Color.pulsarError)
                                    Text("\(activity.kudosCount) kudos")
                                        .foregroundStyle(Color.textSecondary)
                                }
                                
                                HStack(spacing: Spacing.xxs) {
                                    Image(systemName: "bubble.left.fill")
                                        .foregroundStyle(Color.textTertiary)
                                    Text("\(activity.commentsCount) comments")
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                            .font(.bodySmall)
                            
                            // Action buttons
                            HStack(spacing: Spacing.md) {
                                Button {
                                    HapticFeedback.impact(.light)
                                } label: {
                                    Label("Give Kudos", systemImage: "heart")
                                        .font(.headlineSmall)
                                        .foregroundStyle(Color.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.sm)
                                        .background(Color.elevatedBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                                }
                                
                                Button {
                                    showShareSheet = true
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .font(.headlineSmall)
                                        .foregroundStyle(Color.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.sm)
                                        .background(Color.elevatedBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                                }
                            }
                            
                            // Comments section
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Comments")
                                    .font(.headlineSmall)
                                
                                ForEach(comments) { comment in
                                    CommentRow(comment: comment)
                                }
                                
                                // Add comment
                                HStack(spacing: Spacing.sm) {
                                    TextField("Add a comment...", text: $commentText)
                                        .font(.bodyMedium)
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, Spacing.xs)
                                        .background(Color.elevatedBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                                    
                                    Button {
                                        sendComment()
                                    } label: {
                                        Image(systemName: "paperplane.fill")
                                            .foregroundStyle(commentText.isEmpty ? Color.textTertiary : Color.pulsarPrimary)
                                    }
                                    .disabled(commentText.isEmpty)
                                }
                            }
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .background(Color.cardBackground)
            .navigationTitle("Activity")
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            // Edit activity
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button {
                            // Export GPX
                        } label: {
                            Label("Export GPX", systemImage: "square.and.arrow.down")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            // Delete
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.bodyMedium)
                    }
                }
            }
        }
        .onAppear {
            loadComments()
        }
    }
    
    private func loadComments() {
        comments = [
            CommentData(
                id: UUID(),
                userName: "Alex R.",
                avatarURL: nil,
                content: "Great run! That pace is impressive!",
                timestamp: Date().addingTimeInterval(-1800)
            ),
            CommentData(
                id: UUID(),
                userName: "Jordan L.",
                avatarURL: nil,
                content: "Love that route through the park",
                timestamp: Date().addingTimeInterval(-3600)
            )
        ]
    }
    
    private func sendComment() {
        guard !commentText.isEmpty else { return }
        
        let newComment = CommentData(
            id: UUID(),
            userName: "You",
            avatarURL: nil,
            content: commentText,
            timestamp: Date()
        )
        
        withAnimation(.pulsarSpring) {
            comments.insert(newComment, at: 0)
        }
        
        commentText = ""
        HapticFeedback.impact(.light)
    }
}

// MARK: - Supporting Views

struct StatBlock: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.statMedium)
                    .foregroundStyle(Color.textPrimary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailedStatsGrid: View {
    let activity: ActivityData
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.md) {
            StatCard(title: "Avg Pace", value: activity.formattedPace ?? "--", unit: "/km", icon: "speedometer")
            StatCard(title: "Calories", value: "486", unit: "kcal", icon: "flame")
            StatCard(title: "Avg HR", value: "152", unit: "bpm", icon: "heart")
            StatCard(title: "Max HR", value: "178", unit: "bpm", icon: "heart.fill")
            StatCard(title: "Cadence", value: "172", unit: "spm", icon: "figure.run")
            StatCard(title: "Splits", value: "View", unit: "", icon: "chart.bar")
        }
    }
}

struct FeedActivityRouteMapView: View {
    let coordinates: [Coordinate]
    
    @State private var mapRegion: MKCoordinateRegion?
    
    var body: some View {
        Map {
            if !coordinates.isEmpty {
                MapPolyline(coordinates: coordinates.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                })
                .stroke(
                    LinearGradient.pulsarGradient,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
                
                // Start marker
                if let first = coordinates.first {
                    Annotation("Start", coordinate: CLLocationCoordinate2D(
                        latitude: first.latitude,
                        longitude: first.longitude
                    )) {
                        Circle()
                            .fill(Color.pulsarSuccess)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                
                // End marker
                if let last = coordinates.last, coordinates.count > 1 {
                    Annotation("End", coordinate: CLLocationCoordinate2D(
                        latitude: last.latitude,
                        longitude: last.longitude
                    )) {
                        Circle()
                            .fill(Color.pulsarError)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

struct CommentRow: View {
    let comment: CommentData
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            AsyncProfileImage(url: comment.avatarURL, size: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userName)
                        .font(.labelLarge)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(comment.relativeTime)
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                
                Text(comment.content)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.xxs)
    }
}

struct CommentData: Identifiable {
    let id: UUID
    let userName: String
    let avatarURL: URL?
    let content: String
    let timestamp: Date
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

#Preview {
    FeedActivityDetailView(activity: SampleData.activities[0])
}
