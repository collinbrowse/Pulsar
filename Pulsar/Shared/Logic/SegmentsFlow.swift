//
//  SegmentsFlow.swift
//  Pulsar
//
//  Pure helpers for segment filtering so behavior is easy to unit test.
//

import Foundation

enum SegmentsFlow {
    static func filteredSegments(
        segments: [SegmentData],
        tab: SegmentTab,
        searchText: String
    ) -> [SegmentData] {
        var result = segments
        
        switch tab {
        case .starred:
            result = result.filter { $0.isStarred }
        case .mySegments:
            result = result.filter { $0.isCreatedByMe }
        case .explore:
            break
        }
        
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return result }
        
        return result.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) ||
            ($0.city?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }
}
