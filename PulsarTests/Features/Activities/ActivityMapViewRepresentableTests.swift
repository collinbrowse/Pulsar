//
//  ActivityMapViewRepresentableTests.swift
//  PulsarTests
//
//  Created on 12/27/25.
//

import MapKit
@testable import Pulsar
import SwiftUI
import Testing

@Suite("ActivityMapViewRepresentable Tests")
@MainActor
struct ActivityMapViewRepresentableTests {
    // MARK: - Test Fixtures
    
    private func createTestTrackPoints() -> [TrackPoint] {
        let now = Date()
        return [
            TrackPoint(latitude: 37.7749, longitude: -122.4194, timestamp: now),
            TrackPoint(latitude: 37.7750, longitude: -122.4195, timestamp: now.addingTimeInterval(1)),
            TrackPoint(latitude: 37.7751, longitude: -122.4196, timestamp: now.addingTimeInterval(2)),
            TrackPoint(latitude: 37.7752, longitude: -122.4197, timestamp: now.addingTimeInterval(3))
        ]
    }
    
    private func createTestRegion() -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    // MARK: - Helper to create representable with context
    
    private struct RepresentableContext {
        let representable: ActivityMapViewRepresentable
        let mapView: MKMapView
        let coordinator: ActivityMapViewRepresentable.Coordinator
    }
    
    private func createRepresentableAndMapView(
        trackPoints: [TrackPoint],
        onTap: (() -> Void)? = nil
    ) -> RepresentableContext {
        let region = createTestRegion()
        let binding = Binding(get: { region }, set: { _ in })
        
        let representable = ActivityMapViewRepresentable(
            trackPoints: trackPoints,
            region: binding,
            isInteractive: true,
            onTap: onTap
        )
        
        let coordinator = representable.makeCoordinator()
        
        // Create a mock context - we'll use the coordinator directly
        // Since we can't easily create a real Context, we'll manually set up the map view
        // similar to how makeUIView does it
        let mapView = MKMapView()
        mapView.delegate = coordinator
        mapView.region = region
        
        // Add overlays and annotations like makeUIView does
        let validPoints = trackPoints
            .filter { point in
                point.latitude >= -90 && point.latitude <= 90 &&
                point.longitude >= -180 && point.longitude <= 180 &&
                !(point.latitude == 0 && point.longitude == 0)
            }
            .sorted { $0.timestamp < $1.timestamp }
        
        if validPoints.count >= 2 {
            let coordinates = validPoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
            
            if let firstPoint = validPoints.first {
                let startAnnotation = MKPointAnnotation()
                startAnnotation.coordinate = firstPoint.coordinate
                startAnnotation.title = "Start"
                mapView.addAnnotation(startAnnotation)
            }
            
            if validPoints.count > 1, let lastPoint = validPoints.last {
                let endAnnotation = MKPointAnnotation()
                endAnnotation.coordinate = lastPoint.coordinate
                endAnnotation.title = "End"
                mapView.addAnnotation(endAnnotation)
            }
        }
        
        coordinator.onTap = onTap
        
        if onTap != nil {
            let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(ActivityMapViewRepresentable.Coordinator.handleTap(_:)))
            tapGesture.numberOfTapsRequired = 1
            tapGesture.numberOfTouchesRequired = 1
            tapGesture.cancelsTouchesInView = false
            tapGesture.delegate = coordinator
            tapGesture.delaysTouchesBegan = false
            tapGesture.delaysTouchesEnded = false
            mapView.addGestureRecognizer(tapGesture)
            coordinator.tapGesture = tapGesture
        }
        
        return RepresentableContext(representable: representable, mapView: mapView, coordinator: coordinator)
    }
    
    // MARK: - Tests
    
    @Test("dismantleUIView should clean up map view delegate")
    func testDismantleUIViewRemovesDelegate() async throws {
        let trackPoints = createTestTrackPoints()
        let context = createRepresentableAndMapView(trackPoints: trackPoints)
        let representable = context.representable
        let mapView = context.mapView
        let coordinator = context.coordinator
        
        // Verify delegate is set
        #expect(mapView.delegate != nil)
        #expect(mapView.delegate === coordinator)
        
        // Call dismantleUIView to clean up
        representable.dismantleUIView(mapView, coordinator: coordinator)
        
        // Verify delegate is removed (set to nil)
        #expect(mapView.delegate == nil)
    }
    
    @Test("dismantleUIView should remove all overlays")
    func testDismantleUIViewRemovesOverlays() async throws {
        let trackPoints = createTestTrackPoints()
        let context = createRepresentableAndMapView(trackPoints: trackPoints)
        let representable = context.representable
        let mapView = context.mapView
        let coordinator = context.coordinator
        
        // Verify overlays are added
        #expect(!mapView.overlays.isEmpty)
        
        // Call dismantleUIView to clean up
        representable.dismantleUIView(mapView, coordinator: coordinator)
        
        // Verify overlays are removed
        #expect(mapView.overlays.isEmpty)
    }
    
    @Test("dismantleUIView should remove all annotations")
    func testDismantleUIViewRemovesAnnotations() async throws {
        let trackPoints = createTestTrackPoints()
        let context = createRepresentableAndMapView(trackPoints: trackPoints)
        let representable = context.representable
        let mapView = context.mapView
        let coordinator = context.coordinator
        
        // Verify annotations are added (start and end markers)
        let nonUserLocationAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        #expect(!nonUserLocationAnnotations.isEmpty)
        
        // Call dismantleUIView to clean up
        representable.dismantleUIView(mapView, coordinator: coordinator)
        
        // Verify annotations are removed (only user location might remain)
        let remainingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        #expect(remainingAnnotations.isEmpty)
    }
    
    @Test("dismantleUIView should remove gesture recognizers")
    func testDismantleUIViewRemovesGestureRecognizers() async throws {
        var tapCalled = false
        let trackPoints = createTestTrackPoints()
        let context = createRepresentableAndMapView(
            trackPoints: trackPoints,
            onTap: { tapCalled = true }
        )
        let representable = context.representable
        let mapView = context.mapView
        let coordinator = context.coordinator
        
        // Verify gesture recognizer is added
        let tapGestures = mapView.gestureRecognizers?.filter { $0 is UITapGestureRecognizer } ?? []
        #expect(!tapGestures.isEmpty)
        #expect(coordinator.tapGesture != nil)
        
        // Call dismantleUIView to clean up
        representable.dismantleUIView(mapView, coordinator: coordinator)
        
        // Verify gesture recognizer is removed
        let remainingTapGestures = mapView.gestureRecognizers?.filter { $0 is UITapGestureRecognizer } ?? []
        #expect(remainingTapGestures.isEmpty)
        #expect(coordinator.tapGesture == nil)
    }
    
    @Test("dismantleUIView should clean up coordinator")
    func testDismantleUIViewCleansUpCoordinator() async throws {
        var tapCalled = false
        let trackPoints = createTestTrackPoints()
        let context = createRepresentableAndMapView(
            trackPoints: trackPoints,
            onTap: { tapCalled = true }
        )
        let representable = context.representable
        let mapView = context.mapView
        let coordinator = context.coordinator
        
        // Verify coordinator has properties set
        #expect(coordinator.onTap != nil)
        #expect(coordinator.tapGesture != nil)
        
        // Call dismantleUIView to clean up
        representable.dismantleUIView(mapView, coordinator: coordinator)
        
        // Verify coordinator is cleaned up
        #expect(coordinator.tapGesture == nil)
        #expect(coordinator.onTap == nil)
    }
    
    @Test("dismantleUIView should execute on main thread")
    func testDismantleUIViewExecutesOnMainThread() async throws {
        let trackPoints = createTestTrackPoints()
        let context = createRepresentableAndMapView(trackPoints: trackPoints)
        let representable = context.representable
        let mapView = context.mapView
        let coordinator = context.coordinator
        
        // Since we're @MainActor, we're guaranteed to be on the main thread
        // Call dismantleUIView - should execute on main thread (assertion in dismantleUIView will verify)
        // The assert in dismantleUIView will catch if it's called off the main thread
        representable.dismantleUIView(mapView, coordinator: coordinator)
        
        // If we get here without crashing, the assert passed and we were on main thread
        #expect(true) // Test passes if no assertion failure occurred
    }
}
