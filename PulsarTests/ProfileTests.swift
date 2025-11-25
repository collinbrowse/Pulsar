//
//  ProfileTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Foundation
@testable import Pulsar
import SwiftData
import Testing

@Suite("Profile Model Tests")
@MainActor
struct ProfileTests {
    @Test("Profile should initialize with required fields")
    func testProfileInitialization() {
        let profile = Profile(
            userId: "test-user-id",
            username: "testuser",
            email: "test@example.com"
        )
        
        #expect(profile.userId == "test-user-id")
        #expect(profile.username == "testuser")
        #expect(profile.email == "test@example.com")
        #expect(profile.fullName == nil)
        #expect(profile.avatarURL == nil)
    }
    
    @Test("Profile should support optional fields")
    func testProfileOptionalFields() {
        let profile = Profile(
            userId: "test-user-id",
            username: "testuser",
            email: "test@example.com",
            fullName: "Test User",
            gender: .male,
            weightKg: 70.5,
            birthYear: 1990
        )
        
        #expect(profile.fullName == "Test User")
        #expect(profile.gender == .male)
        #expect(profile.weightKg == 70.5)
        #expect(profile.birthYear == 1990)
    }
    
    @Test("Profile should convert to DTO correctly")
    func testProfileToDTO() {
        let profile = Profile(
            userId: "test-user-id",
            username: "testuser",
            email: "test@example.com",
            fullName: "Test User",
            gender: .female,
            weightKg: 60.0,
            birthYear: 1995
        )
        
        let dto = profile.toDTO()
        
        #expect(dto.userId == "test-user-id")
        #expect(dto.username == "testuser")
        #expect(dto.fullName == "Test User")
        #expect(dto.gender == "female")
        #expect(dto.weightKg == 60.0)
        #expect(dto.birthYear == 1995)
    }
    
    @Test("Profile should create from DTO correctly")
    func testProfileFromDTO() {
        let dto = ProfileDTO(
            userId: "test-user-id",
            username: "testuser",
            fullName: "Test User",
            avatarUrl: "https://example.com/avatar.jpg",
            gender: "male",
            weightKg: 75.5,
            birthYear: 1988,
            useMetricUnits: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let profile = Profile.fromDTO(dto, email: "test@example.com")
        
        #expect(profile.userId == "test-user-id")
        #expect(profile.username == "testuser")
        #expect(profile.email == "test@example.com")
        #expect(profile.fullName == "Test User")
        #expect(profile.avatarURL == "https://example.com/avatar.jpg")
        #expect(profile.gender == .male)
        #expect(profile.weightKg == 75.5)
        #expect(profile.birthYear == 1988)
    }
    
    @Test("Gender enum should have correct display names")
    func testGenderDisplayNames() {
        #expect(Gender.male.displayName == "Male")
        #expect(Gender.female.displayName == "Female")
        #expect(Gender.other.displayName == "Other")
        #expect(Gender.preferNotToSay.displayName == "Prefer not to say")
    }
    
    @Test("Gender enum should have all cases")
    func testGenderAllCases() {
        let allCases = Gender.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.male))
        #expect(allCases.contains(.female))
        #expect(allCases.contains(.other))
        #expect(allCases.contains(.preferNotToSay))
    }
    
    @Test("ProfileDTO should decode dates in PostgreSQL format (with timezone offset)")
    func testProfileDTODecodingWithPostgreSQLDates() throws {
        // Simulate the actual JSON response from Supabase/PostgreSQL
        let json = """
        {
            "user_id": "14bb222f-e47c-47c9-ae90-a8fb3070d3cb",
            "username": "user_14bb222f",
            "full_name": "Collin Browse",
            "avatar_url": null,
            "gender": "male",
            "weight_kg": 80.00,
            "birth_year": 1994,
            "created_at": "2025-10-28T14:44:35+00:00",
            "updated_at": "2025-10-28T14:44:35+00:00"
        }
        """
        
        guard let jsonData = json.data(using: .utf8) else {
            throw TestError("Failed to convert JSON string to data")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // PostgreSQL returns dates in these formats:
            // "2025-10-28T14:44:35+00:00"
            // "2025-10-28T14:44:35Z"
            // "2025-10-28T14:44:35.123+00:00"
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            // Try format with timezone offset (PostgreSQL default): yyyy-MM-dd'T'HH:mm:ssZZZZZ
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Try format with fractional seconds: yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ
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
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        
        let profile = try decoder.decode(ProfileDTO.self, from: jsonData)
        
        #expect(profile.userId == "14bb222f-e47c-47c9-ae90-a8fb3070d3cb")
        #expect(profile.username == "user_14bb222f")
        #expect(profile.fullName == "Collin Browse")
        #expect(profile.avatarUrl == nil)
        #expect(profile.gender == "male")
        #expect(profile.weightKg == 80.00)
        #expect(profile.birthYear == 1994)
        #expect(profile.createdAt != nil)
        #expect(profile.updatedAt != nil)
    }
    
    @Test("ProfileDTO should decode dates in standard ISO 8601 format (with Z)")
    func testProfileDTODecodingWithStandardISO8601() throws {
        let json = """
        {
            "user_id": "test-id",
            "username": "testuser",
            "full_name": "Test User",
            "avatar_url": null,
            "gender": null,
            "weight_kg": null,
            "birth_year": null,
            "created_at": "2025-10-28T14:44:35Z",
            "updated_at": "2025-10-28T14:44:35Z"
        }
        """
        
        guard let jsonData = json.data(using: .utf8) else {
            throw TestError("Failed to convert JSON string to data")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // PostgreSQL returns dates in these formats:
            // "2025-10-28T14:44:35+00:00"
            // "2025-10-28T14:44:35Z"
            // "2025-10-28T14:44:35.123+00:00"
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            // Try format with timezone offset (PostgreSQL default): yyyy-MM-dd'T'HH:mm:ssZZZZZ
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Try format with fractional seconds: yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ
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
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        
        let profile = try decoder.decode(ProfileDTO.self, from: jsonData)
        
        #expect(profile.userId == "test-id")
        #expect(profile.username == "testuser")
        #expect(profile.createdAt != nil)
        #expect(profile.updatedAt != nil)
    }
}
