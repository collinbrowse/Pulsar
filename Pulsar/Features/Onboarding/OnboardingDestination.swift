//
//  OnboardingDestination.swift
//  Pulsar
//
//  Navigation destinations after sign-in / sign-up.
//

import SwiftUI

enum OnboardingDestination: Hashable {
    case profileCreation(userId: String, email: String, username: String)
}
