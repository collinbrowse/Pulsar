//
//  MainTabView.swift
//  Pulsar
//
//  Main tab navigation for authenticated users
//

import SwiftUI

enum Tab: String, CaseIterable {
    case feed = "feed"
    case segments = "segments"
    case record = "record"
    case profile = "profile"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .feed: return "Feed"
        case .segments: return "Segments"
        case .record: return "Import"
        case .profile: return "Profile"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .feed: return "rectangle.stack"
        case .segments: return "flag"
        case .record: return "plus.circle"
        case .profile: return "person"
        case .settings: return "gearshape"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .feed: return "rectangle.stack.fill"
        case .segments: return "flag.fill"
        case .record: return "plus.circle.fill"
        case .profile: return "person.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = .feed
    @State private var showImportSheet = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tag(Tab.feed)
                .tabItem {
                    Label(Tab.feed.title, systemImage: selectedTab == .feed ? Tab.feed.selectedIcon : Tab.feed.icon)
                }
            
            SegmentsView()
                .tag(Tab.segments)
                .tabItem {
                    Label(Tab.segments.title, systemImage: selectedTab == .segments ? Tab.segments.selectedIcon : Tab.segments.icon)
                }
            
            // Center import button
            Color.clear
                .tag(Tab.record)
                .tabItem {
                    Label(Tab.record.title, systemImage: Tab.record.icon)
                }
            
            ProfileView()
                .tag(Tab.profile)
                .tabItem {
                    Label(Tab.profile.title, systemImage: selectedTab == .profile ? Tab.profile.selectedIcon : Tab.profile.icon)
                }
            
            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label(Tab.settings.title, systemImage: selectedTab == .settings ? Tab.settings.selectedIcon : Tab.settings.icon)
                }
        }
        .tint(Color.pulsarPrimary)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .record {
                // Reset to previous tab and show import sheet
                selectedTab = oldValue
                showImportSheet = true
                HapticFeedback.impact(.medium)
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
