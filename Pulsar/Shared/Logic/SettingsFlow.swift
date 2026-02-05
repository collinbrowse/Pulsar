//
//  SettingsFlow.swift
//  Pulsar
//
//  Small helpers for settings-related behavior, mainly sign-out
//  and account deletion, so they can be tested with AppState.
//

import Foundation

@MainActor
enum SettingsFlow {
    static func signOut(appState: AppState) {
        appState.signOut()
    }
    
    static func deleteAccount(appState: AppState) {
        // When a backend deletion endpoint exists, call it here.
        // For now, mirror current behavior by signing out locally.
        appState.signOut()
    }
}
