//
//  ActivityService.swift
//  Pulsar
//
//  Local activity import, persistence, and placeholder sync hooks.
//

import Foundation
import SwiftData

enum ActivityServiceError: LocalizedError {
    case invalidFileData
    case unsupportedFileFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFileData:
            return "Could not read the selected file."
        case .unsupportedFileFormat(let ext):
            return ".\(ext) import is not available yet. Try GPX."
        }
    }
}

@MainActor
final class ActivityService {
    static let shared = ActivityService()
    
    private init() {}
    
    func parseActivityFile(from url: URL, userId _: String) async throws -> Activity {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "gpx":
            let parser = GPXParser()
            let gpx = try await parser.parse(url: url)
            let name = gpx.name ?? url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
            let duration = max(gpx.durationSeconds, 1)
            let distance = max(gpx.distanceMeters, 0)
            let activity = Activity(
                name: name,
                activityType: .run,
                startDate: gpx.startTime ?? Date(),
                elapsedTimeSeconds: duration,
                distanceMeters: distance
            )
            activity.endDate = gpx.endTime
            if gpx.elevationGainMeters > 0 {
                activity.elevationGainMeters = gpx.elevationGainMeters
            }
            activity.sourceFile = url.lastPathComponent
            activity.setCoordinates(gpx.coordinates)
            if duration > 0, distance > 0 {
                activity.avgSpeedMps = distance / Double(duration)
            }
            return activity
        case "tcx", "fit":
            throw ActivityServiceError.unsupportedFileFormat(ext)
        default:
            throw ActivityServiceError.invalidFileData
        }
    }
    
    func saveActivity(_ activity: Activity, modelContext: ModelContext, appState: AppState) async throws {
        if let userId = appState.currentUserID {
            let descriptor = FetchDescriptor<Profile>(
                predicate: #Predicate { profile in
                    profile.userId == userId
                }
            )
            if let profile = try modelContext.fetch(descriptor).first {
                activity.profile = profile
            }
        }
        modelContext.insert(activity)
        try modelContext.save()
    }
    
    func syncActivitiesFromBackend(
        for userId: String,
        modelContext: ModelContext,
        appState: AppState
    ) async throws {
        // Remote activity sync is not wired yet.
    }
    
    func syncPendingActivities(
        for userId: String,
        modelContext: ModelContext,
        appState: AppState
    ) async {
        // Upload queue not implemented yet.
    }
    
    func deleteActivity(
        _ activity: Activity,
        modelContext: ModelContext,
        appState: AppState
    ) async throws {
        modelContext.delete(activity)
        try modelContext.save()
    }
    
    func needsRecalculation(_ activity: Activity) -> Bool {
        let coords = activity.coordinates
        guard coords.count >= 2 else { return false }
        return activity.distanceMeters <= 0 || activity.elapsedTimeSeconds <= 0
    }
    
    func recalculateMetrics(for activity: Activity, modelContext: ModelContext) async throws {
        let coords = activity.coordinates
        guard coords.count >= 2 else { return }
        let stats = Self.computeStats(from: coords)
        if stats.distance > 0 {
            activity.distanceMeters = stats.distance
        }
        if stats.duration > 0 {
            activity.elapsedTimeSeconds = stats.duration
        }
        if stats.elevationGain > 0 {
            activity.elevationGainMeters = stats.elevationGain
        }
        if activity.elapsedTimeSeconds > 0, activity.distanceMeters > 0 {
            activity.avgSpeedMps = activity.distanceMeters / Double(activity.elapsedTimeSeconds)
        }
        try modelContext.save()
    }
    
    private struct TrackCoordinateStats {
        let distance: Double
        let elevationGain: Double
        let duration: Int
    }
    
    private static func computeStats(from coordinates: [Coordinate]) -> TrackCoordinateStats {
        var totalDistance: Double = 0
        var totalElevationGain: Double = 0
        for index in 1..<coordinates.count {
            let previous = coordinates[index - 1]
            let current = coordinates[index]
            totalDistance += haversineMeters(
                lat1: previous.latitude, lon1: previous.longitude,
                lat2: current.latitude, lon2: current.longitude
            )
            if let prevEle = previous.elevation, let currEle = current.elevation {
                let diff = currEle - prevEle
                if diff > 0 { totalElevationGain += diff }
            }
        }
        var duration = 0
        if let start = coordinates.first?.time, let end = coordinates.last?.time {
            duration = max(Int(end.timeIntervalSince(start)), 0)
        }
        return TrackCoordinateStats(distance: totalDistance, elevationGain: totalElevationGain, duration: duration)
    }
    
    private static func haversineMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius: Double = 6_371_000
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let sinHalfChordSquared = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        let angularDistance = 2 * atan2(sqrt(sinHalfChordSquared), sqrt(1 - sinHalfChordSquared))
        return earthRadius * angularDistance
    }
}
