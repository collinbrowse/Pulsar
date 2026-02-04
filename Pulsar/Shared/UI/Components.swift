//
//  Components.swift
//  Pulsar
//
//  Reusable UI Components
//

import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.headlineMedium)
                    }
                    Text(title)
                        .font(.headlineMedium)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LinearGradient.pulsarGradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .cardShadow()
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.8 : 1)
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headlineMedium)
                }
                Text(title)
                    .font(.headlineMedium)
            }
            .foregroundStyle(Color.gradientStart)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.gradientStart.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void
    
    init(
        icon: String,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: size, height: size)
                .background(Color.elevatedBackground)
                .clipShape(Circle())
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String?
    let color: Color
    
    init(
        title: String,
        value: String,
        unit: String? = nil,
        icon: String? = nil,
        color: Color = .pulsarPrimary
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.labelMedium)
                        .foregroundStyle(color)
                }
                Text(title.uppercased())
                    .font(.labelSmall)
                    .foregroundStyle(Color.textTertiary)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: Spacing.xxs) {
                Text(value)
                    .font(.statMedium)
                    .foregroundStyle(Color.textPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
}

// MARK: - Activity Card

struct ActivityCard: View {
    let activity: ActivityData
    let showUser: Bool
    let onTap: () -> Void
    let onKudos: () -> Void
    let onComment: () -> Void
    
    init(
        activity: ActivityData,
        showUser: Bool = true,
        onTap: @escaping () -> Void = {},
        onKudos: @escaping () -> Void = {},
        onComment: @escaping () -> Void = {}
    ) {
        self.activity = activity
        self.showUser = showUser
        self.onTap = onTap
        self.onKudos = onKudos
        self.onComment = onComment
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            if showUser {
                HStack(spacing: Spacing.sm) {
                    AsyncProfileImage(url: activity.userAvatarURL, size: 44)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.userName)
                            .font(.headlineSmall)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text(activity.relativeTime)
                            .font(.bodySmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: activity.type.icon)
                        .font(.title3)
                        .foregroundStyle(activity.type.color)
                }
                .padding(Spacing.md)
            }
            
            // Activity Content
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Title
                    Text(activity.name)
                        .font(.headlineMedium)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Map Preview
                    if activity.hasRoute {
                        RoutePreview(coordinates: activity.routeCoordinates)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }
                    
                    // Stats Grid
                    HStack(spacing: Spacing.md) {
                        StatPill(
                            value: activity.formattedDistance,
                            unit: "km",
                            icon: "ruler"
                        )
                        
                        StatPill(
                            value: activity.formattedDuration,
                            unit: "",
                            icon: "clock"
                        )
                        
                        if let pace = activity.formattedPace {
                            StatPill(
                                value: pace,
                                unit: "/km",
                                icon: "speedometer"
                            )
                        }
                        
                        if let elevation = activity.formattedElevation {
                            StatPill(
                                value: elevation,
                                unit: "m",
                                icon: "arrow.up.right"
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
            .buttonStyle(.plain)
            
            Divider()
                .padding(.horizontal, Spacing.md)
            
            // Actions
            HStack(spacing: Spacing.xl) {
                ActionButton(
                    icon: activity.hasKudos ? "heart.fill" : "heart",
                    count: activity.kudosCount,
                    isActive: activity.hasKudos,
                    activeColor: .pulsarError,
                    action: onKudos
                )
                
                ActionButton(
                    icon: "bubble.left",
                    count: activity.commentsCount,
                    action: onComment
                )
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
            
            Text(value)
                .font(.labelLarge)
                .foregroundStyle(Color.textPrimary)
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Color.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let count: Int
    var isActive: Bool = false
    var activeColor: Color = .pulsarPrimary
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.bodyMedium)
                    .foregroundStyle(isActive ? activeColor : Color.textSecondary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}

// MARK: - Profile Image

struct AsyncProfileImage: View {
    let url: URL?
    let size: CGFloat
    
    init(url: URL?, size: CGFloat = 44) {
        self.url = url
        self.size = size
    }
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure, .empty:
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(Color.textTertiary)
            @unknown default:
                ProgressView()
            }
        }
        .frame(width: size, height: size)
        .background(Color.elevatedBackground)
        .clipShape(Circle())
    }
}

// MARK: - Route Preview

struct RoutePreview: View {
    let coordinates: [Coordinate]
    
    var body: some View {
        GeometryReader { geometry in
            if !coordinates.isEmpty {
                Path { path in
                    let points = normalizedPoints(in: geometry.size)
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    LinearGradient.pulsarGradient,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .background(Color.elevatedBackground)
            } else {
                Color.elevatedBackground
                    .overlay {
                        Image(systemName: "map")
                            .font(.title)
                            .foregroundStyle(Color.textTertiary)
                    }
            }
        }
    }
    
    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !coordinates.isEmpty else { return [] }
        
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        
        let latRange = max(maxLat - minLat, 0.0001)
        let lonRange = max(maxLon - minLon, 0.0001)
        
        let padding: CGFloat = 16
        let drawWidth = size.width - padding * 2
        let drawHeight = size.height - padding * 2
        
        return coordinates.map { coord in
            let x = padding + CGFloat((coord.longitude - minLon) / lonRange) * drawWidth
            let y = padding + CGFloat(1 - (coord.latitude - minLat) / latRange) * drawHeight
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String?
    
    init(_ message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .pulsarPrimary))
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cardBackground)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(Color.textTertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.headlineLarge)
                    .foregroundStyle(Color.textPrimary)
                
                Text(message)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(Spacing.xxl)
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let avatarURL: URL?
    let value: String
    let isCurrentUser: Bool
    let isPR: Bool
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 32, height: 32)
                    Text("\(rank)")
                        .font(.labelLarge)
                        .foregroundStyle(.white)
                } else {
                    Text("\(rank)")
                        .font(.labelLarge)
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 32)
                }
            }
            
            // Avatar
            AsyncProfileImage(url: avatarURL, size: 40)
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xxs) {
                    Text(name)
                        .font(.headlineSmall)
                        .foregroundStyle(isCurrentUser ? Color.pulsarPrimary : Color.textPrimary)
                    
                    if isPR {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.pulsarWarning)
                    }
                }
                
                if isCurrentUser {
                    Text("You")
                        .font(.caption2)
                        .foregroundStyle(Color.pulsarPrimary)
                }
            }
            
            Spacer()
            
            // Value
            Text(value)
                .font(.statSmall)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(isCurrentUser ? Color.pulsarPrimary.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD700") // Gold
        case 2: return Color(hex: "C0C0C0") // Silver
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return Color.textTertiary
        }
    }
}

// MARK: - Tab Bar Item

struct PulsarTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isSelected ? "\(icon).fill" : icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.pulsarPrimary : Color.textTertiary)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.pulsarPrimary : Color.textTertiary)
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.bodyMedium)
                .foregroundStyle(Color.textTertiary)
            
            TextField(placeholder, text: $text)
                .font(.bodyMedium)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

// MARK: - Supporting Types

struct Coordinate: Codable, Sendable, Hashable {
    let latitude: Double
    let longitude: Double
}

struct ActivityData: Identifiable, Sendable {
    let id: UUID
    let name: String
    let type: ActivityType
    let userName: String
    let userAvatarURL: URL?
    let distanceMeters: Double
    let durationSeconds: Int
    let elevationGainMeters: Double?
    let paceSecondsPerKm: Int?
    let startDate: Date
    let routeCoordinates: [Coordinate]
    var kudosCount: Int
    var commentsCount: Int
    var hasKudos: Bool
    
    var hasRoute: Bool { !routeCoordinates.isEmpty }
    
    var formattedDistance: String {
        String(format: "%.2f", distanceMeters / 1000)
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
    
    var formattedPace: String? {
        guard let pace = paceSecondsPerKm else { return nil }
        let minutes = pace / 60
        let seconds = pace % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedElevation: String? {
        guard let elevation = elevationGainMeters else { return nil }
        return String(format: "%.0f", elevation)
    }
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: startDate, relativeTo: Date())
    }
}
