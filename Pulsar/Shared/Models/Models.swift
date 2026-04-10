//
//  Models.swift
//  Pulsar
//
//  SwiftData Models for local persistence
//

import CoreLocation
import Foundation
import SwiftData

// MARK: - Profile Model

@Model
final class Profile {
    @Attribute(.unique) var userId: String
    @Attribute(.unique) var username: String
    var fullName: String?
    var avatarURL: URL?
    var bio: String?
    var gender: Gender?
    var weightKg: Double?
    var birthYear: Int?
    var location: String?
    var isPrivate: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Stats (cached for performance)
    var totalActivities: Int
    var totalDistanceMeters: Double
    var totalDurationSeconds: Int
    var totalElevationMeters: Double
    var followersCount: Int
    var followingCount: Int
    var useMetricUnits: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Activity.profile)
    var activities: [Activity]?
    
    init(
        userId: String,
        username: String,
        fullName: String? = nil,
        avatarURL: URL? = nil,
        bio: String? = nil,
        gender: Gender? = nil,
        weightKg: Double? = nil,
        birthYear: Int? = nil,
        location: String? = nil,
        isPrivate: Bool = false,
        useMetricUnits: Bool = true
    ) {
        self.userId = userId
        self.username = username
        self.fullName = fullName
        self.avatarURL = avatarURL
        self.bio = bio
        self.gender = gender
        self.weightKg = weightKg
        self.birthYear = birthYear
        self.location = location
        self.isPrivate = isPrivate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.totalActivities = 0
        self.totalDistanceMeters = 0
        self.totalDurationSeconds = 0
        self.totalElevationMeters = 0
        self.followersCount = 0
        self.followingCount = 0
        self.useMetricUnits = useMetricUnits
    }
    
    var displayName: String {
        fullName ?? username
    }
    
    var age: Int? {
        guard let birthYear = birthYear else { return nil }
        return Calendar.current.component(.year, from: Date()) - birthYear
    }
    
    func toDTO() -> ProfileDTO {
        ProfileDTO(
            userId: userId,
            username: username,
            fullName: fullName,
            avatarUrl: avatarURL?.absoluteString
        )
    }
}

// MARK: - Activity Model

@Model
final class Activity {
    @Attribute(.unique) var activityId: String
    var name: String
    var activityDescription: String?
    var activityType: String // ActivityType rawValue
    var visibility: Visibility
    
    // Timing
    var startDate: Date
    var endDate: Date?
    var elapsedTimeSeconds: Int
    var movingTimeSeconds: Int?
    
    // Distance & Speed
    var distanceMeters: Double
    var avgSpeedMps: Double?
    var maxSpeedMps: Double?
    
    // Elevation
    var elevationGainMeters: Double?
    var elevationLossMeters: Double?
    var minElevationMeters: Double?
    var maxElevationMeters: Double?
    
    // Heart Rate
    var avgHeartRate: Int?
    var maxHeartRate: Int?
    
    // Power (for cycling)
    var avgPower: Int?
    var maxPower: Int?
    var normalizedPower: Int?
    
    // Cadence
    var avgCadence: Int?
    var maxCadence: Int?
    
    // Route data (serialized coordinates)
    var routeData: Data?
    
    // Metadata
    var sourceFile: String?
    var deviceName: String?
    var calories: Int?
    var weather: String?
    
    // Social
    var kudosCount: Int
    var commentsCount: Int
    
    // Relationships
    var profile: Profile?
    
    @Relationship(deleteRule: .cascade, inverse: \SegmentEffort.activity)
    var segmentEfforts: [SegmentEffort]?
    
    init(
        activityId: String = UUID().uuidString,
        name: String,
        activityType: ActivityType,
        startDate: Date,
        elapsedTimeSeconds: Int,
        distanceMeters: Double,
        visibility: Visibility = .publicVisible
    ) {
        self.activityId = activityId
        self.name = name
        self.activityType = activityType.rawValue
        self.startDate = startDate
        self.elapsedTimeSeconds = elapsedTimeSeconds
        self.distanceMeters = distanceMeters
        self.visibility = visibility
        self.kudosCount = 0
        self.commentsCount = 0
    }
    
    // MARK: - Computed Properties
    
    var type: ActivityType {
        ActivityType(rawValue: activityType) ?? .other
    }
    
    var formattedDistance: String {
        String(format: "%.2f km", distanceMeters / 1000)
    }
    
    var formattedDuration: String {
        let hours = elapsedTimeSeconds / 3600
        let minutes = (elapsedTimeSeconds % 3600) / 60
        let seconds = elapsedTimeSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedPace: String? {
        guard distanceMeters > 0 else { return nil }
        let paceSecondsPerKm = Int(Double(elapsedTimeSeconds) / (distanceMeters / 1000))
        let minutes = paceSecondsPerKm / 60
        let seconds = paceSecondsPerKm % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    var formattedSpeed: String? {
        guard let speed = avgSpeedMps else { return nil }
        return String(format: "%.1f km/h", speed * 3.6)
    }
    
    var formattedElevation: String? {
        guard let elevation = elevationGainMeters else { return nil }
        return String(format: "%.0f m", elevation)
    }
    
    var coordinates: [Coordinate] {
        guard let data = routeData else { return [] }
        return (try? JSONDecoder().decode([Coordinate].self, from: data)) ?? []
    }
    
    func setCoordinates(_ coords: [Coordinate]) {
        routeData = try? JSONEncoder().encode(coords)
    }
    
    /// Route points for map views, derived from stored `Coordinate` route data.
    var trackPoints: [TrackPoint]? {
        let coords = coordinates
        guard !coords.isEmpty else { return nil }
        return coords.map { coord in
            TrackPoint(
                latitude: coord.latitude,
                longitude: coord.longitude,
                timestamp: coord.time ?? startDate,
                elevation: coord.elevation
            )
        }
    }
}

// MARK: - Track Point (route sample for MapKit)

struct TrackPoint: Codable, Sendable, Hashable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var elevation: Double?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Segment Model

@Model
final class Segment {
    @Attribute(.unique) var segmentId: String
    var name: String
    var segmentDescription: String?
    var activityType: String
    var distanceMeters: Double
    var avgGradePercent: Double?
    var maxGradePercent: Double?
    var elevationGainMeters: Double?
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    var city: String?
    var state: String?
    var country: String?
    var isPrivate: Bool
    var isHazardous: Bool
    var starCount: Int
    var effortCount: Int
    var createdAt: Date
    
    // Route data
    var routeData: Data?
    
    // KOM/QOM times (seconds)
    var komTime: Int?
    var qomTime: Int?
    
    @Relationship(deleteRule: .cascade, inverse: \SegmentEffort.segment)
    var efforts: [SegmentEffort]?
    
    init(
        segmentId: String = UUID().uuidString,
        name: String,
        activityType: ActivityType,
        distanceMeters: Double,
        startLatitude: Double,
        startLongitude: Double,
        endLatitude: Double,
        endLongitude: Double
    ) {
        self.segmentId = segmentId
        self.name = name
        self.activityType = activityType.rawValue
        self.distanceMeters = distanceMeters
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.isPrivate = false
        self.isHazardous = false
        self.starCount = 0
        self.effortCount = 0
        self.createdAt = Date()
    }
    
    var type: ActivityType {
        ActivityType(rawValue: activityType) ?? .other
    }
    
    var coordinates: [Coordinate] {
        guard let data = routeData else { return [] }
        return (try? JSONDecoder().decode([Coordinate].self, from: data)) ?? []
    }
    
    var formattedDistance: String {
        String(format: "%.2f km", distanceMeters / 1000)
    }
}

// MARK: - Segment Effort Model

@Model
final class SegmentEffort {
    @Attribute(.unique) var effortId: String
    var elapsedTimeSeconds: Int
    var movingTimeSeconds: Int?
    var startDate: Date
    var rank: Int?
    var isPR: Bool
    var prRank: Int?
    
    // Denormalized for leaderboard performance
    var userGender: String?
    var userBirthYear: Int?
    
    // Performance data
    var avgHeartRate: Int?
    var maxHeartRate: Int?
    var avgPower: Int?
    
    // Relationships
    var segment: Segment?
    var activity: Activity?
    
    init(
        effortId: String = UUID().uuidString,
        elapsedTimeSeconds: Int,
        startDate: Date,
        isPR: Bool = false
    ) {
        self.effortId = effortId
        self.elapsedTimeSeconds = elapsedTimeSeconds
        self.startDate = startDate
        self.isPR = isPR
    }
    
    var formattedTime: String {
        let hours = elapsedTimeSeconds / 3600
        let minutes = (elapsedTimeSeconds % 3600) / 60
        let seconds = elapsedTimeSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Follow Relationship

@Model
final class Follow {
    @Attribute(.unique) var followId: String
    var followerId: String
    var followingId: String
    var createdAt: Date
    var status: FollowStatus
    
    init(
        followerId: String,
        followingId: String,
        status: FollowStatus = .accepted
    ) {
        self.followId = "\(followerId)_\(followingId)"
        self.followerId = followerId
        self.followingId = followingId
        self.createdAt = Date()
        self.status = status
    }
}

// MARK: - Kudos Model

@Model
final class Kudos {
    @Attribute(.unique) var kudosId: String
    var userId: String
    var activityId: String
    var createdAt: Date
    
    init(userId: String, activityId: String) {
        self.kudosId = "\(userId)_\(activityId)"
        self.userId = userId
        self.activityId = activityId
        self.createdAt = Date()
    }
}

// MARK: - Comment Model

@Model
final class Comment {
    @Attribute(.unique) var commentId: String
    var userId: String
    var activityId: String
    var content: String
    var createdAt: Date
    var updatedAt: Date?
    
    init(
        commentId: String = UUID().uuidString,
        userId: String,
        activityId: String,
        content: String
    ) {
        self.commentId = commentId
        self.userId = userId
        self.activityId = activityId
        self.content = content
        self.createdAt = Date()
    }
}

// MARK: - Enums

enum Gender: String, Codable, CaseIterable, Sendable {
    case male = "male"
    case female = "female"
    case nonBinary = "non_binary"
    case preferNotToSay = "prefer_not_to_say"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-binary"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

enum Visibility: String, Codable, CaseIterable, Sendable {
    case publicVisible = "public"
    case followers = "followers"
    case privateOnly = "private"
    
    var displayName: String {
        switch self {
        case .publicVisible: return "Public"
        case .followers: return "Followers Only"
        case .privateOnly: return "Private"
        }
    }
    
    var icon: String {
        switch self {
        case .publicVisible: return "globe"
        case .followers: return "person.2"
        case .privateOnly: return "lock"
        }
    }
}

enum FollowStatus: String, Codable, Sendable {
    case pending
    case accepted
    case blocked
}
