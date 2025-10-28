//
//  ActivityService.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import SwiftData
import OSLog
import MapKit

private let logger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "ActivityService")

/// Service for parsing, storing, and managing activities
@MainActor
final class ActivityService: Sendable {
    static let shared = ActivityService()
    
    private init() {}
    
    // MARK: - File Parsing
    
    /// Parse an activity file (GPX, TCX, or FIT) and create an Activity model
    func parseActivityFile(
        from url: URL,
        userID: String
    ) async throws -> Activity {
        logger.info("📄 Parsing activity file: \(url.lastPathComponent)")
        
        let fileExtension = url.pathExtension.lowercased()
        let data = try Data(contentsOf: url)
        
        switch fileExtension {
        case "gpx":
            return try await parseGPX(data: data, fileName: url.lastPathComponent, userID: userID)
        case "tcx":
            return try await parseTCX(data: data, fileName: url.lastPathComponent, userID: userID)
        case "fit":
            return try await parseFIT(data: data, fileName: url.lastPathComponent, userID: userID)
        default:
            throw ActivityServiceError.unsupportedFileFormat(fileExtension)
        }
    }
    
    // MARK: - GPX Parsing
    
    private func parseGPX(data: Data, fileName: String, userID: String) async throws -> Activity {
        logger.info("📍 Parsing GPX file")
        
        // TODO: Use CoreGPX to parse (requires SPM package)
        // For now, create a stub activity
        let activity = Activity(
            userID: userID,
            name: generateActivityName(from: fileName),
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800), // 30 minutes
            distance: 5000, // 5km
            duration: 1800, // 30 minutes
            source: .fileUpload
        )
        
        activity.originalFileName = fileName
        activity.avgSpeed = activity.distance / activity.duration
        
        logger.info("✅ GPX parsed: \(activity.name)")
        return activity
    }
    
    // MARK: - TCX Parsing
    
    private func parseTCX(data: Data, fileName: String, userID: String) async throws -> Activity {
        logger.info("📍 Parsing TCX file")
        
        // TODO: Use XMLCoder to parse (requires SPM package)
        // For now, create a stub activity
        let activity = Activity(
            userID: userID,
            name: generateActivityName(from: fileName),
            activityType: .ride,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600), // 1 hour
            distance: 20000, // 20km
            duration: 3600, // 1 hour
            source: .fileUpload
        )
        
        activity.originalFileName = fileName
        activity.avgSpeed = activity.distance / activity.duration
        activity.avgHeartRate = 145
        activity.maxHeartRate = 175
        
        logger.info("✅ TCX parsed: \(activity.name)")
        return activity
    }
    
    // MARK: - FIT Parsing
    
    private func parseFIT(data: Data, fileName: String, userID: String) async throws -> Activity {
        logger.info("📍 Parsing FIT file")
        
        // TODO: Use FitDataProtocol to parse (requires SPM package)
        // For now, create a stub activity
        let activity = Activity(
            userID: userID,
            name: generateActivityName(from: fileName),
            activityType: .ride,
            startDate: Date(),
            endDate: Date().addingTimeInterval(5400), // 1.5 hours
            distance: 40000, // 40km
            duration: 5400, // 1.5 hours
            source: .fileUpload
        )
        
        activity.originalFileName = fileName
        activity.avgSpeed = activity.distance / activity.duration
        activity.avgHeartRate = 155
        activity.maxHeartRate = 185
        activity.avgPower = 220
        activity.maxPower = 450
        activity.avgCadence = 85
        activity.elevationGain = 450
        
        logger.info("✅ FIT parsed: \(activity.name)")
        return activity
    }
    
    // MARK: - Helpers
    
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
        
        // TODO: Sync to Supabase backend
        // let dto = activity.toDTO()
        // try await supabaseClient.insert("activities", data: dto)
        
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
    
    /// Fetch all activities for a user
    func fetchActivities(
        for userID: String,
        modelContext: ModelContext
    ) throws -> [Activity] {
        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.userID == userID
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// Delete an activity
    func deleteActivity(
        _ activity: Activity,
        modelContext: ModelContext
    ) async throws {
        logger.info("🗑️ Deleting activity: \(activity.name)")
        
        // TODO: Delete from backend
        // try await supabaseClient.delete("activities", id: activity.id)
        
        // Delete from local storage
        modelContext.delete(activity)
        try modelContext.save()
        
        ObservabilityManager.shared.track(event: "activity_deleted", properties: [
            "activity_id": activity.id
        ])
        
        logger.info("✅ Activity deleted successfully")
    }
}

// MARK: - Errors

enum ActivityServiceError: Error, LocalizedError {
    case unsupportedFileFormat(String)
    case invalidFileData
    case parsingFailed(String)
    case noTrackPoints
    case invalidCoordinates
    
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
        }
    }
}

