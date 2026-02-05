//
//  ProfileView.swift
//  Pulsar
//
//  User profile with stats and activity history
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    
    @State private var selectedTimeRange: TimeRange = .allTime
    @State private var selectedActivityType: ActivityType? = nil
    @State private var activities: [ActivityData] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Profile Header
                    ProfileHeader(
                        name: appState.userProfile?.fullName ?? "Athlete",
                        username: appState.userProfile?.username ?? "@athlete",
                        avatarURL: nil,
                        followersCount: 128,
                        followingCount: 94,
                        activitiesCount: activities.count
                    )
                    .padding(.horizontal, Spacing.md)
                    
                    // Stats Summary
                    StatsSummary(
                        totalDistance: totalDistance,
                        totalTime: totalTime,
                        totalElevation: totalElevation,
                        totalActivities: activities.count
                    )
                    .padding(.horizontal, Spacing.md)
                    
                    // Time Range Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                TimeRangePill(
                                    title: range.displayName,
                                    isSelected: selectedTimeRange == range
                                ) {
                                    withAnimation(.pulsarSpring) {
                                        selectedTimeRange = range
                                    }
                                    HapticFeedback.selection()
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    // Activity Type Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ActivityTypePill(
                                type: nil,
                                isSelected: selectedActivityType == nil
                            ) {
                                withAnimation(.pulsarSpring) {
                                    selectedActivityType = nil
                                }
                            }
                            
                            ForEach(ActivityType.allCases.filter { $0 != .other }, id: \.self) { type in
                                ActivityTypePill(
                                    type: type,
                                    isSelected: selectedActivityType == type
                                ) {
                                    withAnimation(.pulsarSpring) {
                                        selectedActivityType = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    // Activity History
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Recent Activities")
                            .font(.headlineMedium)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, Spacing.md)
                        
                        if filteredActivities.isEmpty {
                            EmptyStateView(
                                icon: "figure.run",
                                title: "No Activities",
                                message: "Activities will appear here once you import them."
                            )
                            .frame(height: 200)
                        } else {
                            LazyVStack(spacing: Spacing.sm) {
                                ForEach(filteredActivities) { activity in
                                    ProfileActivityRow(activity: activity)
                                        .padding(.horizontal, Spacing.md)
                                }
                            }
                        }
                    }
                }
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        Text("Edit")
                            .font(.bodyMedium)
                    }
                }
            }
        }
        .task {
            await loadActivities()
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredActivities: [ActivityData] {
        ProfileAnalytics.filteredActivities(
            activities,
            type: selectedActivityType
        )
    }
    
    private var totalDistance: Double {
        ProfileAnalytics.totalDistance(for: filteredActivities)
    }
    
    private var totalTime: Int {
        ProfileAnalytics.totalTime(for: filteredActivities)
    }
    
    private var totalElevation: Double {
        ProfileAnalytics.totalElevation(for: filteredActivities)
    }
    
    // MARK: - Data Loading
    
    private func loadActivities() async {
        isLoading = true
        try? await Task.sleep(for: .milliseconds(300))
        activities = SampleData.activities
        isLoading = false
    }
}

// MARK: - Supporting Views

struct ProfileHeader: View {
    let name: String
    let username: String
    let avatarURL: URL?
    let followersCount: Int
    let followingCount: Int
    let activitiesCount: Int
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AsyncProfileImage(url: avatarURL, size: 100)
                
                Circle()
                    .fill(Color.pulsarPrimary)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
            }
            
            // Name and username
            VStack(spacing: 4) {
                Text(name)
                    .font(.headlineLarge)
                    .foregroundStyle(Color.textPrimary)
                
                Text(username)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }
            
            // Social stats
            HStack(spacing: Spacing.xxl) {
                ProfileStat(value: "\(followersCount)", label: "Followers")
                ProfileStat(value: "\(followingCount)", label: "Following")
                ProfileStat(value: "\(activitiesCount)", label: "Activities")
            }
        }
        .padding(.vertical, Spacing.md)
    }
}

struct ProfileStat: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.statSmall)
                .foregroundStyle(Color.textPrimary)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
        }
    }
}

struct StatsSummary: View {
    let totalDistance: Double
    let totalTime: Int
    let totalElevation: Double
    let totalActivities: Int
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                StatCard(
                    title: "Distance",
                    value: String(format: "%.1f", totalDistance / 1000),
                    unit: "km",
                    icon: "ruler",
                    color: .pulsarPrimary
                )
                
                StatCard(
                    title: "Time",
                    value: formatDuration(totalTime),
                    unit: "",
                    icon: "clock",
                    color: .activityRide
                )
            }
            
            HStack(spacing: Spacing.sm) {
                StatCard(
                    title: "Elevation",
                    value: String(format: "%.0f", totalElevation),
                    unit: "m",
                    icon: "arrow.up.right",
                    color: .activityHike
                )
                
                StatCard(
                    title: "Activities",
                    value: "\(totalActivities)",
                    unit: "",
                    icon: "flame",
                    color: .activitySwim
                )
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct TimeRangePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.labelMedium)
                .foregroundStyle(isSelected ? .white : Color.textSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.pulsarPrimary : Color.elevatedBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
        }
    }
}

struct ActivityTypePill: View {
    let type: ActivityType?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                if let type = type {
                    Image(systemName: type.icon)
                        .font(.caption)
                }
                Text(type?.displayName ?? "All")
                    .font(.labelMedium)
            }
            .foregroundStyle(isSelected ? .white : Color.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? (type?.color ?? Color.pulsarPrimary) : Color.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
        }
    }
}

struct ProfileActivityRow: View {
    let activity: ActivityData
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Activity type icon
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: activity.type.icon)
                    .font(.bodyMedium)
                    .foregroundStyle(activity.type.color)
            }
            
            // Activity info
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headlineSmall)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: Spacing.xs) {
                    Text(activity.startDate, style: .date)
                    Text("•")
                    Text(activity.formattedDistance)
                    Text("•")
                    Text(activity.formattedDuration)
                }
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(Spacing.sm)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .cardShadow()
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case year = "year"
    case allTime = "all"
    
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        case .allTime: return "All Time"
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var fullName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var location = ""
    @State private var selectedGender: Gender = .preferNotToSay
    @State private var birthYear = 1990
    @State private var weightKg = 70.0
    
    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Full Name", text: $fullName)
                TextField("Username", text: $username)
                TextField("Bio", text: $bio, axis: .vertical)
                    .lineLimit(3...5)
                TextField("Location", text: $location)
            }
            
            Section("Personal Details") {
                Picker("Gender", selection: $selectedGender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                
                Picker("Birth Year", selection: $birthYear) {
                    ForEach((1940...2010).reversed(), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                
                HStack {
                    Text("Weight")
                    Spacer()
                    Text("\(Int(weightKg)) kg")
                        .foregroundStyle(Color.textSecondary)
                }
                Slider(value: $weightKg, in: 40...150, step: 1)
            }
            
            Section("Privacy") {
                Toggle("Private Account", isOn: .constant(false))
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    // Save profile
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
