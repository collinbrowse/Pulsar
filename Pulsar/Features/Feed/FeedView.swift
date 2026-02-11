//
//  FeedView.swift
//  Pulsar
//
//  Social activity feed showing followed users' activities
//

import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    @State private var activities: [ActivityData] = []
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var selectedActivity: ActivityData?
    @State private var showActivityDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading && activities.isEmpty {
                    LoadingView("Loading feed...")
                } else if activities.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.stack",
                        title: "No Activities Yet",
                        message: "Follow athletes or import your first activity to get started.",
                        actionTitle: "Import Activity"
                    ) {
                        // Trigger import
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(activities) { activity in
                                ActivityCard(
                                    activity: activity,
                                    onTap: {
                                        selectedActivity = activity
                                        showActivityDetail = true
                                    },
                                    onKudos: {
                                        toggleKudos(for: activity)
                                    },
                                    onComment: {
                                        selectedActivity = activity
                                        showActivityDetail = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.xxxl)
                    }
                    .refreshable {
                        await refreshFeed()
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Notifications
                    } label: {
                        Image(systemName: "bell")
                            .font(.bodyMedium)
                    }
                }
            }
        }
        .task {
            await loadFeed()
        }
        .sheet(isPresented: $showActivityDetail) {
            if let activity = selectedActivity {
                ActivityDetailView(activity: activity)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadFeed() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = appState.currentUserID, let token = appState.accessToken else {
            activities = []
            return
        }
        
        do {
            let rows: [FeedItemRow] = try await SupabaseClient.shared.rpc(
                name: "get_user_feed",
                params: ["p_user_id": userId, "p_limit": 50, "p_offset": 0],
                accessToken: token,
                schema: "app"
            )
            activities = rows.map { $0.toActivityData() }
        } catch {
            activities = []
        }
    }
    
    private func refreshFeed() async {
        isRefreshing = true
        HapticFeedback.impact(.light)
        await loadFeed()
        isRefreshing = false
    }
    
    private func toggleKudos(for activity: ActivityData) {
        HapticFeedback.impact(.light)
        
        withAnimation(.pulsarSpring) {
            activities = FeedFlow.toggleKudos(
                activities: activities,
                for: activity.id
            )
        }
    }
}

// MARK: - Sample Data

enum SampleData {
    static let activities: [ActivityData] = [
        ActivityData(
            id: UUID(),
            name: "Morning Run through Golden Gate Park",
            type: .run,
            userName: "Sarah Chen",
            userAvatarURL: nil,
            distanceMeters: 8543,
            durationSeconds: 2820,
            elevationGainMeters: 89,
            paceSecondsPerKm: 330,
            startDate: Date().addingTimeInterval(-3600),
            routeCoordinates: generateSampleRoute(),
            kudosCount: 24,
            commentsCount: 3,
            hasKudos: false
        ),
        ActivityData(
            id: UUID(),
            name: "Sunset Ride on the Coast",
            type: .ride,
            userName: "Marcus Johnson",
            userAvatarURL: nil,
            distanceMeters: 42500,
            durationSeconds: 5400,
            elevationGainMeters: 456,
            paceSecondsPerKm: nil,
            startDate: Date().addingTimeInterval(-7200),
            routeCoordinates: generateSampleRoute(),
            kudosCount: 67,
            commentsCount: 8,
            hasKudos: true
        ),
        ActivityData(
            id: UUID(),
            name: "Lunchtime Swim",
            type: .swim,
            userName: "Emma Wilson",
            userAvatarURL: nil,
            distanceMeters: 2000,
            durationSeconds: 2400,
            elevationGainMeters: nil,
            paceSecondsPerKm: nil,
            startDate: Date().addingTimeInterval(-14400),
            routeCoordinates: [],
            kudosCount: 15,
            commentsCount: 2,
            hasKudos: false
        ),
        ActivityData(
            id: UUID(),
            name: "Mt. Tamalpais Summit Hike",
            type: .hike,
            userName: "Alex Rivera",
            userAvatarURL: nil,
            distanceMeters: 14200,
            durationSeconds: 14400,
            elevationGainMeters: 823,
            paceSecondsPerKm: 1014,
            startDate: Date().addingTimeInterval(-86400),
            routeCoordinates: generateSampleRoute(),
            kudosCount: 89,
            commentsCount: 12,
            hasKudos: true
        ),
        ActivityData(
            id: UUID(),
            name: "Recovery Walk",
            type: .walk,
            userName: "Jordan Lee",
            userAvatarURL: nil,
            distanceMeters: 3200,
            durationSeconds: 2100,
            elevationGainMeters: 32,
            paceSecondsPerKm: 656,
            startDate: Date().addingTimeInterval(-172800),
            routeCoordinates: generateSampleRoute(),
            kudosCount: 8,
            commentsCount: 1,
            hasKudos: false
        )
    ]
    
    static func generateSampleRoute() -> [Coordinate] {
        // Generate a simple random route for demo
        let baseLat = 37.7749 + Double.random(in: -0.05...0.05)
        let baseLon = -122.4194 + Double.random(in: -0.05...0.05)
        
        var coords: [Coordinate] = []
        var lat = baseLat
        var lon = baseLon
        
        for _ in 0..<50 {
            coords.append(Coordinate(latitude: lat, longitude: lon))
            lat += Double.random(in: -0.002...0.002)
            lon += Double.random(in: -0.002...0.002)
        }
        
        return coords
    }
}

#Preview {
    FeedView()
        .environment(AppState())
}
