//
//  SegmentsFlowTests.swift
//  PulsarTests
//
//  Tests for segment filtering behavior.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("Segments Flow Tests")
struct SegmentsFlowTests {
    @Test("Explore tab returns all segments when no search text")
    func testExploreAllSegments() async throws {
        let segments = sampleSegments()
        
        let filtered = SegmentsFlow.filteredSegments(
            segments: segments,
            tab: .explore,
            searchText: ""
        )
        
        #expect(filtered.count == segments.count)
    }
    
    @Test("Starred tab only returns starred segments")
    func testStarredSegments() async throws {
        let segments = sampleSegments()
        
        let filtered = SegmentsFlow.filteredSegments(
            segments: segments,
            tab: .starred,
            searchText: ""
        )
        
        #expect(filtered.allSatisfy { $0.isStarred })
    }
    
    @Test("My Segments tab only returns user-created segments")
    func testMySegments() async throws {
        let segments = sampleSegments()
        
        let filtered = SegmentsFlow.filteredSegments(
            segments: segments,
            tab: .mySegments,
            searchText: ""
        )
        
        #expect(filtered.allSatisfy { $0.isCreatedByMe })
    }
    
    @Test("Search filters by name and city case-insensitively")
    func testSearchFiltersByNameAndCity() async throws {
        let segments = sampleSegments()
        
        let byName = SegmentsFlow.filteredSegments(
            segments: segments,
            tab: .explore,
            searchText: "golden gate"
        )
        #expect(byName.count == 1)
        #expect(byName.first?.name == "Golden Gate Bridge Run")
        
        let byCity = SegmentsFlow.filteredSegments(
            segments: segments,
            tab: .explore,
            searchText: "marin county"
        )
        #expect(byCity.count == 1)
        #expect(byCity.first?.city == "Marin County, CA")
    }
    
    // MARK: - Helper
    
    private func sampleSegments() -> [SegmentData] {
        [
            SegmentData(
                id: UUID(),
                name: "Golden Gate Bridge Run",
                type: .run,
                distanceMeters: 2743,
                avgGradePercent: 2.1,
                elevationGainMeters: 58,
                city: "San Francisco, CA",
                coordinates: [],
                effortCount: 12453,
                starCount: 892,
                isStarred: true,
                isCreatedByMe: false,
                komTime: 456,
                qomTime: 512
            ),
            SegmentData(
                id: UUID(),
                name: "Hawk Hill Climb",
                type: .ride,
                distanceMeters: 3200,
                avgGradePercent: 8.5,
                elevationGainMeters: 272,
                city: "Marin County, CA",
                coordinates: [],
                effortCount: 45678,
                starCount: 3245,
                isStarred: false,
                isCreatedByMe: false,
                komTime: 678,
                qomTime: 789
            ),
            SegmentData(
                id: UUID(),
                name: "Neighborhood Loop",
                type: .run,
                distanceMeters: 1000,
                avgGradePercent: 1.0,
                elevationGainMeters: 10,
                city: "San Francisco, CA",
                coordinates: [],
                effortCount: 100,
                starCount: 5,
                isStarred: true,
                isCreatedByMe: true,
                komTime: nil,
                qomTime: nil
            )
        ]
    }
}
