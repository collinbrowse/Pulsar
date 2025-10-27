//
//  ProfileTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Testing
import Foundation
import SwiftData
@testable import Pulsar

@Suite("Profile Model Tests")
struct ProfileTests {
    
    @Test("Profile should initialize with required fields")
    func testProfileInitialization() {
        let profile = Profile(
            userID: "test-user-id",
            username: "testuser",
            email: "test@example.com"
        )
        
        #expect(profile.userID == "test-user-id")
        #expect(profile.username == "testuser")
        #expect(profile.email == "test@example.com")
        #expect(profile.fullName == nil)
        #expect(profile.avatarURL == nil)
    }
    
    @Test("Profile should support optional fields")
    func testProfileOptionalFields() {
        let profile = Profile(
            userID: "test-user-id",
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
            userID: "test-user-id",
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
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let profile = Profile.fromDTO(dto, email: "test@example.com")
        
        #expect(profile.userID == "test-user-id")
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
}

