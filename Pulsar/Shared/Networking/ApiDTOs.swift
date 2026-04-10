//
//  ApiDTOs.swift
//  Pulsar
//
//  Codable DTOs for Supabase REST/RPC responses. Snake_case keys match API.
//

import Foundation

// MARK: - Activities table (app.activities)

struct ActivityRow: Codable, Sendable {
    let activityId: String
    let userId: String
    let activityType: String
    let name: String
    let distanceM: Double?
    let durationSec: Int?
    let elevationGainM: Double?
    let startTime: String?
    let endTime: String?

    enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case userId = "user_id"
        case activityType = "activity_type"
        case name
        case distanceM = "distance_m"
        case durationSec = "duration_sec"
        case elevationGainM = "elevation_gain_m"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

// MARK: - get_user_feed RPC result row

struct FeedItemRow: Codable, Sendable {
    let activityId: String
    let userId: String
    let username: String?
    let avatarUrl: String?
    let activityType: String
    let name: String
    let distanceM: Double?
    let durationSec: Int?
    let elevationGainM: Double?
    let startTime: String?
    let kudosCount: Int?
    let commentCount: Int?
    let userGaveKudos: Bool?

    enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case userId = "user_id"
        case username
        case avatarUrl = "avatar_url"
        case activityType = "activity_type"
        case name
        case distanceM = "distance_m"
        case durationSec = "duration_sec"
        case elevationGainM = "elevation_gain_m"
        case startTime = "start_time"
        case kudosCount = "kudos_count"
        case commentCount = "comment_count"
        case userGaveKudos = "user_gave_kudos"
    }
}

// MARK: - get_user_social_stats RPC result

struct SocialStatsRow: Codable, Sendable {
    let followerCount: Int?
    let followingCount: Int?
    let activityCount: Int?

    enum CodingKeys: String, CodingKey {
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case activityCount = "activity_count"
    }
}

// MARK: - app.profiles (Supabase)

struct ProfileDTO: Codable, Sendable {
    let userId: String
    let username: String
    let fullName: String?
    let avatarUrl: String?
}

// MARK: - Segments table (app.segments)

struct SegmentRowDTO: Codable, Sendable {
    let segmentId: String
    let name: String
    let activityType: String
    let distanceM: Double
    let elevationGainM: Double?
    let city: String?
    let state: String?
    let country: String?
    let effortCount: Int?
    let starCount: Int?
    let createdBy: String?

    enum CodingKeys: String, CodingKey {
        case segmentId = "segment_id"
        case name
        case activityType = "activity_type"
        case distanceM = "distance_m"
        case elevationGainM = "elevation_gain_m"
        case city
        case state
        case country
        case effortCount = "effort_count"
        case starCount = "star_count"
        case createdBy = "created_by"
    }
}

// MARK: - Mappers to UI models

extension ActivityRow {
    func toActivityData(userName: String) -> ActivityData {
        let dist = distanceM ?? 0
        let dur = durationSec ?? 0
        let pace: Int? = (dist > 0 && dur > 0) ? Int(Double(dur) / (dist / 1000)) : nil
        let date = startTime.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        return ActivityData(
            id: UUID(uuidString: activityId) ?? UUID(),
            name: name,
            type: ActivityType(rawValue: activityType) ?? .other,
            userName: userName,
            userAvatarURL: nil,
            distanceMeters: dist,
            durationSeconds: dur,
            elevationGainMeters: elevationGainM,
            paceSecondsPerKm: pace,
            startDate: date,
            routeCoordinates: [],
            kudosCount: 0,
            commentsCount: 0,
            hasKudos: false
        )
    }
}

extension FeedItemRow {
    func toActivityData() -> ActivityData {
        let dist = distanceM ?? 0
        let dur = durationSec ?? 0
        let pace: Int? = (dist > 0 && dur > 0) ? Int(Double(dur) / (dist / 1000)) : nil
        let date = startTime.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        return ActivityData(
            id: UUID(uuidString: activityId) ?? UUID(),
            name: name,
            type: ActivityType(rawValue: activityType) ?? .other,
            userName: username ?? "Athlete",
            userAvatarURL: avatarUrl.flatMap { URL(string: $0) },
            distanceMeters: dist,
            durationSeconds: dur,
            elevationGainMeters: elevationGainM,
            paceSecondsPerKm: pace,
            startDate: date,
            routeCoordinates: [],
            kudosCount: kudosCount ?? 0,
            commentsCount: commentCount ?? 0,
            hasKudos: userGaveKudos ?? false
        )
    }
}

extension SegmentRowDTO {
    func toSegmentData(currentUserID: String?) -> SegmentData {
        let cityStr: String? = [city, state, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
            .nilIfEmpty
        return SegmentData(
            id: UUID(uuidString: segmentId) ?? UUID(),
            name: name,
            type: ActivityType(rawValue: activityType) ?? .other,
            distanceMeters: distanceM,
            avgGradePercent: nil,
            elevationGainMeters: elevationGainM,
            city: cityStr,
            coordinates: [],
            effortCount: effortCount ?? 0,
            starCount: starCount ?? 0,
            isStarred: false,
            isCreatedByMe: currentUserID.map { $0 == createdBy } ?? false,
            komTime: nil,
            qomTime: nil
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
