//
//  DesignSystem.swift
//  Pulsar
//
//  Modern 2026 iOS Design System
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Color Palette

extension Color {
    // MARK: - Brand Colors
    // Note: pulsarPrimary and pulsarSecondary are auto-generated from asset catalog
    // in Xcode 26+. We provide fallbacks for older Xcode versions.
    
    #if swift(<6.0)
    /// Primary brand color - vibrant orange/coral
    static let pulsarPrimary = Color("PulsarPrimary")
    
    /// Secondary brand color - deep purple
    static let pulsarSecondary = Color("PulsarSecondary")
    #endif
    
    /// Accent gradient start
    static let gradientStart = Color(hex: "FF6B35")
    
    /// Accent gradient end
    static let gradientEnd = Color(hex: "F7931E")
    
    // MARK: - Semantic Colors
    
    /// Success state - completed activities, PRs
    static let pulsarSuccess = Color(hex: "34C759")
    
    /// Warning state
    static let pulsarWarning = Color(hex: "FF9500")
    
    /// Error state
    static let pulsarError = Color(hex: "FF3B30")
    
    // MARK: - Activity Type Colors
    
    static let activityRun = Color(hex: "FF6B35")
    static let activityRide = Color(hex: "5856D6")
    static let activitySwim = Color(hex: "00C7BE")
    static let activityHike = Color(hex: "8B5CF6")
    static let activityWalk = Color(hex: "64D2FF")
    
    // MARK: - Background Colors
    
    #if os(iOS)
    static let cardBackground = Color(.systemBackground)
    static let elevatedBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    #else
    static let cardBackground = Color(nsColor: .windowBackgroundColor)
    static let elevatedBackground = Color(nsColor: .controlBackgroundColor)
    static let tertiaryBackground = Color(nsColor: .underPageBackgroundColor)
    #endif
    
    // MARK: - Text Colors
    
    #if os(iOS)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    #else
    static let textPrimary = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    #endif
    
    // MARK: - Hex Initializer
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

extension Font {
    // MARK: - Display Fonts
    
    /// Large display - Hero stats
    static let displayLarge = Font.system(size: 56, weight: .bold, design: .rounded)
    
    /// Medium display - Section headers
    static let displayMedium = Font.system(size: 34, weight: .bold, design: .rounded)
    
    /// Small display
    static let displaySmall = Font.system(size: 28, weight: .semibold, design: .rounded)
    
    // MARK: - Headline Fonts
    
    static let headlineLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let headlineMedium = Font.system(size: 17, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 15, weight: .semibold, design: .default)
    
    // MARK: - Body Fonts
    
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: - Label Fonts
    
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    
    // MARK: - Stats Fonts (Tabular for alignment)
    
    static let statLarge = Font.system(size: 32, weight: .bold, design: .rounded).monospacedDigit()
    static let statMedium = Font.system(size: 24, weight: .semibold, design: .rounded).monospacedDigit()
    static let statSmall = Font.system(size: 17, weight: .medium, design: .rounded).monospacedDigit()
}

// MARK: - Spacing

enum Spacing {
    /// 4pt
    static let xxs: CGFloat = 4
    /// 8pt
    static let xs: CGFloat = 8
    /// 12pt
    static let sm: CGFloat = 12
    /// 16pt
    static let md: CGFloat = 16
    /// 20pt
    static let lg: CGFloat = 20
    /// 24pt
    static let xl: CGFloat = 24
    /// 32pt
    static let xxl: CGFloat = 32
    /// 48pt
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    /// 8pt - Small elements
    static let small: CGFloat = 8
    /// 12pt - Cards, buttons
    static let medium: CGFloat = 12
    /// 16pt - Sheets, modals
    static let large: CGFloat = 16
    /// 24pt - Large containers
    static let xlarge: CGFloat = 24
    /// Full pill shape
    static let pill: CGFloat = 100
}

// MARK: - Shadows

extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    func elevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }
    
    func subtleShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let pulsarGradient = LinearGradient(
        colors: [Color.gradientStart, Color.gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let overlayGradient = LinearGradient(
        colors: [Color.clear, Color.black.opacity(0.6)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Animation Curves

extension Animation {
    static let pulsarSpring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let pulsarEaseOut = Animation.easeOut(duration: 0.25)
    static let pulsarBounce = Animation.interpolatingSpring(stiffness: 300, damping: 15)
}

// MARK: - Haptics

#if os(iOS)
enum HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
#else
// No-op haptics for macOS
enum HapticFeedback {
    static func impact(_ style: Any? = nil) {}
    static func notification(_ type: Any) {}
    static func selection() {}
}
#endif

// MARK: - Activity Type Helpers

enum ActivityType: String, CaseIterable, Codable, Sendable {
    case run = "run"
    case ride = "ride"
    case swim = "swim"
    case hike = "hike"
    case walk = "walk"
    case workout = "workout"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .run: return "Run"
        case .ride: return "Ride"
        case .swim: return "Swim"
        case .hike: return "Hike"
        case .walk: return "Walk"
        case .workout: return "Workout"
        case .other: return "Activity"
        }
    }
    
    var icon: String {
        switch self {
        case .run: return "figure.run"
        case .ride: return "figure.outdoor.cycle"
        case .swim: return "figure.pool.swim"
        case .hike: return "figure.hiking"
        case .walk: return "figure.walk"
        case .workout: return "dumbbell.fill"
        case .other: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .run: return .activityRun
        case .ride: return .activityRide
        case .swim: return .activitySwim
        case .hike: return .activityHike
        case .walk: return .activityWalk
        case .workout: return .pulsarPrimary
        case .other: return .pulsarSecondary
        }
    }
}
