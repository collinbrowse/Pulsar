//
//  OnboardingView.swift
//  Pulsar
//
//  Welcome and authentication flow
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0
    @State private var showAuth = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Track Your Journey",
            subtitle: "Import activities from any device or service. Your fitness story, beautifully visualized.",
            imageName: "figure.run",
            color: .activityRun
        ),
        OnboardingPage(
            title: "Compete on Segments",
            subtitle: "Discover popular routes and compare your times with athletes worldwide.",
            imageName: "flag.checkered",
            color: .activityRide
        ),
        OnboardingPage(
            title: "Connect & Share",
            subtitle: "Follow friends, give kudos, and celebrate achievements together.",
            imageName: "person.2.fill",
            color: .pulsarPrimary
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.15),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .frame(height: 44)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicators
                HStack(spacing: Spacing.xs) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.pulsarPrimary : Color.textTertiary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1)
                            .animation(.pulsarSpring, value: currentPage)
                    }
                }
                .padding(.bottom, Spacing.xl)
                
                // Action buttons
                VStack(spacing: Spacing.sm) {
                    if currentPage == pages.count - 1 {
                        PrimaryButton("Get Started", icon: "arrow.right") {
                            showAuth = true
                        }
                        
                        Button("I already have an account") {
                            showAuth = true
                        }
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, Spacing.xs)
                    } else {
                        PrimaryButton("Continue") {
                            withAnimation(.pulsarSpring) {
                                currentPage += 1
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .fullScreenCover(isPresented: $showAuth) {
            AuthView()
        }
    }
}

// MARK: - Supporting Types

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.imageName)
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(page.color)
            }
            
            Spacer()
            
            // Text content
            VStack(spacing: Spacing.md) {
                Text(page.title)
                    .font(.displaySmall)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
