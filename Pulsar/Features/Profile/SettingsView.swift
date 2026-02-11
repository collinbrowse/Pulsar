//
//  SettingsView.swift
//  Pulsar
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    
    // Settings state
    @AppStorage("distanceUnit") private var distanceUnit: DistanceUnit = .kilometers
    @AppStorage("paceUnit") private var paceUnit: PaceUnit = .minPerKm
    @AppStorage("defaultVisibility") private var defaultVisibility: Visibility = .publicVisible
    @AppStorage("showHeartRate") private var showHeartRate = true
    @AppStorage("showPower") private var showPower = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("kudosNotifications") private var kudosNotifications = true
    @AppStorage("commentNotifications") private var commentNotifications = true
    @AppStorage("followerNotifications") private var followerNotifications = true
    
    var body: some View {
        NavigationStack {
            Form {
                // Account Section
                Section {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            AsyncProfileImage(url: nil, size: 50)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appState.userProfile?.fullName ?? "Athlete")
                                    .font(.headlineSmall)
                                
                                Text(appState.userProfile?.username ?? "@athlete")
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                } header: {
                    Text("Account")
                }
                
                // Units Section
                Section {
                    Picker("Distance", selection: $distanceUnit) {
                        ForEach(DistanceUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    
                    Picker("Pace", selection: $paceUnit) {
                        ForEach(PaceUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                } header: {
                    Text("Units")
                }
                
                // Privacy Section
                Section {
                    Picker("Default Activity Visibility", selection: $defaultVisibility) {
                        ForEach(Visibility.allCases, id: \.self) { visibility in
                            Label(visibility.displayName, systemImage: visibility.icon)
                                .tag(visibility)
                        }
                    }
                    
                    NavigationLink {
                        PrivacyZonesView()
                    } label: {
                        Label("Privacy Zones", systemImage: "location.slash")
                    }
                    
                    NavigationLink {
                        BlockedUsersView()
                    } label: {
                        Label("Blocked Users", systemImage: "person.slash")
                    }
                } header: {
                    Text("Privacy")
                }
                
                // Display Section
                Section {
                    Toggle("Show Heart Rate", isOn: $showHeartRate)
                    Toggle("Show Power", isOn: $showPower)
                } header: {
                    Text("Display")
                } footer: {
                    Text("Control which metrics are shown on your activities.")
                }
                
                // Notifications Section
                Section {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        Toggle("Kudos", isOn: $kudosNotifications)
                        Toggle("Comments", isOn: $commentNotifications)
                        Toggle("New Followers", isOn: $followerNotifications)
                    }
                } header: {
                    Text("Notifications")
                }
                
                // Connected Services Section
                Section {
                    NavigationLink {
                        ConnectedServicesView()
                    } label: {
                        Label("Connected Services", systemImage: "link")
                    }
                    
                    NavigationLink {
                        DataExportView()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Data")
                }
                
                // Support Section
                Section {
                    Button {
                        openURL(URL(string: "https://pulsar.app/help")!)
                    } label: {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                    
                    Button {
                        openURL(URL(string: "mailto:support@pulsar.app")!)
                    } label: {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                } header: {
                    Text("Support")
                }
                
                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAccountAlert = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
    }
    
    private func signOut() {
        SettingsFlow.signOut(appState: appState)
        HapticFeedback.notification(.success)
    }
    
    private func deleteAccount() {
        // In production, call API to delete account and then clear state.
        SettingsFlow.deleteAccount(appState: appState)
        HapticFeedback.notification(.success)
    }
}

// MARK: - Units

enum DistanceUnit: String, CaseIterable {
    case kilometers = "km"
    case miles = "mi"
    
    var displayName: String {
        switch self {
        case .kilometers: return "Kilometers"
        case .miles: return "Miles"
        }
    }
}

enum PaceUnit: String, CaseIterable {
    case minPerKm = "min/km"
    case minPerMile = "min/mi"
    
    var displayName: String {
        switch self {
        case .minPerKm: return "min/km"
        case .minPerMile: return "min/mi"
        }
    }
}

// MARK: - Supporting Views

struct PrivacyZonesView: View {
    @State private var zones: [PrivacyZone] = [
        PrivacyZone(name: "Home", latitude: 37.7749, longitude: -122.4194, radiusMeters: 500),
        PrivacyZone(name: "Work", latitude: 37.7899, longitude: -122.4094, radiusMeters: 300)
    ]
    
    var body: some View {
        List {
            ForEach(zones) { zone in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(zone.name)
                            .font(.headlineSmall)
                        
                        Text("\(Int(zone.radiusMeters))m radius")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(true))
                }
            }
            .onDelete { _ in }
            
            Button {
                // Add new zone
            } label: {
                Label("Add Privacy Zone", systemImage: "plus")
            }
        }
        .navigationTitle("Privacy Zones")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyZone: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let radiusMeters: Double
}

struct BlockedUsersView: View {
    var body: some View {
        List {
            Text("No blocked users")
                .foregroundStyle(Color.textSecondary)
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConnectedServicesView: View {
    var body: some View {
        List {
            Section {
                ServiceRow(name: "Apple Health", icon: "heart.fill", color: .pulsarError, isConnected: true)
                ServiceRow(name: "Garmin Connect", icon: "applewatch", color: .blue, isConnected: false)
                ServiceRow(name: "Wahoo", icon: "bicycle", color: .activityRide, isConnected: false)
            } header: {
                Text("Fitness Services")
            }
            
            Section {
                ServiceRow(name: "Apple Watch", icon: "applewatch", color: .pulsarPrimary, isConnected: true)
            } header: {
                Text("Devices")
            }
        }
        .navigationTitle("Connected Services")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ServiceRow: View {
    let name: String
    let icon: String
    let color: Color
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(name)
            
            Spacer()
            
            if isConnected {
                Text("Connected")
                    .font(.caption)
                    .foregroundStyle(Color.pulsarSuccess)
            } else {
                Button("Connect") {
                    // Connect service
                }
                .font(.caption)
                .foregroundStyle(Color.pulsarPrimary)
            }
        }
    }
}

struct DataExportView: View {
    @State private var isExporting = false
    
    var body: some View {
        List {
            Section {
                Button {
                    exportData(format: .gpx)
                } label: {
                    Label("Export as GPX", systemImage: "doc")
                }
                
                Button {
                    exportData(format: .tcx)
                } label: {
                    Label("Export as TCX", systemImage: "doc")
                }
                
                Button {
                    exportData(format: .csv)
                } label: {
                    Label("Export as CSV", systemImage: "tablecells")
                }
            } header: {
                Text("Export Format")
            } footer: {
                Text("Export all your activities in the selected format.")
            }
            
            Section {
                Button(role: .destructive) {
                    // Request data deletion
                } label: {
                    Label("Request Data Deletion", systemImage: "trash")
                }
            } footer: {
                Text("Request to have all your data permanently deleted. This process may take up to 30 days.")
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportData(format: ExportFormat) {
        isExporting = true
        // Export logic
    }
}

enum ExportFormat {
    case gpx, tcx, csv
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (1)")
                        .foregroundStyle(Color.textSecondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2026.02.04")
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            Section {
                Link("Privacy Policy", destination: URL(string: "https://pulsar.app/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://pulsar.app/terms")!)
                Link("Open Source Licenses", destination: URL(string: "https://pulsar.app/licenses")!)
            }
            
            Section {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(LinearGradient.pulsarGradient)
                    
                    Text("Pulsar")
                        .font(.headlineLarge)
                    
                    Text("Made with love for athletes everywhere")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
