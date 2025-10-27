//
//  ProfileCreationView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileCreationView: View {
    let userID: String
    let email: String
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    
    @State private var username: String
    @State private var fullName: String
    @State private var gender: Gender = .preferNotToSay
    @State private var birthYear: String = ""
    @State private var weightKg: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    private let authService = AuthenticationService.shared
    
    init(userID: String, email: String, username: String, path: Binding<NavigationPath>) {
        self.userID = userID
        self.email = email
        self._path = path
        // Use the username that was provided during signup
        _username = State(initialValue: username)
        _fullName = State(initialValue: "")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Complete Your Profile")
                        .font(.system(size: 28, weight: .bold))
                    Text("Help us personalize your experience")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Avatar Selection
                VStack(spacing: 16) {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundStyle(Color(.systemGray4))
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose Photo", systemImage: "camera.fill")
                            .font(.subheadline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical)
                
                // Form
                VStack(spacing: 16) {
                    // Username (read-only, already set)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(username)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Full Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("John Doe", text: $fullName)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Full Name")
                            .accessibilityIdentifier("Full Name")
                    }
                    
                    // Gender
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Picker("Gender", selection: $gender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.displayName).tag(gender)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Birth Year
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Birth Year (Optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("1990", text: $birthYear)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("Used for age-group leaderboards")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg, Optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("70", text: $weightKg)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("Used for power calculations")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Error Message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 32)
                
                // Complete Button
                Button(action: completeProfile) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Complete Profile")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 32)
                .disabled(isLoading)
                .accessibilityIdentifier("Complete Profile")
                
                Spacer()
            }
        }
        .navigationTitle("Your Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .alert("Profile Created!", isPresented: $showSuccess) {
            Button("Get Started") {
                // TODO: Navigate to main app
                path = NavigationPath()
            }
        } message: {
            Text("Welcome to Pulsar! Your profile has been created successfully.")
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage = Image(uiImage: uiImage)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func completeProfile() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                // Create local profile with SwiftData
                let profile = Profile(
                    userID: userID,
                    username: username,
                    email: email,
                    fullName: fullName.isEmpty ? nil : fullName,
                    gender: gender,
                    weightKg: Double(weightKg),
                    birthYear: Int(birthYear)
                )
                
                modelContext.insert(profile)
                try modelContext.save()
                
                // Sync to backend
                let dto = profile.toDTO()
                try await authService.updateProfile(dto)
                
                // Track completion
                ObservabilityManager.shared.track(event: "profile_created", properties: [
                    "user_id": userID,
                    "has_full_name": !fullName.isEmpty,
                    "has_birth_year": !birthYear.isEmpty,
                    "has_weight": !weightKg.isEmpty
                ])
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileCreationView(
            userID: "test-user-id",
            email: "test@example.com",
            username: "testuser",
            path: .constant(NavigationPath())
        )
    }
    .modelContainer(for: Profile.self, inMemory: true)
}

