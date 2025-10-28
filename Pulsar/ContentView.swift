//
//  ContentView.swift
//  Pulsar
//
//  Created by Collin Browse on 10/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        TabView {
            ActivitiesView()
                .tabItem {
                    Label("Activities", systemImage: "figure.run")
                }
            
            Text("Feed")
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
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
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let profile = appState.userProfile {
                        Text("@\(profile.username)")
                    }
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
