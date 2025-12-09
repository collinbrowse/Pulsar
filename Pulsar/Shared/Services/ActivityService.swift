//
//  ActivityService.swift
//  Pulsar
//
//  Created on 10/27/25.
//

// swiftlint:disable file_length
// Justification: Comprehensive activity service with multiple file format parsers requires extensive code

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
// swiftlint:disable:next type_body_length
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
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func parseGPX(data: Data, fileName: String, userId: String) async throws -> Activity { // swiftlint:disable:this function_body_length cyclomatic_complexity
        // Justification: GPX parsing requires extensive validation and metric calculation logic
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
        guard let firstPoint = trackPoints.first, let lastPoint = trackPoints.last else {
            throw ActivityServiceError.noTrackPoints
        }
        let startDate = firstPoint.timestamp
        let endDate = lastPoint.timestamp
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
                if let currentMin = minElevation {
                    if elevation < currentMin {
                        minElevation = elevation
                    }
                } else {
                    minElevation = elevation
                }
                if let currentMax = maxElevation {
                    if elevation > currentMax {
                        maxElevation = elevation
                    }
                } else {
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
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func parseTCX(data: Data, fileName: String, userId: String) async throws -> Activity { // swiftlint:disable:this function_body_length cyclomatic_complexity
        // Justification: TCX parsing requires extensive validation and metric calculation logic
        logger.info("📍 Parsing TCX file")
        
        guard !data.isEmpty else {
            throw ActivityServiceError.invalidFileData
        }
        
        let decoder = XMLDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.shouldProcessNamespaces = false
        
        let tcx: TrainingCenterDatabase
        do {
            tcx = try decoder.decode(TrainingCenterDatabase.self, from: data)
        } catch {
            logger.error("TCX decode error: \(String(describing: error))")
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
                if let currentMin = minElevation {
                    if elevation < currentMin {
                        minElevation = elevation
                    }
                } else {
                    minElevation = elevation
                }
                if let currentMax = maxElevation {
                    if elevation > currentMax {
                        maxElevation = elevation
                    }
                } else {
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
        
        guard let firstPoint = allTrackPoints.first, let lastPoint = allTrackPoints.last else {
            throw ActivityServiceError.noTrackPoints
        }
        let startDate = firstPoint.timestamp
        let endDate = lastPoint.timestamp
        
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
        
        // swiftlint:disable:next todo
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
                if let currentMin = minElevation {
                    if elevation < currentMin {
                        minElevation = elevation
                    }
                } else {
                    minElevation = elevation
                }
                if let currentMax = maxElevation {
                    if elevation > currentMax {
                        maxElevation = elevation
                    }
                } else {
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
    
    /// Parse PostGIS LineString (WKT or GeoJSON) and reconstruct track points
    /// WKT Format: "SRID=4326;LINESTRING(lon lat, lon lat, ...)"
    /// GeoJSON Format: {"type":"LineString","coordinates":[[lon,lat],[lon,lat],...]}
    private func postGISLineStringToTrackPoints(_ geometry: String?, startTime: Date, endTime: Date) -> [TrackPoint]? {
        guard let geometry = geometry, !geometry.isEmpty else { return nil }
        
        var coordinatePairs: [(lon: Double, lat: Double, elevation: Double?)] = []
        
        // Try parsing as GeoJSON first (PostgREST returns this by default)
        if geometry.trimmingCharacters(in: .whitespaces).hasPrefix("{") {
            // Parse GeoJSON
            guard let data = geometry.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String,
                  type == "LineString",
                  let coordinates = json["coordinates"] as? [[Any]] else {
                logger.warning("⚠️ Invalid GeoJSON LineString format")
                return nil
            }
            
            for coordArray in coordinates {
                guard coordArray.count >= 2 else {
                    logger.warning("⚠️ Coordinate array has insufficient elements: \(coordArray.count)")
                    continue
                }
                
                // GeoJSON standard format is [lon, lat, elevation?]
                // PostgREST/PostGIS should return coordinates in this format
                guard let first = coordArray[0] as? Double,
                      let second = coordArray[1] as? Double else {
                    logger.warning("⚠️ Invalid coordinate types in array")
                    continue
                }
                
                // GeoJSON standard is [lon, lat]
                // However, some systems might reverse this, so we check the values
                // Longitude typically has larger absolute values than latitude for most locations
                // But this is not reliable, so we'll use a heuristic:
                // If first value is clearly a longitude (abs > 90) or second is clearly a latitude (abs <= 90)
                // Otherwise, assume standard GeoJSON order [lon, lat]
                let lon: Double
                let lat: Double
                
                // Heuristic: if first value is outside latitude range but within longitude range, it's likely lon
                // If second value is within latitude range, it's likely lat
                if (abs(first) > 90 && abs(first) <= 180) || (abs(second) <= 90 && abs(first) > abs(second)) {
                    // First is likely longitude, second is likely latitude (GeoJSON standard)
                    lon = first
                    lat = second
                } else if (abs(second) > 90 && abs(second) <= 180) || (abs(first) <= 90 && abs(second) > abs(first)) {
                    // Reversed: first is latitude, second is longitude
                    logger.warning("⚠️ GeoJSON coordinates appear reversed (first=\(first), second=\(second)), correcting")
                    lat = first
                    lon = second
                } else {
                    // Ambiguous - assume GeoJSON standard [lon, lat]
                    // Log first few to help debug
                    if coordinatePairs.count < 3 {
                        logger.debug("Ambiguous coordinate order, assuming [lon, lat]: [\(first), \(second)]")
                    }
                    lon = first
                    lat = second
                }
                
                let elevation = coordArray.count >= 3 ? coordArray[2] as? Double : nil
                
                // Validate coordinates before adding
                guard lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180 else {
                    logger.warning("⚠️ Invalid coordinate: lat=\(lat), lon=\(lon)")
                    continue
                }
                
                coordinatePairs.append((lon: lon, lat: lat, elevation: elevation))
            }
        } else {
            // Parse WKT format
            guard let linestringStart = geometry.range(of: "LINESTRING("),
                  let linestringEnd = geometry.range(of: ")", range: linestringStart.upperBound..<geometry.endIndex) else {
                logger.warning("⚠️ Invalid PostGIS LineString WKT format: \(geometry)")
                return nil
            }
            
            let coordinatesString = String(geometry[linestringStart.upperBound..<linestringEnd.lowerBound])
            let pairs = coordinatesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            for pair in pairs {
                let components = pair.split(separator: " ").map { $0.trimmingCharacters(in: .whitespaces) }
                guard components.count >= 2,
                      let lon = Double(components[0]),
                      let lat = Double(components[1]) else {
                    continue
                }
                let elevation = components.count >= 3 ? Double(components[2]) : nil
                coordinatePairs.append((lon: lon, lat: lat, elevation: elevation))
            }
        }
        
        guard coordinatePairs.count >= 2 else {
            logger.warning("⚠️ LineString has insufficient coordinates: \(coordinatePairs.count)")
            return nil
        }
        
        // Create track points with interpolated timestamps
        // IMPORTANT: Process coordinates in the EXACT order they appear in the GeoJSON array
        // This preserves the sequential path order from PostGIS
        // DO NOT deduplicate - preserve all coordinates including stationary points
        // DO NOT sort - preserve the coordinate order from PostGIS
        var trackPoints: [TrackPoint] = []
        let duration = endTime.timeIntervalSince(startTime)
        let timeInterval = coordinatePairs.count > 1 ? duration / Double(coordinatePairs.count - 1) : 0
        
        for (index, pair) in coordinatePairs.enumerated() {
            // Validate coordinates
            guard pair.lat >= -90 && pair.lat <= 90 && pair.lon >= -180 && pair.lon <= 180 else {
                continue
            }
            
            // Interpolate timestamp evenly across the activity duration
            // Note: We can't recover original timestamps from PostGIS geometry,
            // but we preserve the coordinate order which is critical for correct path rendering
            let timestamp = startTime.addingTimeInterval(timeInterval * Double(index))
            
            let point = TrackPoint(
                latitude: pair.lat,
                longitude: pair.lon,
                elevation: pair.elevation,
                timestamp: timestamp,
                heartRate: nil,
                power: nil,
                cadence: nil,
                speed: nil,
                distance: nil
            )
            trackPoints.append(point)
        }
        
        guard !trackPoints.isEmpty else { return nil }
        
        // Log first and last coordinates for debugging
        if let first = trackPoints.first, let last = trackPoints.last {
            logger.debug("✅ Reconstructed \(trackPoints.count) track points from PostGIS geometry")
            logger.debug("   First point: lat=\(first.latitude), lon=\(first.longitude)")
            logger.debug("   Last point: lat=\(last.latitude), lon=\(last.longitude)")
            
            // Check coordinate spread for debugging
            let allLats = trackPoints.map { $0.latitude }
            let allLons = trackPoints.map { $0.longitude }
            let latRange = (allLats.max() ?? 0) - (allLats.min() ?? 0)
            let lonRange = (allLons.max() ?? 0) - (allLons.min() ?? 0)
            logger.debug("   Coordinate spread: lat=\(String(format: "%.6f", latRange)), lon=\(String(format: "%.6f", lonRange))")
        }
        
        // Return points in the exact order they appear in PostGIS geometry
        // This preserves the correct path shape, including stationary periods
        return trackPoints
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
        modelContext: ModelContext,
        appState: AppState
    ) async throws {
        logger.info("💾 Saving activity: \(activity.name)")
        
        // Save to SwiftData
        modelContext.insert(activity)
        try modelContext.save()
        
        // Sync to Supabase backend
        do {
            // Get valid access token, refreshing if necessary
            let accessToken = try await AuthenticationService.shared.getValidAccessToken(appState: appState)
            
            let backendDTO = activityToBackendDTO(activity)
            try await SupabaseClient.shared.upsert(
                table: "activities",
                data: backendDTO,
                accessToken: accessToken
            )
            
            // Mark as synced only after successful backend sync
            activity.lastSyncedAt = Date()
            try modelContext.save()
            
            logger.info("✅ Activity synced to backend")
        } catch let error as AuthError where error == .notAuthenticated {
            // Authentication error - logout user and redirect
            logger.error("❌ Authentication failed - logging out user")
            AuthenticationService.shared.signOutAndRedirect(appState: appState, reason: "Your session has expired. Please sign in again.")
            // Leave lastSyncedAt as nil to mark for retry after re-authentication
            return // Exit early after logout
        } catch let networkError as NetworkError {
            // Check if it's an authentication-related HTTP error (401)
            if case .httpError(let statusCode, _, _) = networkError, statusCode == 401 {
                // 401 Unauthorized - authentication error, logout
                logger.error("❌ Authentication failed (401) - logging out user")
                AuthenticationService.shared.signOutAndRedirect(appState: appState, reason: "Your session has expired. Please sign in again.")
                return // Exit early after logout
            } else {
                // Other network errors (500, timeout, etc.) - don't logout
                logger.error("❌ Network error syncing activity to backend: \(networkError.localizedDescription)")
                // Leave lastSyncedAt as nil to mark for retry
            }
        } catch let urlError as URLError {
            // URLSession errors (connection failures, timeouts) - don't logout
            logger.error("❌ Network connection error syncing activity: \(urlError.localizedDescription)")
            // Leave lastSyncedAt as nil to mark for retry
        } catch {
            // Other errors - don't logout, just log and retry later
            logger.error("❌ Failed to sync activity to backend: \(error.localizedDescription)")
            // Leave lastSyncedAt as nil to mark for retry
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
        modelContext: ModelContext,
        appState: AppState
    ) async throws {
        logger.info("🔄 Syncing activities from backend for user: \(userId)")
        
        // Validate authentication before syncing
        guard AuthenticationService.shared.validateAuthentication() else {
            logger.error("❌ Authentication invalid - logging out user")
            AuthenticationService.shared.signOutAndRedirect(
                appState: appState,
                reason: "Your session has expired. Please sign in again."
            )
            throw AuthError.notAuthenticated
        }
        
        // Get valid access token, refreshing if necessary
        let accessToken = try await AuthenticationService.shared.getValidAccessToken()
        
        // Fetch activities from backend
        // Note: PostgREST returns PostGIS geometry as GeoJSON object
        // We'll decode it in ActivityBackendDTO and convert to JSON string for parsing
        let selectFields = """
            activity_id,user_id,activity_type,name,description,distance_m,duration_sec,\
            elevation_gain_m,elevation_loss_m,max_elevation,min_elevation,\
            avg_heart_rate,max_heart_rate,avg_power,max_power,avg_cadence,max_cadence,\
            start_time,end_time,start_lat,start_lon,end_lat,end_lon,\
            geom,visibility,file_url,original_file_name
            """
        let backendActivities: [ActivityBackendDTO]
        do {
            backendActivities = try await SupabaseClient.shared.fetch(
                from: "activities",
                select: selectFields,
                filter: ["user_id": userId],
                accessToken: accessToken
            )
        } catch let networkError as NetworkError {
            // Check if it's an authentication-related HTTP error (401)
            if case .httpError(let statusCode, _, _) = networkError, statusCode == 401 {
                logger.error("❌ Authentication failed (401) - logging out user")
                AuthenticationService.shared.signOutAndRedirect(
                    appState: appState,
                    reason: "Your session has expired. Please sign in again."
                )
                throw AuthError.notAuthenticated
            } else {
                // Other network errors - rethrow for caller to handle
                throw networkError
            }
        }
        
        logger.info("📥 Fetched \(backendActivities.count) activities from backend")
        
        // Get existing local activities
        let localActivities = try fetchActivities(for: userId, modelContext: modelContext)
        let localActivityIDs = Set(localActivities.map { $0.id })
        logger.debug("📋 Found \(localActivities.count) local activities with IDs: \(Array(localActivityIDs.prefix(5)))")
        
        // Convert backend DTOs to Activity models and merge
        for backendDTO in backendActivities {
            guard let activityId = backendDTO.activityId else {
                logger.warning("⚠️ Backend activity missing activity_id, skipping. Name: \(backendDTO.name)")
                continue
            }
            
            logger.debug("🔄 Processing backend activity: ID=\(activityId), name=\(backendDTO.name)")
            
            // First check: Quick Set lookup
            if localActivityIDs.contains(activityId) {
                logger.debug("Activity \(activityId) already exists locally (Set check), skipping")
                continue
            }
            
            // Second check: Direct query to modelContext to catch any timing issues
            // This is important because SwiftData might not have committed the previous insert yet
            let idDescriptor = FetchDescriptor<Activity>(
                predicate: #Predicate<Activity> { activity in
                    activity.id == activityId && activity.userId == userId
                }
            )
            if let existingActivity = try? modelContext.fetch(idDescriptor).first {
                logger.debug("Activity \(activityId) found in direct query, skipping duplicate insert")
                // Update lastSyncedAt if it's not set (in case this is a local activity that just synced)
                if existingActivity.lastSyncedAt == nil {
                    existingActivity.lastSyncedAt = Date()
                    try? modelContext.save()
                }
                continue
            }
            
            // Third check: Fallback - check by name and startDate to catch any ID mismatches
            // This helps if the backend somehow returns a different ID than what we sent
            // We fetch all user activities and filter in Swift since predicates can't use external values
            if let existingActivity = localActivities.first(where: { activity in
                // Match by name and start date (within 1 minute)
                activity.name == backendDTO.name &&
                abs(activity.startDate.timeIntervalSince(backendDTO.startTime)) < 60.0
            }) {
                logger.warning("⚠️ Activity with matching name/date found but different ID. Local ID: \(existingActivity.id), Backend ID: \(activityId). Skipping duplicate insert.")
                // Update the existing activity's lastSyncedAt
                if existingActivity.lastSyncedAt == nil {
                    existingActivity.lastSyncedAt = Date()
                    try? modelContext.save()
                }
                continue
            }
            
            // All checks passed - create new activity from backend data
            let activity = activityFromBackendDTO(backendDTO, userId: userId)
            modelContext.insert(activity)
            logger.debug("Inserted activity from backend: \(activityId)")
        }
        
        try modelContext.save()
        logger.info("✅ Activities synced from backend")
    }
    
    /// Retry syncing activities that failed to sync to backend
    func syncPendingActivities(
        for userId: String,
        modelContext: ModelContext,
        appState: AppState
    ) async {
        logger.info("🔄 Retrying sync for pending activities for user: \(userId)")
        
        // Validate authentication before syncing
        guard AuthenticationService.shared.validateAuthentication() else {
            logger.error("❌ Authentication invalid - logging out user")
            AuthenticationService.shared.signOutAndRedirect(
                appState: appState,
                reason: "Your session has expired. Please sign in again."
            )
            return
        }
        
        // Find all activities with nil lastSyncedAt (never synced or failed sync)
        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.userId == userId && activity.lastSyncedAt == nil
            }
        )
        
        guard let pendingActivities = try? modelContext.fetch(descriptor), !pendingActivities.isEmpty else {
            logger.debug("No pending activities to sync")
            return
        }
        
        logger.info("📤 Found \(pendingActivities.count) pending activities to sync")
        
        // Attempt to sync each pending activity
        for activity in pendingActivities {
            do {
                // Get valid access token, refreshing if necessary
                let accessToken = try await AuthenticationService.shared.getValidAccessToken()
                
                let backendDTO = activityToBackendDTO(activity)
                try await SupabaseClient.shared.upsert(
                    table: "activities",
                    data: backendDTO,
                    accessToken: accessToken
                )
                
                // Mark as synced after successful backend sync
                activity.lastSyncedAt = Date()
                try modelContext.save()
                
                logger.info("✅ Retried sync for activity: \(activity.name)")
            } catch let error as AuthError where error == .notAuthenticated {
                // Authentication error - logout and stop retrying
                logger.error("❌ Authentication failed during retry - logging out user")
                AuthenticationService.shared.signOutAndRedirect(
                    appState: appState,
                    reason: "Your session has expired. Please sign in again."
                )
                return
            } catch let networkError as NetworkError {
                // Check if it's an authentication-related HTTP error (401)
                if case .httpError(let statusCode, _, _) = networkError, statusCode == 401 {
                    logger.error("❌ Authentication failed (401) during retry - logging out user")
                    AuthenticationService.shared.signOutAndRedirect(
                        appState: appState,
                        reason: "Your session has expired. Please sign in again."
                    )
                    return
                } else {
                    // Other network errors - log but continue with other activities
                    logger.error("❌ Network error retrying sync for activity \(activity.id): \(networkError.localizedDescription)")
                }
            } catch let urlError as URLError {
                // URLSession errors - don't logout, just log and continue
                logger.error("❌ Network connection error retrying sync for activity \(activity.id): \(urlError.localizedDescription)")
            } catch {
                // Other errors - log but continue with other activities
                logger.error("❌ Failed to retry sync for activity \(activity.id): \(error.localizedDescription)")
            }
        }
        
        logger.info("✅ Finished retrying sync for pending activities")
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
        
        // Reconstruct track points from PostGIS LineString geometry
        if let geom = dto.geom {
            let reconstructedPoints = postGISLineStringToTrackPoints(
                geom,
                startTime: dto.startTime,
                endTime: dto.endTime ?? dto.startTime
            )
            activity.trackPoints = reconstructedPoints
        }
        
        // Mark as synced since it came from backend
        activity.lastSyncedAt = Date()
        
        return activity
    }
    
    /// Delete an activity
    func deleteActivity(
        _ activity: Activity,
        modelContext: ModelContext,
        appState: AppState
    ) async throws {
        logger.info("🗑️ Deleting activity: \(activity.name)")
        
        // Validate authentication before deleting
        guard AuthenticationService.shared.validateAuthentication() else {
            logger.error("❌ Authentication invalid - logging out user")
            AuthenticationService.shared.signOutAndRedirect(
                appState: appState,
                reason: "Your session has expired. Please sign in again."
            )
            throw AuthError.notAuthenticated
        }
        
        // Delete from backend
        do {
            // Get valid access token, refreshing if necessary
            let accessToken = try await AuthenticationService.shared.getValidAccessToken(appState: appState)
            
            logger.info("🗑️ Deleting activity from backend: \(activity.id)")
            try await SupabaseClient.shared.delete(
                table: "activities",
                filter: ["activity_id": activity.id],
                accessToken: accessToken
            )
        } catch let error as AuthError where error == .notAuthenticated {
            // Authentication error - logout user
            logger.error("❌ Authentication failed during delete - logging out user")
            AuthenticationService.shared.signOutAndRedirect(
                appState: appState,
                reason: "Your session has expired. Please sign in again."
            )
            throw error
        } catch let networkError as NetworkError {
            // Check if it's an authentication-related HTTP error (401)
            if case .httpError(let statusCode, _, _) = networkError, statusCode == 401 {
                logger.error("❌ Authentication failed (401) during delete - logging out user")
                AuthenticationService.shared.signOutAndRedirect(
                    appState: appState,
                    reason: "Your session has expired. Please sign in again."
                )
                throw AuthError.notAuthenticated
            } else {
                // Other network errors - log but continue with local delete
                logger.warning("⚠️ Network error deleting activity from backend: \(networkError.localizedDescription)")
                // Continue with local delete even if backend delete fails
            }
        } catch let urlError as URLError {
            // URLSession errors - don't logout, just log and continue with local delete
            logger.warning("⚠️ Network connection error deleting activity from backend: \(urlError.localizedDescription)")
            // Continue with local delete even if backend delete fails
        } catch {
            // Other errors - log but continue with local delete
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
    func recalculateMetrics( // swiftlint:disable:this function_body_length cyclomatic_complexity
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
        guard let firstPoint = validPoints.first, let lastPoint = validPoints.last else {
            throw ActivityServiceError.noTrackPoints
        }
        let startDate = firstPoint.timestamp
        let endDate = lastPoint.timestamp
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
                if let currentMin = minElevation {
                    if elevation < currentMin {
                        minElevation = elevation
                    }
                } else {
                    minElevation = elevation
                }
                if let currentMax = maxElevation {
                    if elevation > currentMax {
                        maxElevation = elevation
                    }
                } else {
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
    
    enum CodingKeys: String, CodingKey {
        case activities = "Activities"
    }
}

struct Activities: Codable {
    let activity: [TCXActivity]
    
    enum CodingKeys: String, CodingKey {
        case activity = "Activity"
    }
}

struct TCXActivity: Codable {
    let id: String?
    let lap: [Lap]
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case lap = "Lap"
    }
}

struct Lap: Codable {
    let totalTimeSeconds: Double
    let distanceMeters: Double?
    let track: Track?
    
    enum CodingKeys: String, CodingKey {
        case totalTimeSeconds = "TotalTimeSeconds"
        case distanceMeters = "DistanceMeters"
        case track = "Track"
    }
}

struct Track: Codable {
    let trackpoint: [Trackpoint]
    
    enum CodingKeys: String, CodingKey {
        case trackpoint = "Trackpoint"
    }
}

struct Trackpoint: Codable {
    let time: Date?
    let position: Position?
    let altitudeMeters: Double?
    let heartRateBpm: HeartRateBpm?
    let cadence: Int?
    let extensions: Extensions?
    
    enum CodingKeys: String, CodingKey {
        case time = "Time"
        case position = "Position"
        case altitudeMeters = "AltitudeMeters"
        case heartRateBpm = "HeartRateBpm"
        case cadence = "Cadence"
        case extensions = "Extensions"
    }
}

struct Position: Codable {
    let latitudeDegrees: Double?
    let longitudeDegrees: Double?
    
    enum CodingKeys: String, CodingKey {
        case latitudeDegrees = "LatitudeDegrees"
        case longitudeDegrees = "LongitudeDegrees"
    }
}

struct HeartRateBpm: Codable {
    let value: Int?
    
    enum CodingKeys: String, CodingKey {
        case value = "Value"
    }
}

struct Extensions: Codable {
    let tpx: TPX?
    
    enum CodingKeys: String, CodingKey {
        case tpx = "TPX"
    }
}

struct TPX: Codable {
    let watts: Double?
    
    enum CodingKeys: String, CodingKey {
        case watts = "Watts"
    }
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
