//
//  SegmentsView.swift
//  Pulsar
//
//  Segment discovery and leaderboards
//

import SwiftUI
import MapKit

struct SegmentsView: View {
    @Environment(AppState.self) private var appState
    
    @State private var searchText = ""
    @State private var selectedTab: SegmentTab = .explore
    @State private var segments: [SegmentData] = []
    @State private var selectedSegment: SegmentData?
    @State private var showSegmentDetail = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("", selection: $selectedTab) {
                    ForEach(SegmentTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search segments...")
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                
                // Content
                if isLoading {
                    LoadingView("Loading segments...")
                } else if filteredSegments.isEmpty {
                    EmptyStateView(
                        icon: "flag",
                        title: "No Segments Found",
                        message: selectedTab == .starred ?
                            "Star segments to save them here." :
                            "Segments will appear as you record activities."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(filteredSegments) { segment in
                                SegmentRow(segment: segment) {
                                    selectedSegment = segment
                                    showSegmentDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.xxxl)
                    }
                }
            }
            .navigationTitle("Segments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Filter options
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
        }
        .task {
            await loadSegments()
        }
        .sheet(isPresented: $showSegmentDetail) {
            if let segment = selectedSegment {
                SegmentDetailView(segment: segment)
            }
        }
    }
    
    private var filteredSegments: [SegmentData] {
        SegmentsFlow.filteredSegments(
            segments: segments,
            tab: selectedTab,
            searchText: searchText
        )
    }
    
    private func loadSegments() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let token = appState.accessToken else {
            segments = []
            return
        }
        
        do {
            let rows: [SegmentRowDTO] = try await SupabaseClient.shared.fetch(
                from: "segments",
                select: "segment_id,name,activity_type,distance_m,elevation_gain_m,city,state,country,effort_count,star_count,created_by",
                filter: [:],
                accessToken: token,
                schema: "app"
            )
            let currentUserID = appState.currentUserID
            segments = rows.map { $0.toSegmentData(currentUserID: currentUserID) }
        } catch {
            segments = []
        }
    }
}

// MARK: - Segment Tab

enum SegmentTab: String, CaseIterable {
    case explore = "explore"
    case starred = "starred"
    case mySegments = "my"
    
    var title: String {
        switch self {
        case .explore: return "Explore"
        case .starred: return "Starred"
        case .mySegments: return "My Segments"
        }
    }
}

// MARK: - Segment Row

struct SegmentRow: View {
    let segment: SegmentData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                // Mini map preview
                RoutePreview(coordinates: segment.coordinates)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                
                // Segment info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Image(systemName: segment.type.icon)
                            .font(.caption)
                            .foregroundStyle(segment.type.color)
                        
                        Text(segment.name)
                            .font(.headlineSmall)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)
                    }
                    
                    if let city = segment.city {
                        Text(city)
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    HStack(spacing: Spacing.sm) {
                        Label(segment.formattedDistance, systemImage: "ruler")
                        
                        if let grade = segment.avgGradePercent {
                            Label(String(format: "%.1f%%", grade), systemImage: "arrow.up.right")
                        }
                        
                        Label("\(segment.effortCount)", systemImage: "person.2")
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
                    
                    // Leaderboard preview
                    if let kom = segment.komTime {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "FFD700"))
                            
                            Text("KOM: \(formatTime(kom))")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Star button
                VStack {
                    Button {
                        HapticFeedback.impact(.light)
                    } label: {
                        Image(systemName: segment.isStarred ? "star.fill" : "star")
                            .foregroundStyle(segment.isStarred ? Color.pulsarWarning : Color.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .padding(Spacing.sm)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Segment Detail View

struct SegmentDetailView: View {
    let segment: SegmentData
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: LeaderboardFilter = .overall
    @State private var leaderboard: [LeaderboardEntry] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Map
                    RoutePreview(coordinates: segment.coordinates)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                        .padding(.horizontal, Spacing.md)
                    
                    // Segment info
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Image(systemName: segment.type.icon)
                                .foregroundStyle(segment.type.color)
                            
                            Text(segment.type.displayName)
                                .font(.labelMedium)
                                .foregroundStyle(segment.type.color)
                            
                            Spacer()
                            
                            Button {
                                HapticFeedback.impact(.light)
                            } label: {
                                Image(systemName: segment.isStarred ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundStyle(segment.isStarred ? Color.pulsarWarning : Color.textTertiary)
                            }
                        }
                        
                        Text(segment.name)
                            .font(.headlineLarge)
                            .foregroundStyle(Color.textPrimary)
                        
                        if let city = segment.city {
                            Text(city)
                                .font(.bodyMedium)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    // Stats
                    HStack(spacing: Spacing.sm) {
                        StatCard(
                            title: "Distance",
                            value: segment.formattedDistance,
                            unit: "",
                            icon: "ruler",
                            color: .pulsarPrimary
                        )
                        
                        if let grade = segment.avgGradePercent {
                            StatCard(
                                title: "Avg Grade",
                                value: String(format: "%.1f", grade),
                                unit: "%",
                                icon: "arrow.up.right",
                                color: .activityHike
                            )
                        }
                        
                        if let elevation = segment.elevationGainMeters {
                            StatCard(
                                title: "Elevation",
                                value: String(format: "%.0f", elevation),
                                unit: "m",
                                icon: "mountain.2",
                                color: .activityRide
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    Divider()
                        .padding(.horizontal, Spacing.md)
                    
                    // Leaderboard
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Leaderboard")
                            .font(.headlineMedium)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, Spacing.md)
                        
                        // Filter pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(LeaderboardFilter.allCases, id: \.self) { filter in
                                    LeaderboardFilterPill(
                                        filter: filter,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        withAnimation(.pulsarSpring) {
                                            selectedFilter = filter
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                        
                        // Leaderboard entries
                        VStack(spacing: 0) {
                            ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRow(
                                    rank: index + 1,
                                    name: entry.userName,
                                    avatarURL: nil,
                                    value: formatTime(entry.elapsedTimeSeconds),
                                    isCurrentUser: entry.isCurrentUser,
                                    isPR: entry.isPR
                                )
                                
                                if index < leaderboard.count - 1 {
                                    Divider()
                                        .padding(.horizontal, Spacing.sm)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
            }
            .navigationTitle("Segment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Share
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .onAppear {
            loadLeaderboard()
        }
    }
    
    private func loadLeaderboard() {
        leaderboard = [
            LeaderboardEntry(id: UUID(), userName: "Alex Martinez", elapsedTimeSeconds: 342, isPR: false, isCurrentUser: false),
            LeaderboardEntry(id: UUID(), userName: "Sarah Chen", elapsedTimeSeconds: 356, isPR: false, isCurrentUser: false),
            LeaderboardEntry(id: UUID(), userName: "Marcus Johnson", elapsedTimeSeconds: 361, isPR: false, isCurrentUser: false),
            LeaderboardEntry(id: UUID(), userName: "You", elapsedTimeSeconds: 389, isPR: true, isCurrentUser: true),
            LeaderboardEntry(id: UUID(), userName: "Jordan Lee", elapsedTimeSeconds: 402, isPR: false, isCurrentUser: false),
            LeaderboardEntry(id: UUID(), userName: "Emma Wilson", elapsedTimeSeconds: 415, isPR: false, isCurrentUser: false),
            LeaderboardEntry(id: UUID(), userName: "Chris Park", elapsedTimeSeconds: 428, isPR: false, isCurrentUser: false),
            LeaderboardEntry(id: UUID(), userName: "Taylor Swift", elapsedTimeSeconds: 445, isPR: false, isCurrentUser: false),
        ]
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Leaderboard Filter

enum LeaderboardFilter: String, CaseIterable {
    case overall = "overall"
    case thisYear = "year"
    case female = "female"
    case male = "male"
    case following = "following"
    
    var title: String {
        switch self {
        case .overall: return "Overall"
        case .thisYear: return "This Year"
        case .female: return "Women"
        case .male: return "Men"
        case .following: return "Following"
        }
    }
}

struct LeaderboardFilterPill: View {
    let filter: LeaderboardFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter.title)
                .font(.labelMedium)
                .foregroundStyle(isSelected ? .white : Color.textSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.pulsarPrimary : Color.elevatedBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let id: UUID
    let userName: String
    let elapsedTimeSeconds: Int
    let isPR: Bool
    let isCurrentUser: Bool
}

// MARK: - Sample Segment Data

struct SegmentData: Identifiable {
    let id: UUID
    let name: String
    let type: ActivityType
    let distanceMeters: Double
    let avgGradePercent: Double?
    let elevationGainMeters: Double?
    let city: String?
    let coordinates: [Coordinate]
    let effortCount: Int
    let starCount: Int
    var isStarred: Bool
    var isCreatedByMe: Bool
    let komTime: Int?
    let qomTime: Int?
    
    var formattedDistance: String {
        String(format: "%.2f km", distanceMeters / 1000)
    }
}

enum SampleSegmentData {
    static let segments: [SegmentData] = [
        SegmentData(
            id: UUID(),
            name: "Golden Gate Bridge Run",
            type: .run,
            distanceMeters: 2743,
            avgGradePercent: 2.1,
            elevationGainMeters: 58,
            city: "San Francisco, CA",
            coordinates: SampleData.generateSampleRoute(),
            effortCount: 12453,
            starCount: 892,
            isStarred: true,
            isCreatedByMe: false,
            komTime: 456,
            qomTime: 512
        ),
        SegmentData(
            id: UUID(),
            name: "Hawk Hill Climb",
            type: .ride,
            distanceMeters: 3200,
            avgGradePercent: 8.5,
            elevationGainMeters: 272,
            city: "Marin County, CA",
            coordinates: SampleData.generateSampleRoute(),
            effortCount: 45678,
            starCount: 3245,
            isStarred: false,
            isCreatedByMe: false,
            komTime: 678,
            qomTime: 789
        ),
        SegmentData(
            id: UUID(),
            name: "Embarcadero Sprint",
            type: .run,
            distanceMeters: 800,
            avgGradePercent: 0.2,
            elevationGainMeters: 2,
            city: "San Francisco, CA",
            coordinates: SampleData.generateSampleRoute(),
            effortCount: 8932,
            starCount: 456,
            isStarred: true,
            isCreatedByMe: true,
            komTime: 142,
            qomTime: 168
        ),
        SegmentData(
            id: UUID(),
            name: "Land's End Trail",
            type: .hike,
            distanceMeters: 4800,
            avgGradePercent: 4.2,
            elevationGainMeters: 201,
            city: "San Francisco, CA",
            coordinates: SampleData.generateSampleRoute(),
            effortCount: 5621,
            starCount: 1234,
            isStarred: false,
            isCreatedByMe: false,
            komTime: 1845,
            qomTime: 2012
        )
    ]
}

#Preview {
    SegmentsView()
        .environment(AppState())
}
