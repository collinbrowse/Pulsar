//
//  ContentView.swift
//  Pulsar
//
//  Created by Collin Browse on 10/27/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
            
            ActivitiesView()
                .tabItem {
                    Label("Activities", systemImage: "figure.run")
                }
            
            Text("Segments")
                .tabItem {
                    Label("Segments", systemImage: "flag.fill")
                }
            
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

// Placeholder for Profile Tab
struct ProfileTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    
    var currentProfile: Profile? {
        guard let userId = appState.currentUserId else { return nil }
        return profiles.first { $0.userId == userId }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let profile = currentProfile {
                        Text("@\(profile.username)")
                            .font(.headline)
                        if let fullName = profile.fullName {
                            Text(fullName)
                                .foregroundStyle(.secondary)
                        }
                    } else if let profile = appState.userProfile {
                        Text("@\(profile.username)")
                    }
                }
                
                Section("Preferences") {
                    Toggle("Use Metric Units", isOn: Binding(
                        get: { 
                            currentProfile?.useMetricUnits ?? false
                        },
                        set: { newValue in
                            if let profile = currentProfile {
                                profile.useMetricUnits = newValue
                                profile.updatedAt = Date()
                            } else if let userId = appState.currentUserId {
                                // Create a new profile if it doesn't exist
                                let newProfile = Profile(
                                    userId: userId,
                                    username: appState.userProfile?.username ?? "user",
                                    email: "", // Will be updated when profile is synced
                                    useMetricUnits: newValue
                                )
                                modelContext.insert(newProfile)
                            }
                            try? modelContext.save()
                        }
                    ))
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        // Sign out logic
                        AuthenticationService.shared.signOut()
                        appState.isAuthenticated = false
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Activity.self, inMemory: true)
        .environment(AppState())
}
