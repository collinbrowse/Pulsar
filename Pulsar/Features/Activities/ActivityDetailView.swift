//
//  ActivityDetailView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import MapKit
import SwiftData
import SwiftUI

struct ActivityDetailView: View {
    let activity: Activity
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var hasRecalculated = false
    @State private var useMetric: Bool = false
    @State private var showFullScreenMap = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: activity.activityType.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text(activity.name)
                        .font(.title.bold())
                    
                    Text(activity.startDate.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Map
                if let trackPoints = activity.trackPoints, !trackPoints.isEmpty {
                    ZStack(alignment: .topTrailing) {
                        ActivityMapView(trackPoints: trackPoints, isInteractive: false, onTap: { showFullScreenMap = true })
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Transparent tap overlay that allows gestures to pass through
                        Color.clear
                            .contentShape(Rectangle())
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded { _ in
                                        showFullScreenMap = true
                                    }
                            )
                        
                        // Expand indicator (optional visual hint)
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .padding(8)
                            .allowsHitTesting(false) // Don't block taps
                    }
                    .padding(.horizontal)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .overlay {
                            VStack {
                                Image(systemName: "map.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text("No route data available")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                }
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(title: "Distance", value: formatDistance(activity.distance), icon: "location.fill")
                    StatCard(title: "Duration", value: formatDuration(activity.duration), icon: "clock.fill")
                    
                    if let avgSpeed = activity.avgSpeed {
                        StatCard(title: "Avg Speed", value: formatSpeed(avgSpeed), icon: "speedometer")
                    }
                    
                    if let elevation = activity.elevationGain {
                        StatCard(title: "Elevation", value: formatElevation(elevation), icon: "arrow.up.right")
                    }
                    
                    if let avgHR = activity.avgHeartRate {
                        StatCard(title: "Avg HR", value: "\(avgHR) bpm", icon: "heart.fill")
                    }
                    
                    if let avgPower = activity.avgPower {
                        StatCard(title: "Avg Power", value: "\(Int(avgPower))w", icon: "bolt.fill")
                    }
                }
                .padding(.horizontal)
                
                // Source Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Details")
                        .font(.headline)
                    
                    DetailRow(label: "Source", value: activity.source.displayName)
                    if let fileName = activity.originalFileName {
                        DetailRow(label: "File", value: fileName)
                    }
                    DetailRow(label: "Type", value: activity.activityType.displayName)
                    DetailRow(label: "Privacy", value: activity.isPrivate ? "Private" : "Public")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenMapView(trackPoints: activity.trackPoints ?? [])
        }
        .task {
            // Load metric preference from profile
            updateMetricPreference()
            
            // Automatically recalculate metrics if activity needs it
            if !hasRecalculated && ActivityService.shared.needsRecalculation(activity) {
                if let trackPoints = activity.trackPoints, !trackPoints.isEmpty {
                    do {
                        try await ActivityService.shared.recalculateMetrics(for: activity, modelContext: modelContext)
                        hasRecalculated = true
                    } catch {
                        // Silently fail - metrics will just be wrong
                        print("Failed to recalculate metrics: \(error)")
                    }
                }
            }
        }
    }
    
    private func updateMetricPreference() {
        guard let userId = appState.currentUserId else {
            useMetric = false
            return
        }
        
        let descriptor = FetchDescriptor<Profile>(
            predicate: #Predicate { profile in
                profile.userId == userId
            }
        )
        
        if let profile = try? modelContext.fetch(descriptor).first {
            useMetric = profile.useMetricUnits
        } else {
            useMetric = false
        }
    }
    
    // MARK: - Helpers
    
    private func formatDistance(_ meters: Double) -> String {
        UnitFormatter.shared.formatDistance(meters, useMetric: useMetric)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func formatSpeed(_ metersPerSecond: Double) -> String {
        UnitFormatter.shared.formatSpeed(metersPerSecond, useMetric: useMetric)
    }
    
    private func formatElevation(_ meters: Double) -> String {
        UnitFormatter.shared.formatElevation(meters, useMetric: useMetric)
    }
}

// MARK: - Map View

struct ActivityMapView: View {
    let trackPoints: [TrackPoint]
    let isInteractive: Bool
    let onTap: (() -> Void)?
    @State private var region: MKCoordinateRegion
    
    init(trackPoints: [TrackPoint], isInteractive: Bool = true, onTap: (() -> Void)? = nil) {
        self.trackPoints = trackPoints
        self.isInteractive = isInteractive
        self.onTap = onTap
        
        // Filter valid coordinates and calculate region
        let validCoordinates = trackPoints
            .filter { point in
                point.latitude >= -90 && point.latitude <= 90 &&
                point.longitude >= -180 && point.longitude <= 180 &&
                !(point.latitude == 0 && point.longitude == 0)
            }
            .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        guard !validCoordinates.isEmpty else {
            // Default region if no valid coordinates
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            ))
            return
        }
        
        let minLat = validCoordinates.map { $0.latitude }.min() ?? 0
        let maxLat = validCoordinates.map { $0.latitude }.max() ?? 0
        let minLon = validCoordinates.map { $0.longitude }.min() ?? 0
        let maxLon = validCoordinates.map { $0.longitude }.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = max((maxLat - minLat) * 1.3, 0.01) // Add 30% padding, minimum 0.01
        let lonDelta = max((maxLon - minLon) * 1.3, 0.01)
        
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        ))
    }
    
    var body: some View {
        ActivityMapViewRepresentable(trackPoints: trackPoints, region: $region, isInteractive: isInteractive, onTap: onTap)
    }
}

struct ActivityMapViewRepresentable: UIViewRepresentable {
    let trackPoints: [TrackPoint]
    @Binding var region: MKCoordinateRegion
    let isInteractive: Bool
    let onTap: (() -> Void)?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.isZoomEnabled = isInteractive
        mapView.isScrollEnabled = isInteractive
        mapView.isUserInteractionEnabled = isInteractive
        
        // Filter and sort track points
        let validPoints = trackPoints
            .filter { point in
                // Filter out invalid coordinates
                point.latitude >= -90 && point.latitude <= 90 &&
                point.longitude >= -180 && point.longitude <= 180 &&
                !(point.latitude == 0 && point.longitude == 0)
            }
            .sorted { $0.timestamp < $1.timestamp } // Sort by timestamp
        
        guard validPoints.count >= 2 else {
            return mapView
        }
        
        // Create coordinates array from valid, sorted points
        let coordinates = validPoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        // Add polyline only connecting valid GPS points
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        // Add start marker (first valid point)
        guard let firstPoint = validPoints.first else { return mapView }
        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = firstPoint.coordinate
        startAnnotation.title = "Start"
        mapView.addAnnotation(startAnnotation)
        
        // Add end marker (last valid point, only if different from start)
        if validPoints.count > 1, let lastPoint = validPoints.last {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = lastPoint.coordinate
            endAnnotation.title = "End"
            mapView.addAnnotation(endAnnotation)
        }
        
        // Store onTap in coordinator
        context.coordinator.onTap = onTap
        
        // Add tap gesture recognizer if onTap is provided
        if onTap != nil {
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
            tapGesture.numberOfTapsRequired = 1
            tapGesture.numberOfTouchesRequired = 1
            // Don't cancel touches - allow pan/zoom to work
            tapGesture.cancelsTouchesInView = false
            tapGesture.delegate = context.coordinator
            // Set a lower priority so pan/zoom gestures take precedence
            tapGesture.delaysTouchesBegan = false
            tapGesture.delaysTouchesEnded = false
            mapView.addGestureRecognizer(tapGesture)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.region = region
        mapView.isZoomEnabled = isInteractive
        mapView.isScrollEnabled = isInteractive
        mapView.isUserInteractionEnabled = isInteractive
        
        // Update coordinator's onTap callback
        context.coordinator.onTap = onTap
        
        // Add or update tap gesture recognizer
        if onTap != nil {
            // Remove old gesture if it exists
            if let oldGesture = context.coordinator.tapGesture {
                mapView.removeGestureRecognizer(oldGesture)
            }
            
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
            tapGesture.numberOfTapsRequired = 1
            tapGesture.numberOfTouchesRequired = 1
            tapGesture.cancelsTouchesInView = false
            tapGesture.delegate = context.coordinator
            tapGesture.delaysTouchesBegan = false
            tapGesture.delaysTouchesEnded = false
            mapView.addGestureRecognizer(tapGesture)
            context.coordinator.tapGesture = tapGesture
        } else {
            // Remove gesture if onTap is nil
            if let oldGesture = context.coordinator.tapGesture {
                mapView.removeGestureRecognizer(oldGesture)
                context.coordinator.tapGesture = nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var onTap: (() -> Void)?
        var tapGesture: UITapGestureRecognizer?
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended else { return }
            // Trigger the tap action
            DispatchQueue.main.async {
                self.onTap?()
            }
        }
        
        // Allow tap gesture to work - require pan/pinch to fail first
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Require pan and pinch gestures to fail before recognizing tap
            // This ensures tap only works when user isn't panning/zooming
            if otherGestureRecognizer is UIPanGestureRecognizer || 
               otherGestureRecognizer is UIPinchGestureRecognizer {
                return true
            }
            return false
        }
        
        // Don't allow simultaneous recognition with pan/pinch
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            false
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                renderer.lineCap = .round
                renderer.lineJoin = .round
                // Ensure we only draw the line, not fill
                renderer.fillColor = .clear
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "ActivityAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = annotation.title == "Start" ? .green : .red
            }
            
            return annotationView
        }
    }
}

// MARK: - Full Screen Map View

struct FullScreenMapView: View {
    let trackPoints: [TrackPoint]
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(trackPoints: [TrackPoint]) {
        self.trackPoints = trackPoints
        
        // Filter valid coordinates and calculate region
        let validCoordinates = trackPoints
            .filter { point in
                point.latitude >= -90 && point.latitude <= 90 &&
                point.longitude >= -180 && point.longitude <= 180 &&
                !(point.latitude == 0 && point.longitude == 0)
            }
            .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        guard !validCoordinates.isEmpty else {
            // Default region if no valid coordinates
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            ))
            return
        }
        
        let minLat = validCoordinates.map { $0.latitude }.min() ?? 0
        let maxLat = validCoordinates.map { $0.latitude }.max() ?? 0
        let minLon = validCoordinates.map { $0.longitude }.min() ?? 0
        let maxLon = validCoordinates.map { $0.longitude }.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = max((maxLat - minLat) * 1.3, 0.01) // Add 30% padding, minimum 0.01
        let lonDelta = max((maxLon - minLon) * 1.3, 0.01)
        
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                ActivityMapViewRepresentable(trackPoints: trackPoints, region: $region, isInteractive: true, onTap: nil)
                    .ignoresSafeArea()
                
                // Close button - bigger and positioned in top right
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                })
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Activity Route")
                        .font(.headline)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        ActivityDetailView(activity: Activity(
            userId: "test",
            name: "Morning Run",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        ))
        .modelContainer(for: [Activity.self, Profile.self], inMemory: true)
        .environment(AppState())
    }
}
