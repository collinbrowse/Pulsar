//
//  GPXParserTests.swift
//  PulsarTests
//
//  Tests for GPX file parsing
//

import Testing
import Foundation
@testable import Pulsar

@Suite("GPX Parser Tests")
@MainActor
struct GPXParserTests {
    
    // MARK: - Test Data Helpers
    
    /// Creates a minimal valid GPX string with the given track points
    private func makeGPX(
        name: String? = nil,
        trackPoints: [(lat: Double, lon: Double, ele: Double?, time: String?)]
    ) -> Data {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="PulsarTests">
        <trk>
        """
        
        if let name = name {
            xml += "<name>\(name)</name>"
        }
        
        xml += "<trkseg>"
        
        for point in trackPoints {
            xml += "<trkpt lat=\"\(point.lat)\" lon=\"\(point.lon)\">"
            if let ele = point.ele {
                xml += "<ele>\(ele)</ele>"
            }
            if let time = point.time {
                xml += "<time>\(time)</time>"
            }
            xml += "</trkpt>"
        }
        
        xml += """
        </trkseg>
        </trk>
        </gpx>
        """
        
        return xml.data(using: .utf8)!
    }
    
    /// Creates GPX with route points instead of track points
    private func makeRouteGPX(
        routePoints: [(lat: Double, lon: Double)]
    ) -> Data {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="PulsarTests">
        <rte>
        <name>Test Route</name>
        """
        
        for point in routePoints {
            xml += "<rtept lat=\"\(point.lat)\" lon=\"\(point.lon)\"></rtept>"
        }
        
        xml += """
        </rte>
        </gpx>
        """
        
        return xml.data(using: .utf8)!
    }
    
    // MARK: - Basic Parsing Tests
    
    @Suite("Basic Parsing")
    @MainActor
    struct BasicParsingTests {
        
        @Test("Parse GPX with track points extracts coordinates")
        func testParseTrackPoints() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: nil, time: nil),
                (lat: 37.7750, lon: -122.4195, ele: nil, time: nil),
                (lat: 37.7751, lon: -122.4196, ele: nil, time: nil)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates.count == 3)
            #expect(result.coordinates[0].latitude == 37.7749)
            #expect(result.coordinates[0].longitude == -122.4194)
            #expect(result.coordinates[2].latitude == 37.7751)
        }
        
        @Test("Parse GPX extracts track name")
        func testParseTrackName() async throws {
            let gpxData = GPXParserTests().makeGPX(
                name: "Morning Run in Golden Gate Park",
                trackPoints: [
                    (lat: 37.7749, lon: -122.4194, ele: nil, time: nil)
                ]
            )
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.name == "Morning Run in Golden Gate Park")
        }
        
        @Test("Parse GPX with elevation data")
        func testParseElevation() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: 10.5, time: nil),
                (lat: 37.7750, lon: -122.4195, ele: 15.2, time: nil),
                (lat: 37.7751, lon: -122.4196, ele: 12.8, time: nil)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates[0].elevation == 10.5)
            #expect(result.coordinates[1].elevation == 15.2)
            #expect(result.coordinates[2].elevation == 12.8)
        }
        
        @Test("Parse GPX with timestamps")
        func testParseTimestamps() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: nil, time: "2024-01-15T08:00:00Z"),
                (lat: 37.7750, lon: -122.4195, ele: nil, time: "2024-01-15T08:05:00Z"),
                (lat: 37.7751, lon: -122.4196, ele: nil, time: "2024-01-15T08:10:00Z")
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates[0].time != nil)
            #expect(result.coordinates[2].time != nil)
            #expect(result.startTime != nil)
            #expect(result.endTime != nil)
        }
        
        @Test("Parse GPX with route points")
        func testParseRoutePoints() async throws {
            let gpxData = GPXParserTests().makeRouteGPX(routePoints: [
                (lat: 37.7749, lon: -122.4194),
                (lat: 37.7750, lon: -122.4195)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates.count == 2)
            #expect(result.name == "Test Route")
        }
        
        @Test("Parse GPX without elevation still works")
        func testParseWithoutElevation() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: nil, time: nil),
                (lat: 37.7750, lon: -122.4195, ele: nil, time: nil)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates.count == 2)
            #expect(result.coordinates[0].elevation == nil)
            #expect(result.elevationGainMeters == 0)
        }
        
        @Test("Parse GPX without timestamps still works")
        func testParseWithoutTimestamps() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: nil, time: nil),
                (lat: 37.7750, lon: -122.4195, ele: nil, time: nil)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates.count == 2)
            #expect(result.durationSeconds == 0)
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Suite("Error Handling")
    @MainActor
    struct ErrorHandlingTests {
        
        @Test("Empty GPX throws noTrackPoints error")
        func testEmptyGPXThrows() async throws {
            let emptyGPX = """
            <?xml version="1.0" encoding="UTF-8"?>
            <gpx version="1.1" creator="Test">
            <trk><trkseg></trkseg></trk>
            </gpx>
            """.data(using: .utf8)!
            
            let parser = GPXParser()
            
            await #expect(throws: GPXParser.ParseError.self) {
                try await parser.parse(data: emptyGPX)
            }
        }
        
        @Test("Malformed XML throws parsing error")
        func testMalformedXMLThrows() async throws {
            let malformedXML = """
            <?xml version="1.0" encoding="UTF-8"?>
            <gpx version="1.1">
            <trk><trkseg>
            <trkpt lat="37.7749" lon="-122.4194">
            <!-- missing closing tags -->
            """.data(using: .utf8)!
            
            let parser = GPXParser()
            
            await #expect(throws: GPXParser.ParseError.self) {
                try await parser.parse(data: malformedXML)
            }
        }
        
        @Test("Invalid data throws error")
        func testInvalidDataThrows() async throws {
            let notXML = "This is not XML data at all".data(using: .utf8)!
            
            let parser = GPXParser()
            
            await #expect(throws: GPXParser.ParseError.self) {
                try await parser.parse(data: notXML)
            }
        }
    }
    
    // MARK: - Stats Calculation Tests
    
    @Suite("Stats Calculation")
    @MainActor
    struct StatsCalculationTests {
        
        @Test("Calculate distance using Haversine formula")
        func testDistanceCalculation() async throws {
            // Two points approximately 111 meters apart (0.001 degree at equator)
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 0.0, lon: 0.0, ele: nil, time: nil),
                (lat: 0.001, lon: 0.0, ele: nil, time: nil)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            // At equator, 0.001 degree latitude ≈ 111 meters
            #expect(result.distanceMeters > 100)
            #expect(result.distanceMeters < 120)
        }
        
        @Test("Calculate distance for known route")
        func testKnownDistanceCalculation() async throws {
            // San Francisco to Oakland (approx 13km straight line)
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: nil, time: nil),  // SF
                (lat: 37.8044, lon: -122.2712, ele: nil, time: nil)   // Oakland
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            // Should be approximately 13km
            let distanceKm = result.distanceMeters / 1000
            #expect(distanceKm > 12)
            #expect(distanceKm < 15)
        }
        
        @Test("Calculate elevation gain - only positive changes")
        func testElevationGainCalculation() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: 10.0, time: nil),
                (lat: 37.7750, lon: -122.4195, ele: 25.0, time: nil),  // +15m gain
                (lat: 37.7751, lon: -122.4196, ele: 20.0, time: nil),  // -5m loss (not counted)
                (lat: 37.7752, lon: -122.4197, ele: 35.0, time: nil),  // +15m gain
                (lat: 37.7753, lon: -122.4198, ele: 30.0, time: nil)   // -5m loss (not counted)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            // Total gain should be 15 + 15 = 30m
            #expect(result.elevationGainMeters == 30.0)
        }
        
        @Test("Calculate elevation gain - flat route")
        func testElevationGainFlat() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: 10.0, time: nil),
                (lat: 37.7750, lon: -122.4195, ele: 10.0, time: nil),
                (lat: 37.7751, lon: -122.4196, ele: 10.0, time: nil)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.elevationGainMeters == 0)
        }
        
        @Test("Calculate elevation gain - only downhill")
        func testElevationGainDownhill() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: 100.0, time: nil),
                (lat: 37.7750, lon: -122.4195, ele: 80.0, time: nil),
                (lat: 37.7751, lon: -122.4196, ele: 60.0, time: nil)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.elevationGainMeters == 0)
        }
        
        @Test("Calculate duration from timestamps")
        func testDurationCalculation() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: nil, time: "2024-01-15T08:00:00Z"),
                (lat: 37.7750, lon: -122.4195, ele: nil, time: "2024-01-15T08:15:00Z"),
                (lat: 37.7751, lon: -122.4196, ele: nil, time: "2024-01-15T08:30:00Z")
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            // 30 minutes = 1800 seconds
            #expect(result.durationSeconds == 1800)
        }
        
        @Test("Duration is zero without timestamps")
        func testDurationWithoutTimestamps() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: nil, time: nil),
                (lat: 37.7750, lon: -122.4195, ele: nil, time: nil)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.durationSeconds == 0)
        }
    }
    
    // MARK: - Edge Cases
    
    @Suite("Edge Cases")
    @MainActor
    struct EdgeCaseTests {
        
        @Test("Single track point is valid")
        func testSingleTrackPoint() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: 50.0, time: "2024-01-15T08:00:00Z")
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates.count == 1)
            #expect(result.distanceMeters == 0)
            #expect(result.elevationGainMeters == 0)
        }
        
        @Test("Handles ISO8601 timestamps with fractional seconds")
        func testFractionalSecondsTimestamp() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.7749, lon: -122.4194, ele: nil, time: "2024-01-15T08:00:00.123Z"),
                (lat: 37.7750, lon: -122.4195, ele: nil, time: "2024-01-15T08:00:30.456Z")
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates[0].time != nil)
            #expect(result.durationSeconds == 30)
        }
        
        @Test("Handles negative coordinates")
        func testNegativeCoordinates() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: -33.8688, lon: 151.2093, ele: nil, time: nil),  // Sydney
                (lat: -37.8136, lon: 144.9631, ele: nil, time: nil)   // Melbourne
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates[0].latitude == -33.8688)
            #expect(result.coordinates[0].longitude == 151.2093)
        }
        
        @Test("Handles high precision coordinates")
        func testHighPrecisionCoordinates() async throws {
            let gpxData = GPXParserTests().makeGPX(trackPoints: [
                (lat: 37.77492839, lon: -122.41941628, ele: nil, time: nil),
                (lat: 37.77493012, lon: -122.41941893, ele: nil, time: nil)
            ])
            
            let parser = GPXParser()
            let result = try await parser.parse(data: gpxData)
            
            #expect(result.coordinates[0].latitude == 37.77492839)
            #expect(result.coordinates[0].longitude == -122.41941628)
        }
        
        @Test("Parser can be reused for multiple files")
        func testParserReuse() async throws {
            let parser = GPXParser()
            
            let gpx1 = GPXParserTests().makeGPX(
                name: "First Run",
                trackPoints: [(lat: 37.7749, lon: -122.4194, ele: nil, time: nil)]
            )
            
            let gpx2 = GPXParserTests().makeGPX(
                name: "Second Run",
                trackPoints: [
                    (lat: 40.7128, lon: -74.0060, ele: nil, time: nil),
                    (lat: 40.7129, lon: -74.0061, ele: nil, time: nil)
                ]
            )
            
            let result1 = try await parser.parse(data: gpx1)
            let result2 = try await parser.parse(data: gpx2)
            
            #expect(result1.name == "First Run")
            #expect(result1.coordinates.count == 1)
            
            #expect(result2.name == "Second Run")
            #expect(result2.coordinates.count == 2)
        }
    }
    
    // MARK: - Integration Test with Real GPX Structure
    
    @Suite("Integration Tests")
    @MainActor
    struct IntegrationTests {
        
        @Test("Parse realistic GPX file structure")
        func testRealisticGPX() async throws {
            // A more realistic GPX structure with metadata
            let realisticGPX = """
            <?xml version="1.0" encoding="UTF-8"?>
            <gpx version="1.1" creator="Garmin Connect"
                 xmlns="http://www.topografix.com/GPX/1/1"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <metadata>
                <time>2024-01-15T08:00:00Z</time>
              </metadata>
              <trk>
                <name>Morning 5K Run</name>
                <type>running</type>
                <trkseg>
                  <trkpt lat="37.7749" lon="-122.4194">
                    <ele>10.0</ele>
                    <time>2024-01-15T08:00:00Z</time>
                  </trkpt>
                  <trkpt lat="37.7760" lon="-122.4180">
                    <ele>15.0</ele>
                    <time>2024-01-15T08:05:00Z</time>
                  </trkpt>
                  <trkpt lat="37.7780" lon="-122.4160">
                    <ele>20.0</ele>
                    <time>2024-01-15T08:10:00Z</time>
                  </trkpt>
                  <trkpt lat="37.7800" lon="-122.4140">
                    <ele>18.0</ele>
                    <time>2024-01-15T08:15:00Z</time>
                  </trkpt>
                  <trkpt lat="37.7820" lon="-122.4120">
                    <ele>25.0</ele>
                    <time>2024-01-15T08:20:00Z</time>
                  </trkpt>
                </trkseg>
              </trk>
            </gpx>
            """.data(using: .utf8)!
            
            let parser = GPXParser()
            let result = try await parser.parse(data: realisticGPX)
            
            // Verify name
            #expect(result.name == "Morning 5K Run")
            
            // Verify coordinates count
            #expect(result.coordinates.count == 5)
            
            // Verify duration (20 minutes = 1200 seconds)
            #expect(result.durationSeconds == 1200)
            
            // Verify elevation gain (5 + 5 + 7 = 17m, excluding the -2m drop)
            #expect(result.elevationGainMeters == 17.0)
            
            // Verify distance is reasonable (should be around 1km based on coordinate spread)
            #expect(result.distanceMeters > 500)
            #expect(result.distanceMeters < 2000)
            
            // Verify start and end times
            #expect(result.startTime != nil)
            #expect(result.endTime != nil)
        }
    }
}
