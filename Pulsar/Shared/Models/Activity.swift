//
//  Activity.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import MapKit
import SwiftData

/// Activity model for storing workout data
@Model
final class Activity {
    // MARK: - Identity
    
    @Attribute(.unique) var id: String
    var userId: String
    
    // MARK: - Metadata
    
    var name: String
    var activityType: ActivityType
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Statistics
    
    var distance: Double // meters
    var duration: Double // seconds
    var elevationGain: Double? // meters
    var elevationLoss: Double? // meters
    var maxElevation: Double? // meters
    var minElevation: Double? // meters
    
    // MARK: - Performance Metrics
    
    var avgSpeed: Double? // m/s
    var maxSpeed: Double? // m/s
    var avgHeartRate: Int? // bpm
    var maxHeartRate: Int? // bpm
    var avgPower: Double? // watts
    var maxPower: Double? // watts
    var avgCadence: Int? // rpm
    var maxCadence: Int? // rpm
    var calories: Int? // kcal
    
    // MARK: - Route Data
    
    @Relationship(deleteRule: .cascade) var trackPoints: [TrackPoint]?
    var routePolyline: String? // Encoded polyline for MapKit
    
    // MARK: - Source
    
    var source: ActivitySource
    var originalFileName: String?
    var rawFileURL: String? // URL to stored GPX/TCX/FIT file in Supabase Storage
    
    // MARK: - Privacy
    
    var isPrivate: Bool
    var isStationary: Bool // true if activity was recorded in one location (treadmill, etc)
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        activityType: ActivityType,
        startDate: Date,
        endDate: Date,
        distance: Double,
        duration: Double,
        source: ActivitySource = .fileUpload,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.activityType = activityType
        self.startDate = startDate
        self.endDate = endDate
        self.distance = distance
        self.duration = duration
        self.source = source
        self.isPrivate = isPrivate
        self.isStationary = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var averagePace: Double? {
        guard distance > 0, duration > 0 else { return nil }
        // Pace in minutes per kilometer
        return (duration / 60) / (distance / 1000)
    }
    
    var averageSpeedKmh: Double? {
        guard let avgSpeed else { return nil }
        return avgSpeed * 3.6 // m/s to km/h
    }
}

// MARK: - Supporting Models

@Model
final class TrackPoint {
    var latitude: Double
    var longitude: Double
    var elevation: Double?
    var timestamp: Date
    var heartRate: Int?
    var power: Double?
    var cadence: Int?
    var speed: Double?
    var distance: Double? // cumulative distance at this point
    
    init(
        latitude: Double,
        longitude: Double,
        elevation: Double? = nil,
        timestamp: Date,
        heartRate: Int? = nil,
        power: Double? = nil,
        cadence: Int? = nil,
        speed: Double? = nil,
        distance: Double? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.power = power
        self.cadence = cadence
        self.speed = speed
        self.distance = distance
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Enums

enum ActivityType: String, Codable, CaseIterable, Sendable {
    case run = "run"
    case ride = "ride"
    case walk = "walk"
    case hike = "hike"
    case swim = "swim"
    case ski = "ski"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .run: return "Run"
        case .ride: return "Ride"
        case .walk: return "Walk"
        case .hike: return "Hike"
        case .swim: return "Swim"
        case .ski: return "Ski"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .run: return "figure.run"
        case .ride: return "bicycle"
        case .walk: return "figure.walk"
        case .hike: return "figure.hiking"
        case .swim: return "figure.pool.swim"
        case .ski: return "figure.skiing.downhill"
        case .other: return "figure.mixed.cardio"
        }
    }
}

enum ActivitySource: String, Codable, Sendable {
    case fileUpload = "file_upload"
    case healthKit = "healthkit"
    case stravaAPI = "strava_api"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .fileUpload: return "File Upload"
        case .healthKit: return "Apple Health"
        case .stravaAPI: return "Strava"
        case .manual: return "Manual Entry"
        }
    }
}

// MARK: - DTOs for API

struct ActivityDTO: Codable, Sendable {
    let id: String
    let userId: String
    let name: String
    let activityType: String
    let startDate: Date
    let endDate: Date
    let distance: Double
    let duration: Double
    let elevationGain: Double?
    let elevationLoss: Double?
    let maxElevation: Double?
    let minElevation: Double?
    let avgSpeed: Double?
    let maxSpeed: Double?
    let avgHeartRate: Int?
    let maxHeartRate: Int?
    let avgPower: Double?
    let maxPower: Double?
    let avgCadence: Int?
    let maxCadence: Int?
    let calories: Int?
    let routePolyline: String?
    let source: String
    let originalFileName: String?
    let rawFileURL: String?
    let isPrivate: Bool
    let isStationary: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case activityType = "activity_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case distance
        case duration
        case elevationGain = "elevation_gain"
        case elevationLoss = "elevation_loss"
        case maxElevation = "max_elevation"
        case minElevation = "min_elevation"
        case avgSpeed = "avg_speed"
        case maxSpeed = "max_speed"
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case avgPower = "avg_power"
        case maxPower = "max_power"
        case avgCadence = "avg_cadence"
        case maxCadence = "max_cadence"
        case calories
        case routePolyline = "route_polyline"
        case source
        case originalFileName = "original_file_name"
        case rawFileURL = "raw_file_url"
        case isPrivate = "is_private"
        case isStationary = "is_stationary"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Backend DTO (matches Supabase schema)

struct ActivityBackendDTO: Codable, Sendable {
    let activityId: String? // Optional for inserts (backend generates UUID)
    let userId: String
    let activityType: String
    let name: String
    let description: String?
    let distanceM: Double
    let durationSec: Int
    let elevationGainM: Double?
    let elevationLossM: Double?
    let maxElevation: Double?
    let minElevation: Double?
    let avgHeartRate: Int?
    let maxHeartRate: Int?
    let avgPower: Int?
    let maxPower: Int?
    let avgCadence: Int?
    let maxCadence: Int?
    let startTime: Date
    let endTime: Date?
    let startLat: Double?
    let startLon: Double?
    let endLat: Double?
    let endLon: Double?
    let geom: String? // PostGIS LineString in WKT format: "SRID=4326;LINESTRING(lon lat, lon lat, ...)"
    let visibility: String // "public", "followers", or "private"
    let fileUrl: String?
    let originalFileName: String?
    
    enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case userId = "user_id"
        case activityType = "activity_type"
        case name
        case description
        case distanceM = "distance_m"
        case durationSec = "duration_sec"
        case elevationGainM = "elevation_gain_m"
        case elevationLossM = "elevation_loss_m"
        case maxElevation = "max_elevation"
        case minElevation = "min_elevation"
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case avgPower = "avg_power"
        case maxPower = "max_power"
        case avgCadence = "avg_cadence"
        case maxCadence = "max_cadence"
        case startTime = "start_time"
        case endTime = "end_time"
        case startLat = "start_lat"
        case startLon = "start_lon"
        case endLat = "end_lat"
        case endLon = "end_lon"
        case geom
        case visibility
        case fileUrl = "file_url"
        case originalFileName = "original_file_name"
    }
}

// MARK: - Conversion Extensions

extension Activity {
    func toDTO() -> ActivityDTO {
        ActivityDTO(
            id: id,
            userId: userId,
            name: name,
            activityType: activityType.rawValue,
            startDate: startDate,
            endDate: endDate,
            distance: distance,
            duration: duration,
            elevationGain: elevationGain,
            elevationLoss: elevationLoss,
            maxElevation: maxElevation,
            minElevation: minElevation,
            avgSpeed: avgSpeed,
            maxSpeed: maxSpeed,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            avgPower: avgPower,
            maxPower: maxPower,
            avgCadence: avgCadence,
            maxCadence: maxCadence,
            calories: calories,
            routePolyline: routePolyline,
            source: source.rawValue,
            originalFileName: originalFileName,
            rawFileURL: rawFileURL,
            isPrivate: isPrivate,
            isStationary: isStationary,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    static func fromDTO(_ dto: ActivityDTO) -> Activity {
        let activity = Activity(
            id: dto.id,
            userId: dto.userId,
            name: dto.name,
            activityType: ActivityType(rawValue: dto.activityType) ?? .other,
            startDate: dto.startDate,
            endDate: dto.endDate,
            distance: dto.distance,
            duration: dto.duration,
            source: ActivitySource(rawValue: dto.source) ?? .fileUpload,
            isPrivate: dto.isPrivate
        )
        
        activity.elevationGain = dto.elevationGain
        activity.elevationLoss = dto.elevationLoss
        activity.maxElevation = dto.maxElevation
        activity.minElevation = dto.minElevation
        activity.avgSpeed = dto.avgSpeed
        activity.maxSpeed = dto.maxSpeed
        activity.avgHeartRate = dto.avgHeartRate
        activity.maxHeartRate = dto.maxHeartRate
        activity.avgPower = dto.avgPower
        activity.maxPower = dto.maxPower
        activity.avgCadence = dto.avgCadence
        activity.maxCadence = dto.maxCadence
        activity.calories = dto.calories
        activity.routePolyline = dto.routePolyline
        activity.originalFileName = dto.originalFileName
        activity.rawFileURL = dto.rawFileURL
        activity.isStationary = dto.isStationary
        activity.createdAt = dto.createdAt
        activity.updatedAt = dto.updatedAt
        
        return activity
    }
}
