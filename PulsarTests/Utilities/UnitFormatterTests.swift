//
//  UnitFormatterTests.swift
//  PulsarTests
//
//  Created on 11/24/25.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("UnitFormatter Tests")
@MainActor
struct UnitFormatterTests {
    let formatter = UnitFormatter.shared
    
    // MARK: - formatDistance Tests
    
    @Test("Format distance in metric - kilometers")
    func testFormatDistanceMetricKilometers() {
        let result = formatter.formatDistance(5000, useMetric: true) // 5 km
        #expect(result == "5.00 km")
    }
    
    @Test("Format distance in metric - meters")
    func testFormatDistanceMetricMeters() {
        let result = formatter.formatDistance(500, useMetric: true) // 500 m
        #expect(result == "500 m")
    }
    
    @Test("Format distance in metric - exactly 1 km")
    func testFormatDistanceMetricExactly1km() {
        let result = formatter.formatDistance(1000, useMetric: true) // 1 km
        #expect(result == "1.00 km")
    }
    
    @Test("Format distance in imperial - miles")
    func testFormatDistanceImperialMiles() {
        let result = formatter.formatDistance(1609.34, useMetric: false) // 1 mile
        #expect(result == "1.00 mi")
    }
    
    @Test("Format distance in imperial - feet")
    func testFormatDistanceImperialFeet() {
        let result = formatter.formatDistance(500, useMetric: false) // ~1640 ft
        #expect(result == "1640 ft")
    }
    
    @Test("Format distance in imperial - exactly 1 mile")
    func testFormatDistanceImperialExactly1Mile() {
        let result = formatter.formatDistance(1609.34, useMetric: false) // 1 mile
        #expect(result == "1.00 mi")
    }
    
    @Test("Format distance - zero meters")
    func testFormatDistanceZero() {
        let metricResult = formatter.formatDistance(0, useMetric: true)
        #expect(metricResult == "0 m")
        
        let imperialResult = formatter.formatDistance(0, useMetric: false)
        #expect(imperialResult == "0 ft")
    }
    
    @Test("Format distance - very large value")
    func testFormatDistanceVeryLarge() {
        let result = formatter.formatDistance(100000, useMetric: true) // 100 km
        #expect(result == "100.00 km")
        
        let imperialResult = formatter.formatDistance(160934, useMetric: false) // 100 miles
        #expect(imperialResult == "100.00 mi")
    }
    
    // MARK: - formatSpeed Tests
    
    @Test("Format speed in metric - km/h")
    func testFormatSpeedMetric() {
        let result = formatter.formatSpeed(10, useMetric: true) // 10 m/s = 36 km/h
        #expect(result == "36.0 km/h")
    }
    
    @Test("Format speed in imperial - mph")
    func testFormatSpeedImperial() {
        let result = formatter.formatSpeed(10, useMetric: false) // 10 m/s ≈ 22.37 mph
        #expect(result == "22.4 mph")
    }
    
    @Test("Format speed - zero")
    func testFormatSpeedZero() {
        let metricResult = formatter.formatSpeed(0, useMetric: true)
        #expect(metricResult == "0.0 km/h")
        
        let imperialResult = formatter.formatSpeed(0, useMetric: false)
        #expect(imperialResult == "0.0 mph")
    }
    
    @Test("Format speed - very fast")
    func testFormatSpeedVeryFast() {
        let result = formatter.formatSpeed(50, useMetric: true) // 50 m/s = 180 km/h
        #expect(result == "180.0 km/h")
        
        let imperialResult = formatter.formatSpeed(50, useMetric: false) // ≈ 111.8 mph
        #expect(imperialResult == "111.8 mph")
    }
    
    // MARK: - formatElevation Tests
    
    @Test("Format elevation in metric - meters")
    func testFormatElevationMetric() {
        let result = formatter.formatElevation(1000, useMetric: true)
        #expect(result == "1000 m")
    }
    
    @Test("Format elevation in imperial - feet")
    func testFormatElevationImperial() {
        let result = formatter.formatElevation(1000, useMetric: false) // ≈ 3280.84 ft
        #expect(result == "3281 ft")
    }
    
    @Test("Format elevation - zero")
    func testFormatElevationZero() {
        let metricResult = formatter.formatElevation(0, useMetric: true)
        #expect(metricResult == "0 m")
        
        let imperialResult = formatter.formatElevation(0, useMetric: false)
        #expect(imperialResult == "0 ft")
    }
    
    @Test("Format elevation - very high")
    func testFormatElevationVeryHigh() {
        let result = formatter.formatElevation(8848, useMetric: true) // Mount Everest
        #expect(result == "8848 m")
        
        let imperialResult = formatter.formatElevation(8848, useMetric: false) // ≈ 29029 ft
        #expect(imperialResult == "29029 ft")
    }
    
    // MARK: - formatPace Tests
    
    @Test("Format pace in metric - min/km")
    func testFormatPaceMetric() {
        // 5 min/km = 300 seconds per 1000 meters = 0.3 seconds per meter
        let secondsPerMeter = 0.3
        let result = formatter.formatPace(secondsPerMeter, useMetric: true)
        #expect(result == "5:00 min/km")
    }
    
    @Test("Format pace in imperial - min/mi")
    func testFormatPaceImperial() {
        // 8 min/mi = 480 seconds per 1609.34 meters ≈ 0.298 seconds per meter
        let secondsPerMeter = 0.298
        let result = formatter.formatPace(secondsPerMeter, useMetric: false)
        // Should be approximately 8:00 min/mi
        #expect(result.contains("min/mi"))
    }
    
    @Test("Format pace - fast pace")
    func testFormatPaceFast() {
        // 3 min/km = 180 seconds per 1000 meters = 0.18 seconds per meter
        let secondsPerMeter = 0.18
        let result = formatter.formatPace(secondsPerMeter, useMetric: true)
        #expect(result == "3:00 min/km")
    }
    
    @Test("Format pace - slow pace")
    func testFormatPaceSlow() {
        // 10 min/km = 600 seconds per 1000 meters = 0.6 seconds per meter
        let secondsPerMeter = 0.6
        let result = formatter.formatPace(secondsPerMeter, useMetric: true)
        #expect(result == "10:00 min/km")
    }
    
    @Test("Format pace - with seconds")
    func testFormatPaceWithSeconds() {
        // 5:30 min/km = 330 seconds per 1000 meters = 0.33 seconds per meter
        let secondsPerMeter = 0.33
        let result = formatter.formatPace(secondsPerMeter, useMetric: true)
        #expect(result == "5:30 min/km")
    }
    
    @Test("Format pace - zero")
    func testFormatPaceZero() {
        let result = formatter.formatPace(0, useMetric: true)
        #expect(result == "0:00 min/km")
        
        let imperialResult = formatter.formatPace(0, useMetric: false)
        #expect(imperialResult == "0:00 min/mi")
    }
    
    // MARK: - useMetricUnits Tests
    
    @Test("useMetricUnits with profile - metric")
    func testUseMetricUnitsWithMetricProfile() {
        let profile = Profile(
            userId: "test",
            username: "testuser",
            email: "test@example.com",
            useMetricUnits: true
        )
        
        let result = formatter.useMetricUnits(profile: profile)
        #expect(result == true)
    }
    
    @Test("useMetricUnits with profile - imperial")
    func testUseMetricUnitsWithImperialProfile() {
        let profile = Profile(
            userId: "test",
            username: "testuser",
            email: "test@example.com",
            useMetricUnits: false
        )
        
        let result = formatter.useMetricUnits(profile: profile)
        #expect(result == false)
    }
    
    @Test("useMetricUnits with nil profile")
    func testUseMetricUnitsWithNilProfile() {
        let result = formatter.useMetricUnits(profile: nil)
        #expect(result == false) // Defaults to false (imperial)
    }
    
    // MARK: - Edge Cases
    
    @Test("Format distance - very small value")
    func testFormatDistanceVerySmall() {
        let result = formatter.formatDistance(0.5, useMetric: true)
        #expect(result == "0 m") // 0.5 meters rounds to 0 m with %.0f format
        
        let imperialResult = formatter.formatDistance(0.5, useMetric: false)
        // 0.5 meters = 1.64 feet, rounds to 2 ft with %.0f format
        #expect(imperialResult == "2 ft")
    }
    
    @Test("Format speed - very slow")
    func testFormatSpeedVerySlow() {
        let result = formatter.formatSpeed(0.1, useMetric: true) // 0.1 m/s = 0.36 km/h
        #expect(result == "0.4 km/h") // Rounded to 1 decimal
        
        let imperialResult = formatter.formatSpeed(0.1, useMetric: false) // ≈ 0.22 mph
        #expect(imperialResult == "0.2 mph")
    }
    
    @Test("Format pace - very fast pace")
    func testFormatPaceVeryFast() {
        // 2 min/km = 120 seconds per 1000 meters = 0.12 seconds per meter
        let secondsPerMeter = 0.12
        let result = formatter.formatPace(secondsPerMeter, useMetric: true)
        #expect(result == "2:00 min/km")
    }
    
    @Test("Format pace - very slow pace")
    func testFormatPaceVerySlow() {
        // 15 min/km = 900 seconds per 1000 meters = 0.9 seconds per meter
        let secondsPerMeter = 0.9
        let result = formatter.formatPace(secondsPerMeter, useMetric: true)
        #expect(result == "15:00 min/km")
    }
}
