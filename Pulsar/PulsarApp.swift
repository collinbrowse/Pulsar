//
//  PulsarApp.swift
//  Pulsar
//
//  Main app entry point
//

import OSLog
import SwiftData
import SwiftUI

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
        logger.debug("Initializing ModelContainer for SwiftData models")
        
        // Use in-memory store for UI tests to avoid disk/sandbox issues when run from Xcode
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        
        if isUITesting {
            logger.debug("Running with in-memory store for UI tests")
        }
        
        // CloudKit is disabled for this configuration
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            logger.info("ModelContainer initialized successfully (inMemory: \(isUITesting))")
            return container
        } catch {
            // Log the error with as much detail as SwiftData provides
            logger.fault("Primary ModelContainer initialization failed: \(String(describing: error))")

            // Attempt a safe fallback to an in-memory store to avoid crashing on launch
            // This helps recover from migration/load issues on developer/test devices
            let fallbackConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )

            do {
                let fallback = try ModelContainer(for: schema, configurations: [fallbackConfig])
                logger.warning("Fell back to in-memory ModelContainer due to load issue. Persistent data will not be saved this run.")
                return fallback
            } catch {
                // If even the in-memory container fails, there's likely a schema definition problem
                logger.fault("Fallback in-memory ModelContainer failed: \(String(describing: error))")
                preconditionFailure("Could not create any ModelContainer: \(error)")
            }
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
