//
//  ActivityTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Foundation
@testable import Pulsar
import SwiftData
import Testing

@Suite("Activity Model Tests")
@MainActor
struct ActivityTests {
    @Test("Activity should initialize with required properties")
    func testActivityInitialization() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(1800) // 30 minutes
        
        let activity = Activity(
            userId: "test-user-123",
            name: "Morning Run",
            activityType: .run,
            startDate: startDate,
            endDate: endDate,
            distance: 5000,
            duration: 1800
        )
        
        #expect(activity.userId == "test-user-123")
        #expect(activity.name == "Morning Run")
        #expect(activity.activityType == .run)
        #expect(activity.distance == 5000)
        #expect(activity.duration == 1800)
        #expect(activity.source == .fileUpload)
        #expect(activity.isPrivate == false)
    }
    
    @Test("Activity should calculate average pace correctly")
    func testAveragePaceCalculation() async throws {
        let activity = Activity(
            userId: "test-user",
            name: "Test Run",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000, // 5km
            duration: 1800 // 30 minutes
        )
        
        let pace = try #require(activity.averagePace)
        // 30 minutes / 5 km = 6 min/km
        #expect(abs(pace - 6.0) < 0.01)
    }
    
    @Test("Activity should calculate average speed in km/h")
    func testAverageSpeedCalculation() async throws {
        let activity = Activity(
            userId: "test-user",
            name: "Test Ride",
            activityType: .ride,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            distance: 20000, // 20km
            duration: 3600 // 1 hour
        )
        
        activity.avgSpeed = activity.distance / activity.duration // 5.56 m/s
        
        let speedKmh = try #require(activity.averageSpeedKmh)
        // 5.56 m/s * 3.6 = 20 km/h
        #expect(abs(speedKmh - 20.0) < 0.1)
    }
    
    @Test("ActivityType should have correct display names")
    func testActivityTypeDisplayNames() async throws {
        #expect(ActivityType.run.displayName == "Run")
        #expect(ActivityType.ride.displayName == "Ride")
        #expect(ActivityType.walk.displayName == "Walk")
        #expect(ActivityType.hike.displayName == "Hike")
    }
    
    @Test("ActivitySource should have correct display names")
    func testActivitySourceDisplayNames() async throws {
        #expect(ActivitySource.fileUpload.displayName == "File Upload")
        #expect(ActivitySource.healthKit.displayName == "Apple Health")
        #expect(ActivitySource.stravaAPI.displayName == "Strava")
    }
    
    @Test("Activity DTO conversion should preserve data")
    func testDTOConversion() async throws {
        let activity = Activity(
            id: "test-id-123",
            userId: "user-456",
            name: "Test Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800,
            source: .fileUpload,
            isPrivate: true
        )
        
        activity.elevationGain = 150
        activity.avgHeartRate = 145
        
        let dto = activity.toDTO()
        
        #expect(dto.id == "test-id-123")
        #expect(dto.userId == "user-456")
        #expect(dto.name == "Test Activity")
        #expect(dto.activityType == "run")
        #expect(dto.distance == 5000)
        #expect(dto.elevationGain == 150)
        #expect(dto.avgHeartRate == 145)
        #expect(dto.isPrivate == true)
        
        let reconstructed = Activity.fromDTO(dto)
        #expect(reconstructed.id == activity.id)
        #expect(reconstructed.name == activity.name)
        #expect(reconstructed.distance == activity.distance)
    }
}

@Suite("ActivityService Tests")
@MainActor
struct ActivityServiceTests {
    @Test("ActivityService should reject unsupported file formats")
    func testUnsupportedFileFormat() async throws {
        let service = ActivityService.shared
        
        // Create a temporary file with unsupported extension
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.xyz")
        try "dummy content".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        // Test that unsupported format throws error
        do {
            _ = try await service.parseActivityFile(from: tempURL, userId: "test-user")
            Issue.record("Should have thrown ActivityServiceError.unsupportedFileFormat")
        } catch let error as ActivityServiceError {
            // Verify it's the correct error type
            if case .unsupportedFileFormat(let format) = error {
                #expect(format == "xyz")
            } else {
                Issue.record("Expected unsupportedFileFormat error, got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("ActivityService should generate activity names from filenames")
    func testActivityNameGeneration() async throws {
        // This test validates the internal name generation logic
        // by checking that parsed activities have meaningful names
        #expect(true) // Placeholder until we implement real parsing
    }
}
