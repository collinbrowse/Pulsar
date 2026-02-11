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

/// One-line summary for errors so we never dump NSError userInfo (e.g. Core Data model dumps) to the console.
private func shortErrorSummary(_ error: Error) -> String {
    let ns = error as NSError
    let reason = (ns.userInfo[NSLocalizedFailureReasonErrorKey] as? String) ?? ns.localizedDescription
    if reason.isEmpty { return "\(ns.domain) \(ns.code)" }
    return "\(ns.domain) \(ns.code): \(reason)"
}

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
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        
        let defaultStoreURL: URL? = isUITesting ? nil : {
            guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
            return appSupport.appendingPathComponent("default.store")
        }()
        
        let modelConfiguration = ModelConfiguration(
            nil,
            schema: schema,
            isStoredInMemoryOnly: isUITesting,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .none
        )

        func makeContainer() throws -> ModelContainer {
            try ModelContainer(for: schema, configurations: [modelConfiguration])
        }

        do {
            let container = try makeContainer()
            logger.info("[Pulsar] Storage: \(isUITesting ? "in-memory (UI test)" : "on-disk")")
            return container
        } catch {
            logger.error("[Pulsar] Storage failed: \(shortErrorSummary(error))")

            if let url = defaultStoreURL {
                let fm = FileManager.default
                let base = url.deletingPathExtension()
                for ext in ["store", "store-wal", "store-shm"] {
                    let fileURL = ext == "store" ? url : base.appendingPathExtension(ext)
                    if fm.fileExists(atPath: fileURL.path) { try? fm.removeItem(at: fileURL) }
                }
                do {
                    let container = try makeContainer()
                    logger.info("[Pulsar] Storage: on-disk (recovered after store reset)")
                    return container
                } catch {
                    logger.error("[Pulsar] Storage retry failed: \(shortErrorSummary(error))")
                }
            }

            let fallbackConfig = ModelConfiguration(
                nil,
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true,
                groupContainer: .automatic,
                cloudKitDatabase: .none
            )
            do {
                let fallback = try ModelContainer(for: schema, configurations: [fallbackConfig])
                logger.warning("[Pulsar] Storage: in-memory fallback (data not persisted)")
                return fallback
            } catch {
                logger.fault("[Pulsar] Storage unrecoverable: \(shortErrorSummary(error))")
                preconditionFailure("Could not create any ModelContainer: \(shortErrorSummary(error))")
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
        Task { @MainActor in
            ObservabilityManager.shared.configure()
        }
        configureAppearance()
        if !AppEnvironment.shared.isConfigured {
            logger.warning("[Pulsar] Environment not configured — check API keys")
        }
        logger.info("[Pulsar] Ready")
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
