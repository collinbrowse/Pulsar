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
    
    // MARK: - Sync Status
    
    var lastSyncedAt: Date? // Timestamp of last successful backend sync, nil if never synced or needs retry
    
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
    case run
    case ride
    case walk
    case hike
    case swim
    case ski
    case other
    
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
    let geom: String? // PostGIS LineString in WKT or GeoJSON format (will be converted to string representation)
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
    
    // Manual initializer for encoding (when creating DTO to send to backend)
    init(
        activityId: String?,
        userId: String,
        activityType: String,
        name: String,
        description: String?,
        distanceM: Double,
        durationSec: Int,
        elevationGainM: Double?,
        elevationLossM: Double?,
        maxElevation: Double?,
        minElevation: Double?,
        avgHeartRate: Int?,
        maxHeartRate: Int?,
        avgPower: Int?,
        maxPower: Int?,
        avgCadence: Int?,
        maxCadence: Int?,
        startTime: Date,
        endTime: Date?,
        startLat: Double?,
        startLon: Double?,
        endLat: Double?,
        endLon: Double?,
        geom: String?,
        visibility: String,
        fileUrl: String?,
        originalFileName: String?
    ) {
        self.activityId = activityId
        self.userId = userId
        self.activityType = activityType
        self.name = name
        self.description = description
        self.distanceM = distanceM
        self.durationSec = durationSec
        self.elevationGainM = elevationGainM
        self.elevationLossM = elevationLossM
        self.maxElevation = maxElevation
        self.minElevation = minElevation
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.avgPower = avgPower
        self.maxPower = maxPower
        self.avgCadence = avgCadence
        self.maxCadence = maxCadence
        self.startTime = startTime
        self.endTime = endTime
        self.startLat = startLat
        self.startLon = startLon
        self.endLat = endLat
        self.endLon = endLon
        self.geom = geom
        self.visibility = visibility
        self.fileUrl = fileUrl
        self.originalFileName = originalFileName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activityId = try container.decodeIfPresent(String.self, forKey: .activityId)
        userId = try container.decode(String.self, forKey: .userId)
        activityType = try container.decode(String.self, forKey: .activityType)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        distanceM = try container.decode(Double.self, forKey: .distanceM)
        durationSec = try container.decode(Int.self, forKey: .durationSec)
        elevationGainM = try container.decodeIfPresent(Double.self, forKey: .elevationGainM)
        elevationLossM = try container.decodeIfPresent(Double.self, forKey: .elevationLossM)
        maxElevation = try container.decodeIfPresent(Double.self, forKey: .maxElevation)
        minElevation = try container.decodeIfPresent(Double.self, forKey: .minElevation)
        avgHeartRate = try container.decodeIfPresent(Int.self, forKey: .avgHeartRate)
        maxHeartRate = try container.decodeIfPresent(Int.self, forKey: .maxHeartRate)
        avgPower = try container.decodeIfPresent(Int.self, forKey: .avgPower)
        maxPower = try container.decodeIfPresent(Int.self, forKey: .maxPower)
        avgCadence = try container.decodeIfPresent(Int.self, forKey: .avgCadence)
        maxCadence = try container.decodeIfPresent(Int.self, forKey: .maxCadence)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        startLat = try container.decodeIfPresent(Double.self, forKey: .startLat)
        startLon = try container.decodeIfPresent(Double.self, forKey: .startLon)
        endLat = try container.decodeIfPresent(Double.self, forKey: .endLat)
        endLon = try container.decodeIfPresent(Double.self, forKey: .endLon)
        visibility = try container.decode(String.self, forKey: .visibility)
        fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl)
        originalFileName = try container.decodeIfPresent(String.self, forKey: .originalFileName)
        
        // Handle geom field - PostgREST returns PostGIS geometry as GeoJSON object
        // Try to decode as string first (WKT format), otherwise decode as JSON object and convert to string
        if let geomString = try? container.decode(String.self, forKey: .geom) {
            // Already a string (WKT format)
            geom = geomString
        } else if container.contains(.geom) {
            let isNil = (try? container.decodeNil(forKey: .geom)) ?? false
            if !isNil {
                // Decode as JSON object (GeoJSON) - use a helper struct to decode the GeoJSON
                // Then serialize it back to a JSON string for the parsing function
                // Note: PostGIS may include a "crs" field which we ignore
                struct GeoJSONHelper: Decodable {
                    let type: String
                    let coordinates: [[Double]]
                    let crs: CRSHelper? // Optional CRS field from PostGIS
            
                    struct CRSHelper: Decodable {
                        let type: String?
                        let properties: [String: String]?
                    }
                }
                
                if let geoJSON = try? container.decode(GeoJSONHelper.self, forKey: .geom) {
                    // Convert back to JSON string
                    let jsonDict: [String: Any] = [
                        "type": geoJSON.type,
                        "coordinates": geoJSON.coordinates
                    ]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        geom = jsonString
                    } else {
                        geom = nil
                    }
                } else {
                    geom = nil
                }
            } else {
                geom = nil
            }
        } else {
            geom = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(activityId, forKey: .activityId)
        try container.encode(userId, forKey: .userId)
        try container.encode(activityType, forKey: .activityType)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(distanceM, forKey: .distanceM)
        try container.encode(durationSec, forKey: .durationSec)
        try container.encodeIfPresent(elevationGainM, forKey: .elevationGainM)
        try container.encodeIfPresent(elevationLossM, forKey: .elevationLossM)
        try container.encodeIfPresent(maxElevation, forKey: .maxElevation)
        try container.encodeIfPresent(minElevation, forKey: .minElevation)
        try container.encodeIfPresent(avgHeartRate, forKey: .avgHeartRate)
        try container.encodeIfPresent(maxHeartRate, forKey: .maxHeartRate)
        try container.encodeIfPresent(avgPower, forKey: .avgPower)
        try container.encodeIfPresent(maxPower, forKey: .maxPower)
        try container.encodeIfPresent(avgCadence, forKey: .avgCadence)
        try container.encodeIfPresent(maxCadence, forKey: .maxCadence)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(startLat, forKey: .startLat)
        try container.encodeIfPresent(startLon, forKey: .startLon)
        try container.encodeIfPresent(endLat, forKey: .endLat)
        try container.encodeIfPresent(endLon, forKey: .endLon)
        try container.encodeIfPresent(geom, forKey: .geom)
        try container.encode(visibility, forKey: .visibility)
        try container.encodeIfPresent(fileUrl, forKey: .fileUrl)
        try container.encodeIfPresent(originalFileName, forKey: .originalFileName)
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
