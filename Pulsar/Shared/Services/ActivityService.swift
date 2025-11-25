//
//  ActivityService.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import CoreGPX
import FitDataProtocol
import Foundation
import MapKit
import OSLog
import SwiftData
import XMLCoder

private let logger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "ActivityService")

/// Service for parsing, storing, and managing activities
@MainActor
final class ActivityService {
    static let shared = ActivityService()
    
    private init() {}
    
    // MARK: - File Parsing
    
    /// Parse an activity file (GPX, TCX, or FIT) and create an Activity model
    func parseActivityFile(
        from url: URL,
        userId: String
    ) async throws -> Activity {
        logger.info("📄 Parsing activity file: \(url.lastPathComponent)")
        
        let fileExtension = url.pathExtension.lowercased()
        let data = try Data(contentsOf: url)
        
        switch fileExtension {
        case "gpx":
            return try await parseGPX(data: data, fileName: url.lastPathComponent, userId: userId)
        case "tcx":
            return try await parseTCX(data: data, fileName: url.lastPathComponent, userId: userId)
        case "fit":
            return try await parseFIT(data: data, fileName: url.lastPathComponent, userId: userId)
        default:
            throw ActivityServiceError.unsupportedFileFormat(fileExtension)
        }
    }
    
    // MARK: - GPX Parsing
    
    private func parseGPX(data: Data, fileName: String, userId: String) async throws -> Activity {
        logger.info("📍 Parsing GPX file")
        
        // Create temporary file to use GPXParser
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("gpx")
        try data.write(to: tempURL)
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        guard let parser = GPXParser(withPath: tempURL.path),
              let gpxRoot = parser.parsedData() else {
            throw ActivityServiceError.parsingFailed("Failed to parse GPX XML")
        }
        
        // Extract track points from all tracks
        var allTrackPoints: [GPXTrackPoint] = []
        for track in gpxRoot.tracks {
            for segment in track.segments {
                allTrackPoints.append(contentsOf: segment.points)
            }
        }
        
        guard !allTrackPoints.isEmpty else {
            throw ActivityServiceError.noTrackPoints
        }
        
        // Convert to TrackPoint models and calculate metrics
        let trackPoints = allTrackPoints.compactMap { gpxPoint -> TrackPoint? in
            guard let lat = gpxPoint.latitude,
                  let lon = gpxPoint.longitude else {
                return nil
            }
            
            return TrackPoint(
                latitude: lat,
                longitude: lon,
                elevation: gpxPoint.elevation,
                timestamp: gpxPoint.time ?? Date(),
                heartRate: nil,
                power: nil,
                cadence: nil,
                speed: nil,
                distance: nil
            )
        }
        
        guard !trackPoints.isEmpty else {
            throw ActivityServiceError.noTrackPoints
        }
        
        // Calculate metrics
        let startDate = trackPoints.first!.timestamp
        let endDate = trackPoints.last!.timestamp
        let duration = endDate.timeIntervalSince(startDate)
        
        // Calculate distance from track points
        var totalDistance: Double = 0
        var cumulativeDistance: Double = 0
        var elevationGain: Double = 0
        var elevationLoss: Double = 0
        var minElevation: Double?
        var maxElevation: Double?
        var speeds: [Double] = []
        
        for (index, point) in trackPoints.enumerated() {
            // Update elevation stats
            if let elevation = point.elevation {
                if minElevation == nil || elevation < minElevation! {
                    minElevation = elevation
                }
                if maxElevation == nil || elevation > maxElevation! {
                    maxElevation = elevation
                }
                
                // Calculate elevation gain/loss with noise filtering
                // Only count elevation changes > 2 meters to filter GPS noise
                if index > 0, let prevElevation = trackPoints[index - 1].elevation {
                    let elevationDiff = elevation - prevElevation
                    // Filter out small changes (< 2m) that are likely GPS noise
                    if abs(elevationDiff) >= 2.0 {
                        if elevationDiff > 0 {
                            elevationGain += elevationDiff
                        } else {
                            elevationLoss += abs(elevationDiff)
                        }
                    }
                }
            }
            
            // Calculate distance
            if index > 0 {
                let prevPoint = trackPoints[index - 1]
                let distance = calculateDistance(
                    from: CLLocationCoordinate2D(latitude: prevPoint.latitude, longitude: prevPoint.longitude),
                    to: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                )
                cumulativeDistance += distance
                totalDistance += distance
                
                // Calculate speed if we have timestamps
                let timeDiff = point.timestamp.timeIntervalSince(prevPoint.timestamp)
                if timeDiff > 0 {
                    let speed = distance / timeDiff // m/s
                    speeds.append(speed)
                }
            }
            
            // Update cumulative distance in track point
            trackPoints[index].distance = cumulativeDistance
        }
        
        // Determine activity type from name or default to run
        let activityType = determineActivityType(from: fileName, distance: totalDistance)
        
        // Create activity
        let activity = Activity(
            userId: userId,
            name: gpxRoot.metadata?.name ?? generateActivityName(from: fileName),
            activityType: activityType,
            startDate: startDate,
            endDate: endDate,
            distance: totalDistance,
            duration: duration,
            source: .fileUpload
        )
        
        activity.originalFileName = fileName
        activity.trackPoints = trackPoints
        activity.elevationGain = elevationGain > 0 ? elevationGain : nil
        activity.elevationLoss = elevationLoss > 0 ? elevationLoss : nil
        activity.minElevation = minElevation
        activity.maxElevation = maxElevation
        
        // Calculate average and max speed
        if !speeds.isEmpty {
            activity.avgSpeed = speeds.reduce(0, +) / Double(speeds.count)
            activity.maxSpeed = speeds.max()
        } else if duration > 0 {
            activity.avgSpeed = totalDistance / duration
        }
        
        logger.info("✅ GPX parsed: \(activity.name) - \(String(format: "%.2f", totalDistance/1000))km, \(Int(duration/60))min")
        return activity
    }
    
    // MARK: - TCX Parsing
    
    private func parseTCX(data: Data, fileName: String, userId: String) async throws -> Activity {
        logger.info("📍 Parsing TCX file")
        
        let decoder = XMLDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let tcx: TrainingCenterDatabase
        do {
            tcx = try decoder.decode(TrainingCenterDatabase.self, from: data)
        } catch {
            throw ActivityServiceError.parsingFailed("TCX decode failed: \(error.localizedDescription)")
        }
        
        guard let activity = tcx.activities.activity.first,
              let lap = activity.lap.first else {
            throw ActivityServiceError.parsingFailed("No activity or lap data found in TCX file")
        }
        
        // Extract track points
        var allTrackPoints: [TrackPoint] = []
        var heartRates: [Int] = []
        var cadences: [Int] = []
        var powers: [Double] = []
        
        if let track = lap.track {
            for trackpoint in track.trackpoint {
                guard let position = trackpoint.position,
                      let lat = position.latitudeDegrees,
                      let lon = position.longitudeDegrees,
                      let time = trackpoint.time else {
                    continue
                }
                
                let heartRate = trackpoint.heartRateBpm?.value
                let cadence = trackpoint.cadence
                let power = trackpoint.extensions?.tpx?.watts
                
                if let hr = heartRate {
                    heartRates.append(hr)
                }
                if let cad = cadence {
                    cadences.append(cad)
                }
                if let pwr = power {
                    powers.append(pwr)
                }
                
                let point = TrackPoint(
                    latitude: lat,
                    longitude: lon,
                    elevation: trackpoint.altitudeMeters,
                    timestamp: time,
                    heartRate: heartRate,
                    power: power,
                    cadence: cadence,
                    speed: nil,
                    distance: nil
                )
                allTrackPoints.append(point)
            }
        }
        
        guard !allTrackPoints.isEmpty else {
            throw ActivityServiceError.noTrackPoints
        }
        
        // Calculate distance and update track points
        var totalDistance: Double = 0
        var cumulativeDistance: Double = 0
        var elevationGain: Double = 0
        var elevationLoss: Double = 0
        var minElevation: Double?
        var maxElevation: Double?
        
        for (index, point) in allTrackPoints.enumerated() {
            if let elevation = point.elevation {
                if minElevation == nil || elevation < minElevation! {
                    minElevation = elevation
                }
                if maxElevation == nil || elevation > maxElevation! {
                    maxElevation = elevation
                }
                
                if index > 0, let prevElevation = allTrackPoints[index - 1].elevation {
                    let elevationDiff = elevation - prevElevation
                    // Filter out small changes (< 2m) that are likely GPS noise
                    if abs(elevationDiff) >= 2.0 {
                        if elevationDiff > 0 {
                            elevationGain += elevationDiff
                        } else {
                            elevationLoss += abs(elevationDiff)
                        }
                    }
                }
            }
            
            if index > 0 {
                let prevPoint = allTrackPoints[index - 1]
                let distance = calculateDistance(
                    from: CLLocationCoordinate2D(latitude: prevPoint.latitude, longitude: prevPoint.longitude),
                    to: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                )
                cumulativeDistance += distance
                totalDistance += distance
                allTrackPoints[index].distance = cumulativeDistance
            }
        }
        
        // Use lap distance if available, otherwise use calculated
        let distance = lap.distanceMeters ?? totalDistance
        let duration = lap.totalTimeSeconds
        
        let startDate = allTrackPoints.first!.timestamp
        let endDate = allTrackPoints.last!.timestamp
        
        let activityType = determineActivityType(from: fileName, distance: distance)
        
        let activityModel = Activity(
            userId: userId,
            name: activity.id?.description ?? generateActivityName(from: fileName),
            activityType: activityType,
            startDate: startDate,
            endDate: endDate,
            distance: distance,
            duration: duration,
            source: .fileUpload
        )
        
        activityModel.originalFileName = fileName
        activityModel.trackPoints = allTrackPoints
        activityModel.elevationGain = elevationGain > 0 ? elevationGain : nil
        activityModel.elevationLoss = elevationLoss > 0 ? elevationLoss : nil
        activityModel.minElevation = minElevation
        activityModel.maxElevation = maxElevation
        
        if duration > 0 {
            activityModel.avgSpeed = distance / duration
        }
        
        // Calculate heart rate stats
        if !heartRates.isEmpty {
            activityModel.avgHeartRate = Int(heartRates.reduce(0, +) / heartRates.count)
            activityModel.maxHeartRate = heartRates.max()
        }
        
        // Calculate cadence stats
        if !cadences.isEmpty {
            activityModel.avgCadence = Int(cadences.reduce(0, +) / cadences.count)
            activityModel.maxCadence = cadences.max()
        }
        
        // Calculate power stats
        if !powers.isEmpty {
            activityModel.avgPower = powers.reduce(0, +) / Double(powers.count)
            activityModel.maxPower = powers.max()
        }
        
        logger.info("✅ TCX parsed: \(activityModel.name) - \(String(format: "%.2f", distance/1000))km, \(Int(duration/60))min")
        return activityModel
    }
    
    // MARK: - FIT Parsing
    
    private func parseFIT(data: Data, fileName: String, userId: String) async throws -> Activity {
        logger.info("📍 Parsing FIT file")
        
        // TODO: Implement FIT file parsing once FitDataProtocol API is verified
        // The FitDataProtocol package API needs to be checked for the correct type names
        // For now, return an error indicating FIT parsing is not yet implemented
        throw ActivityServiceError.parsingFailed("FIT file parsing is not yet fully implemented. GPX and TCX formats are supported.")
        
        /* 
        // Placeholder implementation - will be completed once correct API is confirmed:
        
        // Decode FIT file
        let fitFile: [FitMessage] // Type name TBD
        do {
            fitFile = try decodeFitFile(data: data) // Method TBD
        } catch {
            throw ActivityServiceError.parsingFailed("FIT decode failed: \(error.localizedDescription)")
        }
        
        // Extract session message for summary data
        var sessionMessage: SessionMessage?
        var activityType: ActivityType = .ride
        var startTime: Date?
        var totalDistance: Double = 0
        var totalDuration: Double = 0
        var avgHeartRate: Int?
        var maxHeartRate: Int?
        var avgPower: Double?
        var maxPower: Double?
        var avgCadence: Int?
        var maxCadence: Int?
        var totalElevationGain: Double = 0
        
        // Extract record messages for track points
        var trackPoints: [TrackPoint] = []
        var heartRates: [Int] = []
        var cadences: [Int] = []
        var powers: [Double] = []
        var elevations: [Double] = []
        var lastPosition: (lat: Double, lon: Double)?
        
        for message in fitFile.messages {
            switch message {
            case let record as RecordMessage:
                // Extract position data
                if let positionLat = record.positionLat,
                   let positionLong = record.positionLong {
                    let lat = Double(positionLat) / 1_000_000.0 // Convert semicircles to degrees
                    let lon = Double(positionLong) / 1_000_000.0
                    
                    let timestamp = record.timestamp ?? Date()
                    let elevation = record.altitude
                    let heartRate = record.heartRate
                    let cadence = record.cadence
                    let power = record.power
                    
                    if let hr = heartRate {
                        heartRates.append(Int(hr))
                    }
                    if let cad = cadence {
                        cadences.append(Int(cad))
                    }
                    if let pwr = power {
                        powers.append(Double(pwr))
                    }
                    if let elev = elevation {
                        elevations.append(elev)
                    }
                    
                    let point = TrackPoint(
                        latitude: lat,
                        longitude: lon,
                        elevation: elevation,
                        timestamp: timestamp,
                        heartRate: heartRate.map { Int($0) },
                        power: power.map { Double($0) },
                        cadence: cadence.map { Int($0) },
                        speed: record.speed,
                        distance: nil
                    )
                    trackPoints.append(point)
                    lastPosition = (lat, lon)
                    
                    if startTime == nil {
                        startTime = timestamp
                    }
                }
                
            case let session as SessionMessage:
                sessionMessage = session
                totalDistance = session.totalDistance ?? 0
                totalDuration = session.totalElapsedTime ?? 0
                avgHeartRate = session.avgHeartRate.map { Int($0) }
                maxHeartRate = session.maxHeartRate.map { Int($0) }
                avgPower = session.avgPower.map { Double($0) }
                maxPower = session.maxPower.map { Double($0) }
                avgCadence = session.avgCadence.map { Int($0) }
                maxCadence = session.maxCadence.map { Int($0) }
                totalElevationGain = session.totalAscent ?? 0
                
                // Determine activity type from sport
                if let sport = session.sport {
                    switch sport {
                    case .running:
                        activityType = .run
                    case .cycling:
                        activityType = .ride
                    case .walking:
                        activityType = .walk
                    default:
                        activityType = determineActivityType(from: fileName, distance: totalDistance)
                    }
                }
                
            default:
                break
            }
        }
        
        guard !trackPoints.isEmpty else {
            throw ActivityServiceError.noTrackPoints
        }
        
        // Calculate distance from track points if not provided
        var calculatedDistance: Double = 0
        var cumulativeDistance: Double = 0
        var elevationGain: Double = 0
        var elevationLoss: Double = 0
        var minElevation: Double?
        var maxElevation: Double?
        
        for (index, point) in trackPoints.enumerated() {
            if let elevation = point.elevation {
                if minElevation == nil || elevation < minElevation! {
                    minElevation = elevation
                }
                if maxElevation == nil || elevation > maxElevation! {
                    maxElevation = elevation
                }
                
                if index > 0, let prevElevation = trackPoints[index - 1].elevation {
                    let elevationDiff = elevation - prevElevation
                    if elevationDiff > 0 {
                        elevationGain += elevationDiff
                    } else {
                        elevationLoss += abs(elevationDiff)
                    }
                }
            }
            
            if index > 0 {
                let prevPoint = trackPoints[index - 1]
                let distance = calculateDistance(
                    from: CLLocationCoordinate2D(latitude: prevPoint.latitude, longitude: prevPoint.longitude),
                    to: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                )
                cumulativeDistance += distance
                calculatedDistance += distance
                trackPoints[index].distance = cumulativeDistance
            }
        }
        
        // Use session distance if available, otherwise use calculated
        let finalDistance = totalDistance > 0 ? totalDistance : calculatedDistance
        let finalDuration = totalDuration > 0 ? totalDuration : trackPoints.last!.timestamp.timeIntervalSince(trackPoints.first!.timestamp)
        
        let startDate = startTime ?? trackPoints.first!.timestamp
        let endDate = trackPoints.last!.timestamp
        
        let activity = Activity(
            userId: userId,
            name: generateActivityName(from: fileName),
            activityType: activityType,
            startDate: startDate,
            endDate: endDate,
            distance: finalDistance,
            duration: finalDuration,
            source: .fileUpload
        )
        
        activity.originalFileName = fileName
        activity.trackPoints = trackPoints
        activity.elevationGain = totalElevationGain > 0 ? totalElevationGain : (elevationGain > 0 ? elevationGain : nil)
        activity.elevationLoss = elevationLoss > 0 ? elevationLoss : nil
        activity.minElevation = minElevation
        activity.maxElevation = maxElevation
        
        if finalDuration > 0 {
            activity.avgSpeed = finalDistance / finalDuration
        }
        
        // Use session stats if available, otherwise calculate from track points
        activity.avgHeartRate = avgHeartRate ?? (heartRates.isEmpty ? nil : Int(heartRates.reduce(0, +) / heartRates.count))
        activity.maxHeartRate = maxHeartRate ?? heartRates.max()
        activity.avgPower = avgPower ?? (powers.isEmpty ? nil : powers.reduce(0, +) / Double(powers.count))
        activity.maxPower = maxPower ?? powers.max()
        activity.avgCadence = avgCadence ?? (cadences.isEmpty ? nil : Int(cadences.reduce(0, +) / cadences.count))
        activity.maxCadence = maxCadence ?? cadences.max()
        
        logger.info("✅ FIT parsed: \(activity.name) - \(String(format: "%.2f", finalDistance/1000))km, \(Int(finalDuration/60))min")
        return activity
        */
    }
    
    // MARK: - Helpers
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    /// Convert track points to PostGIS LineString WKT format
    private func trackPointsToPostGISLineString(_ trackPoints: [TrackPoint]) -> String? {
        let validPoints = trackPoints
            .filter { point in
                point.latitude >= -90 && point.latitude <= 90 &&
                point.longitude >= -180 && point.longitude <= 180 &&
                !(point.latitude == 0 && point.longitude == 0)
            }
        
        guard validPoints.count >= 2 else { return nil }
        
        // PostGIS LineString format: "SRID=4326;LINESTRING(lon lat, lon lat, ...)"
        let coordinates = validPoints.map { "\($0.longitude) \($0.latitude)" }.joined(separator: ", ")
        return "SRID=4326;LINESTRING(\(coordinates))"
    }
    
    /// Convert Activity to backend DTO for Supabase
    private func activityToBackendDTO(_ activity: Activity) -> ActivityBackendDTO {
        let trackPoints = activity.trackPoints ?? []
        let validPoints = trackPoints
            .filter { point in
                point.latitude >= -90 && point.latitude <= 90 &&
                point.longitude >= -180 && point.longitude <= 180 &&
                !(point.latitude == 0 && point.longitude == 0)
            }
        
        let startPoint = validPoints.first
        let endPoint = validPoints.last
        
        return ActivityBackendDTO(
            activityId: activity.id,
            userId: activity.userId,
            activityType: activity.activityType.rawValue,
            name: activity.name,
            description: nil,
            distanceM: activity.distance,
            durationSec: Int(activity.duration),
            elevationGainM: activity.elevationGain,
            elevationLossM: activity.elevationLoss,
            maxElevation: activity.maxElevation,
            minElevation: activity.minElevation,
            avgHeartRate: activity.avgHeartRate,
            maxHeartRate: activity.maxHeartRate,
            avgPower: activity.avgPower.map { Int($0) },
            maxPower: activity.maxPower.map { Int($0) },
            avgCadence: activity.avgCadence,
            maxCadence: activity.maxCadence,
            startTime: activity.startDate,
            endTime: activity.endDate,
            startLat: startPoint?.latitude,
            startLon: startPoint?.longitude,
            endLat: endPoint?.latitude,
            endLon: endPoint?.longitude,
            geom: trackPointsToPostGISLineString(trackPoints),
            visibility: activity.isPrivate ? "private" : "public",
            fileUrl: activity.rawFileURL,
            originalFileName: activity.originalFileName
        )
    }
    
    private func determineActivityType(from fileName: String, distance: Double) -> ActivityType {
        let lowercased = fileName.lowercased()
        
        if lowercased.contains("run") || lowercased.contains("running") {
            return .run
        } else if lowercased.contains("ride") || lowercased.contains("cycling") || lowercased.contains("bike") {
            return .ride
        } else if lowercased.contains("walk") || lowercased.contains("walking") {
            return .walk
        } else if lowercased.contains("hike") || lowercased.contains("hiking") {
            return .hike
        } else if lowercased.contains("swim") || lowercased.contains("swimming") {
            return .swim
        } else if lowercased.contains("ski") || lowercased.contains("skiing") {
            return .ski
        }
        
        // Default based on distance/speed
        if distance > 0 {
            let avgSpeedKmh = (distance / 1000) / (3600 / 1000) // rough estimate
            if avgSpeedKmh < 6 {
                return .walk
            } else if avgSpeedKmh < 15 {
                return .run
            } else {
                return .ride
            }
        }
        
        return .other
    }
    
    private func generateActivityName(from fileName: String) -> String {
        // Remove file extension
        let nameWithoutExtension = fileName.replacingOccurrences(of: #"\.(gpx|tcx|fit)$"#, with: "", options: .regularExpression)
        
        // If filename is descriptive, use it
        if nameWithoutExtension.count > 3 {
            return nameWithoutExtension.replacingOccurrences(of: "_", with: " ").capitalized
        }
        
        // Otherwise, generate a name based on date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Activity \(formatter.string(from: Date()))"
    }
    
    // MARK: - Storage
    
    /// Save activity to local SwiftData and sync to backend
    func saveActivity(
        _ activity: Activity,
        modelContext: ModelContext
    ) async throws {
        logger.info("💾 Saving activity: \(activity.name)")
        
        // Save to SwiftData
        modelContext.insert(activity)
        try modelContext.save()
        
        // Sync to Supabase backend
        do {
            // Get valid access token, refreshing if necessary
            let accessToken = try await AuthenticationService.shared.getValidAccessToken()
            
            let backendDTO = activityToBackendDTO(activity)
            try await SupabaseClient.shared.upsert(
                table: "activities",
                data: backendDTO,
                accessToken: accessToken
            )
            
            logger.info("✅ Activity synced to backend")
        } catch {
            // Log error but don't fail the save - activity is saved locally
            logger.error("❌ Failed to sync activity to backend: \(error.localizedDescription)")
            // Don't throw - we want local save to succeed even if backend sync fails
        }
        
        // Track analytics
        ObservabilityManager.shared.track(event: "activity_created", properties: [
            "activity_id": activity.id,
            "activity_type": activity.activityType.rawValue,
            "source": activity.source.rawValue,
            "distance_km": activity.distance / 1000,
            "duration_min": activity.duration / 60
        ])
        
        logger.info("✅ Activity saved successfully")
    }
    
    /// Fetch all activities for a user (from local SwiftData)
    func fetchActivities(
        for userId: String,
        modelContext: ModelContext
    ) throws -> [Activity] {
        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.userId == userId
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// Sync activities from backend to local storage
    func syncActivitiesFromBackend(
        for userId: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("🔄 Syncing activities from backend for user: \(userId)")
        
        // Get valid access token, refreshing if necessary
        let accessToken = try await AuthenticationService.shared.getValidAccessToken()
        
        // Fetch activities from backend
        // Note: We exclude 'geom' from the select because:
        // 1. PostgREST returns PostGIS geometry as GeoJSON, not WKT
        // 2. PostgREST doesn't support SQL functions like ST_AsText() in select parameter
        // 3. We don't reconstruct track points from geometry anyway (activities synced from backend have nil trackPoints)
        // The geom field will be nil in the DTO, which is fine since we're not using it
        let selectFields = """
            activity_id,user_id,activity_type,name,description,distance_m,duration_sec,\
            elevation_gain_m,elevation_loss_m,max_elevation,min_elevation,\
            avg_heart_rate,max_heart_rate,avg_power,max_power,avg_cadence,max_cadence,\
            start_time,end_time,start_lat,start_lon,end_lat,end_lon,\
            visibility,file_url,original_file_name
            """
        let backendActivities: [ActivityBackendDTO] = try await SupabaseClient.shared.fetch(
            from: "activities",
            select: selectFields,
            filter: ["user_id": userId],
            accessToken: accessToken
        )
        
        logger.info("📥 Fetched \(backendActivities.count) activities from backend")
        
        // Get existing local activities
        let localActivities = try fetchActivities(for: userId, modelContext: modelContext)
        let localActivityIDs = Set(localActivities.map { $0.id })
        
        // Convert backend DTOs to Activity models and merge
        for backendDTO in backendActivities {
            guard let activityId = backendDTO.activityId else {
                logger.warning("⚠️ Backend activity missing activity_id, skipping")
                continue
            }
            
            // Check if activity already exists locally
            if localActivityIDs.contains(activityId) {
                // Update existing activity if backend version is newer
                // For now, skip updates - we'll implement conflict resolution later
                logger.debug("Activity \(activityId) already exists locally, skipping")
                continue
            } else {
                // Create new activity from backend data
                let activity = activityFromBackendDTO(backendDTO, userId: userId)
                modelContext.insert(activity)
                logger.debug("Inserted activity from backend: \(activityId)")
            }
        }
        
        try modelContext.save()
        logger.info("✅ Activities synced from backend")
    }
    
    /// Convert backend DTO to Activity model
    private func activityFromBackendDTO(_ dto: ActivityBackendDTO, userId: String) -> Activity {
        // Use activity_id from backend as the ID, or generate a new UUID if missing
        let activityId = dto.activityId ?? UUID().uuidString
        
        let activity = Activity(
            id: activityId,
            userId: userId,
            name: dto.name,
            activityType: ActivityType(rawValue: dto.activityType) ?? .other,
            startDate: dto.startTime,
            endDate: dto.endTime ?? dto.startTime,
            distance: dto.distanceM,
            duration: Double(dto.durationSec),
            source: .fileUpload,
            isPrivate: dto.visibility == "private"
        )
        
        activity.elevationGain = dto.elevationGainM
        activity.elevationLoss = dto.elevationLossM
        activity.maxElevation = dto.maxElevation
        activity.minElevation = dto.minElevation
        activity.avgHeartRate = dto.avgHeartRate
        activity.maxHeartRate = dto.maxHeartRate
        activity.avgPower = dto.avgPower.map { Double($0) }
        activity.maxPower = dto.maxPower.map { Double($0) }
        activity.avgCadence = dto.avgCadence
        activity.maxCadence = dto.maxCadence
        activity.rawFileURL = dto.fileUrl
        activity.originalFileName = dto.originalFileName
        
        // Calculate avg speed from distance and duration
        if dto.durationSec > 0 {
            activity.avgSpeed = dto.distanceM / Double(dto.durationSec)
        }
        
        // Note: Track points are not stored individually in backend
        // They're stored as PostGIS geometry. We can't reconstruct individual
        // track points from the LineString, so trackPoints will be nil for
        // activities synced from backend.
        
        return activity
    }
    
    /// Delete an activity
    func deleteActivity(
        _ activity: Activity,
        modelContext: ModelContext
    ) async throws {
        logger.info("🗑️ Deleting activity: \(activity.name)")
        
        // Delete from backend
        do {
            // Get valid access token, refreshing if necessary
            let accessToken = try await AuthenticationService.shared.getValidAccessToken()
            
            logger.info("🗑️ Deleting activity from backend: \(activity.id)")
            try await SupabaseClient.shared.delete(
                table: "activities",
                filter: ["activity_id": activity.id],
                accessToken: accessToken
            )
        } catch {
            logger.warning("⚠️ Failed to delete activity from backend: \(error.localizedDescription)")
            // Continue with local delete even if backend delete fails
        }
        
        // Delete from local storage
        modelContext.delete(activity)
        try modelContext.save()
        
        ObservabilityManager.shared.track(event: "activity_deleted", properties: [
            "activity_id": activity.id
        ])
        
        logger.info("✅ Activity deleted successfully")
    }
    
    /// Recalculate metrics from existing track points
    /// Useful for activities that were uploaded before proper parsing was implemented
    func recalculateMetrics(
        for activity: Activity,
        modelContext: ModelContext
    ) async throws {
        logger.info("🔄 Recalculating metrics for activity: \(activity.name)")
        
        guard let trackPoints = activity.trackPoints, !trackPoints.isEmpty else {
            logger.warning("No track points available for recalculation")
            throw ActivityServiceError.noTrackPoints
        }
        
        // Sort track points by timestamp to ensure correct order
        let sortedPoints = trackPoints.sorted { $0.timestamp < $1.timestamp }
        
        guard !sortedPoints.isEmpty else {
            throw ActivityServiceError.noTrackPoints
        }
        
        // Filter out invalid coordinates (0,0 or out of valid range)
        let validPoints = sortedPoints.filter { point in
            point.latitude >= -90 && point.latitude <= 90 &&
            point.longitude >= -180 && point.longitude <= 180 &&
            !(point.latitude == 0 && point.longitude == 0)
        }
        
        guard validPoints.count >= 2 else {
            throw ActivityServiceError.noTrackPoints
        }
        
        // Recalculate all metrics
        let startDate = validPoints.first!.timestamp
        let endDate = validPoints.last!.timestamp
        let duration = endDate.timeIntervalSince(startDate)
        
        var totalDistance: Double = 0
        var elevationGain: Double = 0
        var elevationLoss: Double = 0
        var minElevation: Double?
        var maxElevation: Double?
        var speeds: [Double] = []
        
        for (index, point) in validPoints.enumerated() {
            // Update elevation stats
            if let elevation = point.elevation {
                if minElevation == nil || elevation < minElevation! {
                    minElevation = elevation
                }
                if maxElevation == nil || elevation > maxElevation! {
                    maxElevation = elevation
                }
                
                if index > 0, let prevElevation = validPoints[index - 1].elevation {
                    let elevationDiff = elevation - prevElevation
                    // Filter out small changes (< 2m) that are likely GPS noise
                    if abs(elevationDiff) >= 2.0 {
                        if elevationDiff > 0 {
                            elevationGain += elevationDiff
                        } else {
                            elevationLoss += abs(elevationDiff)
                        }
                    }
                }
            }
            
            // Calculate distance
            if index > 0 {
                let prevPoint = validPoints[index - 1]
                let distance = calculateDistance(
                    from: CLLocationCoordinate2D(latitude: prevPoint.latitude, longitude: prevPoint.longitude),
                    to: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                )
                totalDistance += distance
                
                // Calculate speed
                let timeDiff = point.timestamp.timeIntervalSince(prevPoint.timestamp)
                if timeDiff > 0 {
                    let speed = distance / timeDiff
                    speeds.append(speed)
                }
            }
        }
        
        // Update activity with recalculated metrics
        activity.startDate = startDate
        activity.endDate = endDate
        activity.duration = duration
        activity.distance = totalDistance
        activity.elevationGain = elevationGain > 0 ? elevationGain : nil
        activity.elevationLoss = elevationLoss > 0 ? elevationLoss : nil
        activity.minElevation = minElevation
        activity.maxElevation = maxElevation
        
        if !speeds.isEmpty {
            activity.avgSpeed = speeds.reduce(0, +) / Double(speeds.count)
            activity.maxSpeed = speeds.max()
        } else if duration > 0 {
            activity.avgSpeed = totalDistance / duration
        }
        
        activity.updatedAt = Date()
        
        // Update track points order
        activity.trackPoints = validPoints
        
        try modelContext.save()
        
        logger.info("✅ Metrics recalculated: \(String(format: "%.2f", totalDistance/1000))km, \(Int(duration/60))min")
    }
    
    /// Check if an activity needs recalculation (has trackPoints but metrics might be wrong)
    func needsRecalculation(_ activity: Activity) -> Bool {
        // If activity has trackPoints but distance/duration seem suspicious (round numbers)
        // or if trackPoints exist but metrics don't match
        if let trackPoints = activity.trackPoints, !trackPoints.isEmpty {
            // Check if distance is a suspiciously round number (likely placeholder)
            let distanceKm = activity.distance / 1000
            _ = distanceKm.truncatingRemainder(dividingBy: 1) == 0 || 
                    distanceKm.truncatingRemainder(dividingBy: 0.5) == 0
            
            // If distance is exactly 5km, 20km, 40km (old placeholder values), needs recalculation
            if distanceKm == 5.0 || distanceKm == 20.0 || distanceKm == 40.0 {
                return true
            }
            
            // If we have trackPoints but the calculated distance from them would be very different
            // This is a heuristic - if trackPoints exist, we should be able to recalculate
            return false // For now, only flag obvious placeholder values
        }
        
        return false
    }
}

// MARK: - TCX XML Structures

struct TrainingCenterDatabase: Codable {
    let activities: Activities
}

struct Activities: Codable {
    let activity: [TCXActivity]
}

struct TCXActivity: Codable {
    let id: String?
    let lap: [Lap]
}

struct Lap: Codable {
    let totalTimeSeconds: Double
    let distanceMeters: Double?
    let track: Track?
}

struct Track: Codable {
    let trackpoint: [Trackpoint]
}

struct Trackpoint: Codable {
    let time: Date?
    let position: Position?
    let altitudeMeters: Double?
    let heartRateBpm: HeartRateBpm?
    let cadence: Int?
    let extensions: Extensions?
}

struct Position: Codable {
    let latitudeDegrees: Double?
    let longitudeDegrees: Double?
}

struct HeartRateBpm: Codable {
    let value: Int?
}

struct Extensions: Codable {
    let tpx: TPX?
}

struct TPX: Codable {
    let watts: Double?
}

// MARK: - Errors

enum ActivityServiceError: Error, LocalizedError {
    case unsupportedFileFormat(String)
    case invalidFileData
    case parsingFailed(String)
    case noTrackPoints
    case invalidCoordinates
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFileFormat(let format):
            return "Unsupported file format: .\(format). Please use GPX, TCX, or FIT files."
        case .invalidFileData:
            return "The file data is invalid or corrupted."
        case .parsingFailed(let reason):
            return "Failed to parse activity file: \(reason)"
        case .noTrackPoints:
            return "No GPS data found in the activity file."
        case .invalidCoordinates:
            return "The GPS coordinates in the file are invalid."
        case .notAuthenticated:
            return "You must be signed in to sync activities."
        }
    }
}
