//
//  UnitFormatter.swift
//  Pulsar
//
//  Created on 11/24/25.
//

import Foundation

/// Utility for formatting activity metrics in metric or imperial units
@MainActor
final class UnitFormatter {
    static let shared = UnitFormatter()
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Get the current unit preference from user profile
    /// Defaults to metric (true) if profile not available
    func useMetricUnits(profile: Profile?) -> Bool {
        // Will be implemented once Profile model is updated
        return profile?.useMetricUnits ?? false
    }
    
    // MARK: - Distance Formatting
    
    func formatDistance(_ meters: Double, useMetric: Bool) -> String {
        if useMetric {
            let km = meters / 1000
            if km >= 1 {
                return String(format: "%.2f km", km)
            } else {
                return String(format: "%.0f m", meters)
            }
        } else {
            let miles = meters / 1609.34
            let feet = meters * 3.28084
            if miles >= 1 {
                return String(format: "%.2f mi", miles)
            } else {
                return String(format: "%.0f ft", feet)
            }
        }
    }
    
    // MARK: - Speed Formatting
    
    func formatSpeed(_ metersPerSecond: Double, useMetric: Bool) -> String {
        if useMetric {
            let kmh = metersPerSecond * 3.6
            return String(format: "%.1f km/h", kmh)
        } else {
            let mph = metersPerSecond * 2.23694
            return String(format: "%.1f mph", mph)
        }
    }
    
    // MARK: - Elevation Formatting
    
    func formatElevation(_ meters: Double, useMetric: Bool) -> String {
        if useMetric {
            return String(format: "%.0f m", meters)
        } else {
            let feet = meters * 3.28084
            return String(format: "%.0f ft", feet)
        }
    }
    
    // MARK: - Pace Formatting (for running)
    
    func formatPace(_ secondsPerMeter: Double, useMetric: Bool) -> String {
        if useMetric {
            // Minutes per kilometer
            let minutesPerKm = (secondsPerMeter * 1000) / 60
            let minutes = Int(minutesPerKm)
            let seconds = Int((minutesPerKm - Double(minutes)) * 60)
            return String(format: "%d:%02d min/km", minutes, seconds)
        } else {
            // Minutes per mile
            let minutesPerMile = (secondsPerMeter * 1609.34) / 60
            let minutes = Int(minutesPerMile)
            let seconds = Int((minutesPerMile - Double(minutes)) * 60)
            return String(format: "%d:%02d min/mi", minutes, seconds)
        }
    }
}

