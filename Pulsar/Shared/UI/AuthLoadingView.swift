//
//  AuthLoadingView.swift
//  Pulsar
//
//  Elegant loading screen shown while auth state is determined. User never sees onboarding or main app until we know which to show.
//

import SwiftUI

struct AuthLoadingView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            loadingBackground
            loadingContent
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
    
    private var loadingBackground: some View {
        LinearGradient(
            colors: [
                Color.gradientStart.opacity(0.12),
                Color.gradientEnd.opacity(0.06),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var loadingContent: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()
            logoSection
            Spacer()
            loadingDots
        }
    }
    
    private var logoSection: some View {
        VStack(spacing: Spacing.lg) {
            logoIcon
            Text("Pulsar")
                .font(.displaySmall)
                .foregroundStyle(Color.textPrimary)
        }
    }
    
    private var logoIcon: some View {
        let ringOpacity = 0.4 + 0.2 * (0.5 + 0.5 * cos(phase * CGFloat.pi * 2))
        let ringScale = 1.0 + 0.03 * sin(phase * CGFloat.pi * 2)
        return ZStack {
            Circle()
                .stroke(LinearGradient.pulsarGradient, lineWidth: 2)
                .frame(width: 88, height: 88)
                .opacity(Double(ringOpacity))
                .scaleEffect(ringScale)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.gradientStart.opacity(0.2), Color.gradientEnd.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
            Image(systemName: "waveform.path")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(LinearGradient.pulsarGradient)
        }
    }
    
    private var loadingDots: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(LinearGradient.pulsarGradient)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale(for: index))
                    .opacity(dotOpacity(for: index))
            }
        }
        .padding(.bottom, Spacing.xxxl)
    }
    
    private func dotScale(for index: Int) -> CGFloat {
        let t = phase + CGFloat(index) / 3
        return 0.72 + 0.45 * (0.5 + 0.5 * cos(t * CGFloat.pi * 2))
    }
    
    private func dotOpacity(for index: Int) -> Double {
        let t = phase + CGFloat(index) / 3
        return 0.45 + 0.55 * (0.5 + 0.5 * cos(t * CGFloat.pi * 2))
    }
}

#Preview {
    AuthLoadingView()
}
