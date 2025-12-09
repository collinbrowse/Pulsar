//
//  PulsarApp.swift
//  Pulsar
//
//  Created by Collin Browse on 10/27/25.
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
            Item.self,
            Profile.self,
            Activity.self,
            TrackPoint.self,
            Follow.self,
            Kudo.self,
            Comment.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
            if appState.isAuthenticated {
                ContentView()
                    .environment(appState)
            } else {
                OnboardingCoordinator()
                    .environment(appState)
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Configuration
    
    private func configureApp() {
        logger.info("Pulsar app launching...")
        
        // Restore authentication session from Keychain
        Task { @MainActor in
            AuthenticationService.shared.restoreSessionIfNeeded(appState: appState)
            
            // Sync data from backend if user is authenticated
            if appState.isAuthenticated, let userId = appState.currentUserId {
                let modelContext = sharedModelContainer.mainContext
                do {
                    // Sync activities from backend
                    try await ActivityService.shared.syncActivitiesFromBackend(
                        for: userId,
                        modelContext: modelContext,
                        appState: appState
                    )
                    // Retry any pending activities that failed to sync
                    await ActivityService.shared.syncPendingActivities(
                        for: userId,
                        modelContext: modelContext,
                        appState: appState
                    )
                    
                    // Sync social data from backend (follows, kudos, comments)
                    try await SocialService.shared.syncFollowsFromBackend(
                        for: userId,
                        modelContext: modelContext
                    )
                    try await SocialService.shared.syncKudosFromBackend(
                        for: userId,
                        modelContext: modelContext
                    )
                    try await SocialService.shared.syncCommentsFromBackend(
                        for: userId,
                        modelContext: modelContext
                    )
                    
                    logger.info("✅ Background sync completed on app launch")
                } catch {
                    logger.warning("⚠️ Failed to sync data on launch: \(error.localizedDescription)")
                    // Don't block app launch if sync fails - user can still use app
                }
            }
        }
        
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
        
        logger.info("Pulsar app configured")
    }
}
