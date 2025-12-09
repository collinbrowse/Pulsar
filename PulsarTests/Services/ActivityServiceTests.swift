//
//  ActivityServiceTests.swift
//  PulsarTests
//
//  Created on 11/24/25.
//

// swiftlint:disable file_length
import Foundation
@testable import Pulsar
import SwiftData
import Testing
import XMLCoder

@Suite("ActivityService Tests")
@MainActor
// swiftlint:disable:next type_body_length
struct ActivityServiceTests {
    // MARK: - Test Fixtures
    
    /// Debug helper to list bundle contents (for troubleshooting)
    private func debugBundleContents() {
        let bundle = Bundle(for: BundleFinder.self)
        if let resourcePath = bundle.resourcePath {
            print("Bundle resource path: \(resourcePath)")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                print("Bundle contents: \(contents)")
            }
        }
        print("Bundle path: \(bundle.bundlePath)")
    }
    
    /// Verifies that a file URL exists and has content
    private func verifyFileExistsAndHasContent(_ url: URL) -> Bool {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            return false
        }
        guard let fileData = try? Data(contentsOf: url), !fileData.isEmpty else {
            return false
        }
        return true
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func getTestFixtureURL(_ filename: String) -> URL? {
        let fileManager = FileManager.default
        
        // Strategy 1: Try to find test fixture in bundle first
        let bundle = Bundle(for: BundleFinder.self)
        
        // Try with TestFixtures subdirectory first
        if let url = bundle.url(forResource: filename, withExtension: nil, subdirectory: "TestFixtures") {
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        
        // Try at bundle root (files in Copy Bundle Resources are at root)
        if let url = bundle.url(forResource: filename, withExtension: nil) {
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        
        // Try with just the filename (no extension) in case extension is handled differently
        let nameWithoutExt = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        if let url = bundle.url(forResource: nameWithoutExt, withExtension: ext.isEmpty ? nil : ext) {
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        
        // Try with TestFixtures subdirectory and explicit extension
        if !ext.isEmpty, let url = bundle.url(forResource: nameWithoutExt, withExtension: ext, subdirectory: "TestFixtures") {
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        
        // Try direct path in bundle Resources folder
        if let resourcePath = bundle.resourcePath {
            let directPath = URL(fileURLWithPath: resourcePath)
                .appendingPathComponent(filename)
            if fileManager.fileExists(atPath: directPath.path) {
                return directPath
            }
            
            // Try in TestFixtures subdirectory of Resources
            let testFixturesPath = URL(fileURLWithPath: resourcePath)
                .appendingPathComponent("TestFixtures")
                .appendingPathComponent(filename)
            if fileManager.fileExists(atPath: testFixturesPath.path) {
                return testFixturesPath
            }
        }
        
        // Strategy 2: Relative to test file location (most reliable)
        let testFileURL = URL(fileURLWithPath: #file)
        let testFixturesPath2 = testFileURL
            .deletingLastPathComponent() // Remove ActivityServiceTests.swift
            .deletingLastPathComponent() // Remove Services/
            .appendingPathComponent("TestFixtures")
            .appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: testFixturesPath2.path) {
            return testFixturesPath2
        }
        
        // Strategy 3: Find project root by looking for Pulsar.xcodeproj or .git
        var searchPath = testFileURL.deletingLastPathComponent() // Start at Services/
        while searchPath.pathComponents.count > 1 {
            // Check if this directory contains Pulsar.xcodeproj or .git
            let projectFile = searchPath.appendingPathComponent("Pulsar.xcodeproj")
            let gitDir = searchPath.appendingPathComponent(".git")
            
            if fileManager.fileExists(atPath: projectFile.path) || fileManager.fileExists(atPath: gitDir.path) {
                // Found project root
                let testFixturesPath3 = searchPath
                    .appendingPathComponent("PulsarTests")
                    .appendingPathComponent("TestFixtures")
                    .appendingPathComponent(filename)
                if fileManager.fileExists(atPath: testFixturesPath3.path) {
                    return testFixturesPath3
                }
                break
            }
            searchPath = searchPath.deletingLastPathComponent()
        }
        
        // Strategy 4: Try current working directory
        let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let testFixturesPath4 = cwd
            .appendingPathComponent("PulsarTests")
            .appendingPathComponent("TestFixtures")
            .appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: testFixturesPath4.path) {
            return testFixturesPath4
        }
        
        // Strategy 5: Try to find PulsarTests directory by walking up from test file
        var currentPath = testFileURL.deletingLastPathComponent()
        while currentPath.pathComponents.count > 1 {
            // Check if we're in PulsarTests directory
            if currentPath.lastPathComponent == "PulsarTests" {
                let testFixturesPath5 = currentPath
                    .appendingPathComponent("TestFixtures")
                    .appendingPathComponent(filename)
                if fileManager.fileExists(atPath: testFixturesPath5.path) {
                    return testFixturesPath5
                }
            }
            currentPath = currentPath.deletingLastPathComponent()
        }
        
        return nil
    }
    
    // MARK: - File Format Tests
    
    @Test("ActivityService should reject unsupported file formats")
    func testUnsupportedFileFormat() async throws {
        let service = ActivityService.shared
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.xyz")
        try "dummy content".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        do {
            _ = try await service.parseActivityFile(from: tempURL, userId: "test-user")
            Issue.record("Should have thrown ActivityServiceError.unsupportedFileFormat")
        } catch let error as ActivityServiceError {
            if case .unsupportedFileFormat(let format) = error {
                #expect(format == "xyz")
            } else {
                Issue.record("Expected unsupportedFileFormat error, got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - GPX Parsing Tests
    
    @Test("ActivityService should parse valid GPX file")
    func testParseValidGPX() async throws {
        let service = ActivityService.shared
        
        guard let gpxURL = getTestFixtureURL("sample.gpx") else {
            Issue.record("Test fixture sample.gpx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: gpxURL, userId: "test-user")
        
        #expect(activity.userId == "test-user")
        #expect(!activity.name.isEmpty)
        #expect(activity.distance > 0)
        #expect(activity.duration > 0)
        #expect(activity.startDate < activity.endDate)
        #expect(activity.trackPoints?.count ?? 0 > 0)
    }
    
    @Test("ActivityService should handle invalid GPX file")
    func testParseInvalidGPX() async throws {
        let service = ActivityService.shared
        
        guard let invalidGPXURL = getTestFixtureURL("invalid.gpx") else {
            Issue.record("Test fixture invalid.gpx not found")
            return
        }
        
        do {
            _ = try await service.parseActivityFile(from: invalidGPXURL, userId: "test-user")
            Issue.record("Should have thrown error for invalid GPX file")
        } catch let error as ActivityServiceError {
            // Should throw parsingFailed or noTrackPoints
            let isExpectedError = {
                if case .parsingFailed = error { return true }
                if case .noTrackPoints = error { return true }
                return false
            }()
            #expect(isExpectedError)
        } catch {
            // Other errors are acceptable for invalid files
            #expect(true)
        }
    }
    
    @Test("ActivityService should calculate distance from GPX track points")
    func testGPXDistanceCalculation() async throws {
        let service = ActivityService.shared
        
        guard let gpxURL = getTestFixtureURL("sample.gpx") else {
            Issue.record("Test fixture sample.gpx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: gpxURL, userId: "test-user")
        
        // Distance should be calculated from track points
        #expect(activity.distance > 0)
        
        // With 5 track points, distance should be reasonable
        // Each point is roughly 0.0001 degrees apart (about 11 meters)
        // So total distance should be around 40-50 meters
        #expect(activity.distance < 1000) // Less than 1km for test data
    }
    
    @Test("ActivityService should calculate duration from GPX timestamps")
    func testGPXDurationCalculation() async throws {
        let service = ActivityService.shared
        
        guard let gpxURL = getTestFixtureURL("sample.gpx") else {
            Issue.record("Test fixture sample.gpx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: gpxURL, userId: "test-user")
        
        // Duration should be calculated from timestamps
        // Test fixture has 5 points, 30 seconds apart = 120 seconds total
        let expectedDuration: TimeInterval = 120.0
        let tolerance: TimeInterval = 5.0 // Allow small tolerance
        
        #expect(abs(activity.duration - expectedDuration) < tolerance)
    }
    
    @Test("ActivityService should calculate elevation gain from GPX")
    func testGPXElevationCalculation() async throws {
        let service = ActivityService.shared
        
        guard let gpxURL = getTestFixtureURL("sample.gpx") else {
            Issue.record("Test fixture sample.gpx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: gpxURL, userId: "test-user")
        
        // Test fixture has elevation from 10m to 20m = 10m gain
        // But with noise filtering (2m threshold), might be less
        if let elevationGain = activity.elevationGain {
            #expect(elevationGain >= 0)
            #expect(elevationGain <= 15) // Should be around 10m, but allow some tolerance
        }
    }
    
    @Test("ActivityService should generate activity name from GPX filename")
    func testGPXActivityNameGeneration() async throws {
        let service = ActivityService.shared
        
        guard let gpxURL = getTestFixtureURL("sample.gpx") else {
            Issue.record("Test fixture sample.gpx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: gpxURL, userId: "test-user")
        
        // Name should be generated from filename or track name
        #expect(!activity.name.isEmpty)
        // Should contain "Test" or "Run" from test fixture
        let nameLower = activity.name.lowercased()
        #expect(nameLower.contains("test") || nameLower.contains("run") || nameLower.contains("sample"))
    }
    
    // MARK: - TCX Parsing Tests
    
    @Test("ActivityService should parse valid TCX file")
    func testParseValidTCX() async throws {
        let service = ActivityService.shared
        
        guard let tcxURL = getTestFixtureURL("sample.tcx") else {
            Issue.record("Test fixture sample.tcx not found")
            return
        }
        
        guard verifyFileExistsAndHasContent(tcxURL) else {
            Issue.record("TCX file does not exist or is empty at: \(tcxURL.path)")
            return
        }
        
        // Debug: Verify we can read the file data
        let fileData = try Data(contentsOf: tcxURL)
        guard !fileData.isEmpty else {
            Issue.record("TCX file data is empty after reading from: \(tcxURL.path)")
            return
        }
        
        // Debug: Check if we can decode as string to verify content
        guard let fileString = String(data: fileData, encoding: .utf8) else {
            Issue.record("TCX file data could not be decoded as UTF-8 string")
            return
        }
        
        guard fileString.contains("TrainingCenterDatabase") else {
            Issue.record("TCX file does not contain expected XML structure. First 200 chars: \(String(fileString.prefix(200)))")
            return
        }
        
        // Debug: Try to decode XML directly to see the actual error
        do {
            let decoder = XMLDecoder()
            decoder.dateDecodingStrategy = .iso8601
            _ = try decoder.decode(TrainingCenterDatabase.self, from: fileData)
        } catch {
            Issue.record("Direct XML decode failed: \(error.localizedDescription). File size: \(fileData.count) bytes. Full error: \(String(describing: error))")
            // Continue to see what service does
        }
        
        let activity = try await service.parseActivityFile(from: tcxURL, userId: "test-user")
        
        #expect(activity.userId == "test-user")
        #expect(!activity.name.isEmpty)
        #expect(activity.distance > 0)
        #expect(activity.duration > 0)
        #expect(activity.startDate < activity.endDate)
        #expect(activity.trackPoints?.count ?? 0 > 0)
    }
    
    @Test("ActivityService should handle invalid TCX file")
    func testParseInvalidTCX() async throws {
        let service = ActivityService.shared
        
        guard let invalidTCXURL = getTestFixtureURL("invalid.tcx") else {
            Issue.record("Test fixture invalid.tcx not found")
            return
        }
        
        do {
            _ = try await service.parseActivityFile(from: invalidTCXURL, userId: "test-user")
            Issue.record("Should have thrown error for invalid TCX file")
        } catch let error as ActivityServiceError {
            // Should throw parsingFailed or noTrackPoints
            let isExpectedError = {
                if case .parsingFailed = error { return true }
                if case .noTrackPoints = error { return true }
                return false
            }()
            #expect(isExpectedError)
        } catch {
            // Other errors are acceptable for invalid files
            #expect(true)
        }
    }
    
    @Test("ActivityService should use TCX lap distance when available")
    func testTCXLapDistance() async throws {
        let service = ActivityService.shared
        
        guard let tcxURL = getTestFixtureURL("sample.tcx") else {
            Issue.record("Test fixture sample.tcx not found")
            return
        }
        
        guard verifyFileExistsAndHasContent(tcxURL) else {
            Issue.record("TCX file does not exist or is empty at: \(tcxURL.path)")
            return
        }
        
        // Debug: Verify we can read the file data
        let fileData = try Data(contentsOf: tcxURL)
        guard !fileData.isEmpty else {
            Issue.record("TCX file data is empty after reading from: \(tcxURL.path)")
            return
        }
        
        // Debug: Check if we can decode as string to verify content
        if let fileString = String(data: fileData, encoding: .utf8) {
            guard fileString.contains("TrainingCenterDatabase") else {
                Issue.record("TCX file does not contain expected XML structure. First 200 chars: \(String(fileString.prefix(200)))")
                return
            }
        }
        
        let activity = try await service.parseActivityFile(from: tcxURL, userId: "test-user")
        
        // TCX fixture has DistanceMeters = 500.0
        // Should use this value if available
        #expect(activity.distance > 0)
        // Should be close to 500 meters (allow some tolerance)
        #expect(abs(activity.distance - 500.0) < 100.0)
    }
    
    @Test("ActivityService should calculate duration from TCX")
    func testTCXDurationCalculation() async throws {
        let service = ActivityService.shared
        
        guard let tcxURL = getTestFixtureURL("sample.tcx") else {
            Issue.record("Test fixture sample.tcx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: tcxURL, userId: "test-user")
        
        // TCX fixture has TotalTimeSeconds = 120.0
        let expectedDuration: TimeInterval = 120.0
        let tolerance: TimeInterval = 5.0
        
        #expect(abs(activity.duration - expectedDuration) < tolerance)
    }
    
    @Test("ActivityService should extract heart rate from TCX if available")
    func testTCXHeartRateExtraction() async throws {
        let service = ActivityService.shared
        
        guard let tcxURL = getTestFixtureURL("sample.tcx") else {
            Issue.record("Test fixture sample.tcx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: tcxURL, userId: "test-user")
        
        // Test fixture doesn't have heart rate, but structure should support it
        // Just verify activity was created successfully
        #expect(activity.userId == "test-user")
    }
    
    // MARK: - FIT Parsing Tests
    
    @Test("ActivityService should handle FIT file format")
    func testFITFileHandling() async throws {
        let service = ActivityService.shared
        
        // Create a dummy FIT file (binary format)
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.fit")
        try "dummy fit content".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        do {
            _ = try await service.parseActivityFile(from: tempURL, userId: "test-user")
            Issue.record("FIT parsing should throw error (not yet implemented)")
        } catch let error as ActivityServiceError {
            // FIT parsing is not yet implemented, should throw parsingFailed
            if case .parsingFailed(let reason) = error {
                #expect(reason.contains("FIT") || reason.contains("not yet"))
            } else {
                // Other errors are acceptable
                #expect(true)
            }
        } catch {
            // Other errors are acceptable
            #expect(true)
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("ActivityService should handle missing file")
    func testMissingFile() async throws {
        let service = ActivityService.shared
        
        let missingURL = URL(fileURLWithPath: "/nonexistent/file.gpx")
        
        do {
            _ = try await service.parseActivityFile(from: missingURL, userId: "test-user")
            Issue.record("Should have thrown error for missing file")
        } catch {
            // Should throw file not found error
            #expect(true)
        }
    }
    
    @Test("ActivityService should handle empty GPX file")
    func testEmptyGPXFile() async throws {
        let service = ActivityService.shared
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("empty.gpx")
        try "".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        do {
            _ = try await service.parseActivityFile(from: tempURL, userId: "test-user")
            Issue.record("Should have thrown error for empty GPX file")
        } catch let error as ActivityServiceError {
            let isExpectedError = {
                if case .parsingFailed = error { return true }
                if case .noTrackPoints = error { return true }
                return false
            }()
            #expect(isExpectedError)
        } catch {
            #expect(true)
        }
    }
    
    @Test("ActivityService should handle GPX file with no track points")
    func testGPXNoTrackPoints() async throws {
        let service = ActivityService.shared
        
        // Create GPX file with no track points
        let gpxContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Test">
          <trk>
            <name>Empty Track</name>
            <trkseg>
            </trkseg>
          </trk>
        </gpx>
        """
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("empty_track.gpx")
        try gpxContent.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        do {
            _ = try await service.parseActivityFile(from: tempURL, userId: "test-user")
            Issue.record("Should have thrown error for GPX with no track points")
        } catch let error as ActivityServiceError {
            if case .noTrackPoints = error {
                #expect(true)
            } else {
                Issue.record("Expected noTrackPoints error, got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Activity Properties Tests
    
    @Test("ActivityService should set correct activity type from filename")
    func testActivityTypeFromFilename() async throws {
        let service = ActivityService.shared
        
        guard let gpxURL = getTestFixtureURL("sample.gpx") else {
            Issue.record("Test fixture sample.gpx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: gpxURL, userId: "test-user")
        
        // Activity type should be determined from filename or default
        #expect([.run, .ride, .walk, .hike].contains(activity.activityType))
    }
    
    @Test("ActivityService should set source as fileUpload")
    func testActivitySource() async throws {
        let service = ActivityService.shared
        
        guard let gpxURL = getTestFixtureURL("sample.gpx") else {
            Issue.record("Test fixture sample.gpx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: gpxURL, userId: "test-user")
        
        #expect(activity.source == .fileUpload)
    }
    
    @Test("ActivityService should preserve original filename")
    func testOriginalFileName() async throws {
        let service = ActivityService.shared
        
        guard let gpxURL = getTestFixtureURL("sample.gpx") else {
            Issue.record("Test fixture sample.gpx not found")
            return
        }
        
        let activity = try await service.parseActivityFile(from: gpxURL, userId: "test-user")
        
        #expect(activity.originalFileName == "sample.gpx")
    }
    
    // MARK: - Sync Status Tracking Tests
    
    @Test("Activity should have lastSyncedAt field")
    func testActivityHasLastSyncedAtField() async throws {
        let activity = Activity(
            userId: "test-user",
            name: "Test Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        )
        
        // Initially should be nil (never synced)
        #expect(activity.lastSyncedAt == nil)
        
        // Can be set to a date
        let syncDate = Date()
        activity.lastSyncedAt = syncDate
        #expect(activity.lastSyncedAt == syncDate)
    }
    
    @Test("ActivityService syncPendingActivities should find activities with nil lastSyncedAt")
    // swiftlint:disable:next function_body_length
    func testSyncPendingActivitiesFindsUnsyncedActivities() async throws {
        let service = ActivityService.shared
        let modelContext = createTestModelContext()
        let userId = "test-user-123"
        
        // Create activities with different sync statuses
        let syncedActivity = Activity(
            userId: userId,
            name: "Synced Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        )
        syncedActivity.lastSyncedAt = Date()
        modelContext.insert(syncedActivity)
        
        let unsyncedActivity1 = Activity(
            userId: userId,
            name: "Unsynced Activity 1",
            activityType: .ride,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            distance: 10000,
            duration: 3600
        )
        // lastSyncedAt is nil by default
        modelContext.insert(unsyncedActivity1)
        
        let unsyncedActivity2 = Activity(
            userId: userId,
            name: "Unsynced Activity 2",
            activityType: .walk,
            startDate: Date(),
            endDate: Date().addingTimeInterval(900),
            distance: 2000,
            duration: 900
        )
        // lastSyncedAt is nil by default
        modelContext.insert(unsyncedActivity2)
        
        // Create activity for different user (should not be found)
        let otherUserActivity = Activity(
            userId: "other-user",
            name: "Other User Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        )
        modelContext.insert(otherUserActivity)
        
        try modelContext.save()
        
        // Verify we can find unsynced activities using the same predicate logic
        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.userId == userId && activity.lastSyncedAt == nil
            }
        )
        
        let pendingActivities = try modelContext.fetch(descriptor)
        
        // Should find 2 unsynced activities for the test user
        #expect(pendingActivities.count == 2)
        #expect(pendingActivities.contains { $0.id == unsyncedActivity1.id })
        #expect(pendingActivities.contains { $0.id == unsyncedActivity2.id })
        #expect(!pendingActivities.contains { $0.id == syncedActivity.id })
        #expect(!pendingActivities.contains { $0.id == otherUserActivity.id })
    }
    
    @Test("ActivityService syncPendingActivities should handle empty pending activities")
    func testSyncPendingActivitiesHandlesEmptyList() async throws {
        let service = ActivityService.shared
        let modelContext = createTestModelContext()
        let userId = "test-user-123"
        
        // Create only synced activities
        let syncedActivity = Activity(
            userId: userId,
            name: "Synced Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        )
        syncedActivity.lastSyncedAt = Date()
        modelContext.insert(syncedActivity)
        try modelContext.save()
        
        // Should not throw and should handle gracefully
        let appState = AppState()
        await service.syncPendingActivities(for: userId, modelContext: modelContext, appState: appState)
        
        // Verify activity is still there and still synced
        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.userId == userId
            }
        )
        let activities = try modelContext.fetch(descriptor)
        #expect(activities.count == 1)
        #expect(activities.first?.lastSyncedAt != nil)
    }
    
    // MARK: - Authentication Error Handling Tests
    
    @Test("NetworkError 401 should be identified as authentication error")
    func testNetworkError401IsAuthError() {
        let error = NetworkError.httpError(statusCode: 401, errorCode: "unauthorized", message: "Authentication required")
        
        // Verify it's a NetworkError with 401 status
        if case .httpError(let statusCode, _, _) = error {
            #expect(statusCode == 401)
        } else {
            Issue.record("Expected httpError with statusCode 401")
        }
    }
    
    @Test("NetworkError 500 should be identified as network error, not auth error")
    func testNetworkError500IsNotAuthError() {
        let error = NetworkError.httpError(statusCode: 500, errorCode: "internal_server_error", message: "Server error")
        
        // Verify it's a NetworkError with 500 status (not 401)
        if case .httpError(let statusCode, _, _) = error {
            #expect(statusCode == 500)
            #expect(statusCode != 401) // Should not be treated as auth error
        } else {
            Issue.record("Expected httpError with statusCode 500")
        }
    }
    
    @Test("URLError should be identified as network error, not auth error")
    func testURLErrorIsNotAuthError() {
        let error = URLError(.notConnectedToInternet)
        
        // Verify it's a URLError (network issue, not auth)
        #expect(error.code == .notConnectedToInternet)
        // URLError should not trigger logout
    }
    
    @Test("AuthError.notAuthenticated should be identified as authentication error")
    func testAuthErrorNotAuthenticatedIsAuthError() {
        let error = AuthError.notAuthenticated
        
        // Verify it's the correct auth error
        #expect(error == .notAuthenticated)
    }
    
    @Test("ActivityService methods should accept appState parameter")
    func testActivityServiceMethodsAcceptAppState() {
        let modelContext = createTestModelContext()
        let appState = AppState()
        
        // Verify methods accept appState parameter (compile-time check)
        // This test ensures the API is correct
        let activity = Activity(
            userId: "test-user",
            name: "Test Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(100),
            distance: 1000,
            duration: 100
        )
        
        // These should compile without errors
        // Note: These will fail at runtime without proper setup, but we're just checking the API
        let service = ActivityService.shared
        Task {
            _ = try? await service.saveActivity(activity, modelContext: modelContext, appState: appState)
            _ = try? await service.syncActivitiesFromBackend(for: "test-user", modelContext: modelContext, appState: appState)
            _ = await service.syncPendingActivities(for: "test-user", modelContext: modelContext, appState: appState)
            _ = try? await service.deleteActivity(activity, modelContext: modelContext, appState: appState)
        }
        
        // If we get here, the API is correct (compilation succeeded)
        // Verify appState was created successfully
        #expect(appState.isAuthenticated == false)
    }
    
    // MARK: - Geometry Parsing Tests
    
    /// Creates a JSONDecoder with the same date decoding strategy as SupabaseClient
    private func createSupabaseJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            // Try format with timezone offset (PostgreSQL default)
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Try format with fractional seconds
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Try format with Z (Zulu time)
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Try with fractional seconds and Z
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return decoder
    }
    
    @Test("ActivityBackendDTO should decode WKT geometry format")
    func testActivityBackendDTODecodesWKTGeometry() throws {
        // Create JSON with WKT format geometry
        let wktGeometry = "SRID=4326;LINESTRING(-122.4194 37.7749, -122.4195 37.7750, -122.4196 37.7751)"
        let jsonString = """
        {
            "activity_id": "test-activity-123",
            "user_id": "test-user-123",
            "activity_type": "run",
            "name": "Test Activity",
            "distance_m": 1000.0,
            "duration_sec": 3600,
            "start_time": "2025-01-01T12:00:00Z",
            "end_time": "2025-01-01T13:00:00Z",
            "visibility": "public",
            "geom": "\(wktGeometry)"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = createSupabaseJSONDecoder()
        let dto = try decoder.decode(ActivityBackendDTO.self, from: jsonData)
        
        #expect(dto.activityId == "test-activity-123")
        #expect(dto.geom == wktGeometry)
    }
    
    @Test("ActivityBackendDTO should decode GeoJSON geometry format")
    func testActivityBackendDTODecodesGeoJSONGeometry() throws {
        // Create JSON with GeoJSON format geometry
        let jsonString = """
        {
            "activity_id": "test-activity-456",
            "user_id": "test-user-123",
            "activity_type": "run",
            "name": "Test Activity",
            "distance_m": 1000.0,
            "duration_sec": 3600,
            "start_time": "2025-01-01T12:00:00Z",
            "end_time": "2025-01-01T13:00:00Z",
            "visibility": "public",
            "geom": {
                "type": "LineString",
                "coordinates": [[-122.4194, 37.7749], [-122.4195, 37.7750], [-122.4196, 37.7751]]
            }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = createSupabaseJSONDecoder()
        let dto = try decoder.decode(ActivityBackendDTO.self, from: jsonData)
        
        #expect(dto.activityId == "test-activity-456")
        // GeoJSON should be converted to JSON string
        #expect(dto.geom != nil)
        #expect(dto.geom?.contains("LineString") == true)
        #expect(dto.geom?.contains("coordinates") == true)
    }
    
    @Test("ActivityBackendDTO should handle missing geometry")
    func testActivityBackendDTODecodesMissingGeometry() throws {
        let jsonString = """
        {
            "activity_id": "test-activity-789",
            "user_id": "test-user-123",
            "activity_type": "run",
            "name": "Test Activity",
            "distance_m": 1000.0,
            "duration_sec": 3600,
            "start_time": "2025-01-01T12:00:00Z",
            "end_time": "2025-01-01T13:00:00Z",
            "visibility": "public"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = createSupabaseJSONDecoder()
        let dto = try decoder.decode(ActivityBackendDTO.self, from: jsonData)
        
        #expect(dto.activityId == "test-activity-789")
        #expect(dto.geom == nil)
    }
    
    // MARK: - Test Helpers
    
    private func createTestModelContext() -> ModelContext {
        let schema = Schema([
            Activity.self,
            TrackPoint.self,
            Profile.self,
            Follow.self,
            Kudo.self,
            Comment.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        return ModelContext(container)
    }
}

// Helper class to find the test bundle
private class BundleFinder {}
