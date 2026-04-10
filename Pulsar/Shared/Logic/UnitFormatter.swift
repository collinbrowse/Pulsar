//
//  UnitFormatter.swift
//  Pulsar
//
//  Distance, speed, and elevation strings for metric vs imperial display.
//

import Foundation

final class UnitFormatter: @unchecked Sendable {
    static let shared = UnitFormatter()
    
    private init() {}
    
    func formatDistance(_ meters: Double, useMetric: Bool) -> String {
        if useMetric {
            if meters >= 1000 {
                return String(format: "%.2f km", meters / 1000)
            }
            return String(format: "%.0f m", meters)
        }
        let miles = meters / 1609.34
        if miles >= 0.1 {
            return String(format: "%.2f mi", miles)
        }
        let feet = meters * 3.28084
        return String(format: "%.0f ft", feet)
    }
    
    func formatSpeed(_ metersPerSecond: Double, useMetric: Bool) -> String {
        if useMetric {
            let kmh = metersPerSecond * 3.6
            return String(format: "%.1f km/h", kmh)
        }
        let mph = metersPerSecond * 2.23694
        return String(format: "%.1f mph", mph)
    }
    
    func formatElevation(_ meters: Double, useMetric: Bool) -> String {
        if useMetric {
            return String(format: "%.0f m", meters)
        }
        let feet = meters * 3.28084
        return String(format: "%.0f ft", feet)
    }
}
