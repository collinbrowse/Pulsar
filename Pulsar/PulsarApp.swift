//
//  PulsarApp.swift
//  Pulsar
//
//  Main app entry point
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "App")

@main
struct PulsarApp: App {
    @State private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Profile.self,
            Activity.self,
            Segment.self,
            SegmentEffort.self,
            Follow.self,
            Kudos.self,
            Comment.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        configureApp()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Configuration
    
    private func configureApp() {
        logger.info("Pulsar app launching...")
        
        // Configure observability (analytics, crashlytics)
        Task { @MainActor in
            ObservabilityManager.shared.configure()
        }
        
        // Log configuration status
        if AppEnvironment.shared.isConfigured {
            logger.info("Environment configured successfully")
        } else {
            logger.warning("Environment not fully configured - check API keys")
        }
        
        // Configure appearance
        configureAppearance()
        
        logger.info("Pulsar app configured")
    }
    
    private func configureAppearance() {
        #if os(iOS)
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        #endif
    }
}
