//
//  FeedView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftData
import SwiftUI

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @State private var feedItems: [FeedItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let socialService = SocialService.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if feedItems.isEmpty && !isLoading {
                    emptyState
                } else {
                    feedList
                }
            }
            .navigationTitle("Feed")
            .refreshable {
                await loadFeed()
            }
            .task {
                await loadFeed()
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Activities Yet", systemImage: "figure.run.circle")
        } description: {
            Text("Follow other athletes to see their activities here")
        } actions: {
            Button("Find Athletes") {
                // TODO: Navigate to user search
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(feedItems) { item in
                    FeedCard(item: item)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func loadFeed() async {
        guard let userId = appState.currentUserId else { return }
        
        isLoading = true
        
        do {
            feedItems = try socialService.getFeed(userId: userId, modelContext: modelContext)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Feed Card

struct FeedCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let item: FeedItem
    
    @State private var hasKudoed: Bool
    @State private var kudosCount: Int
    @State private var showComments = false
    
    private let socialService = SocialService.shared
    
    init(item: FeedItem) {
        self.item = item
        _hasKudoed = State(initialValue: item.hasUserKudoed)
        _kudosCount = State(initialValue: item.kudosCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(item.profile.username.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                
                // User info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.profile.username)
                        .font(.headline)
                    Text(item.timeAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Activity type icon
                Image(systemName: item.activity.activityType.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            
            // Activity name
            Text(item.activity.name)
                .font(.title3.bold())
            
            // Stats
            HStack(spacing: 20) {
                Label(formatDistance(item.activity.distance), systemImage: "location.fill")
                Label(formatDuration(item.activity.duration), systemImage: "clock.fill")
                if let elevation = item.activity.elevationGain {
                    Label(formatElevation(elevation), systemImage: "arrow.up.right")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            Divider()
            
            // Actions
            HStack(spacing: 24) {
                Button(action: toggleKudo) {
                    Label("\(kudosCount)", systemImage: hasKudoed ? "heart.fill" : "heart")
                        .foregroundStyle(hasKudoed ? .red : .primary)
                }
                .buttonStyle(.plain)
                
                Button(action: { showComments.toggle() }, label: {
                    Label("\(item.commentsCount)", systemImage: "bubble.left")
                })
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {}, label: {
                    Image(systemName: "paperplane")
                })
                .buttonStyle(.plain)
            }
            .font(.subheadline)
            
            // Comments preview
            if showComments {
                CommentSection(activityId: item.activity.id)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private func toggleKudo() {
        guard let userId = appState.currentUserId else { return }
        
        Task {
            do {
                if hasKudoed {
                    try await socialService.removeKudo(
                        userId: userId,
                        activityId: item.activity.id,
                        modelContext: modelContext
                    )
                    await MainActor.run {
                        hasKudoed = false
                        kudosCount = max(0, kudosCount - 1)
                    }
                } else {
                    try await socialService.giveKudo(
                        userId: userId,
                        activityId: item.activity.id,
                        modelContext: modelContext
                    )
                    await MainActor.run {
                        hasKudoed = true
                        kudosCount += 1
                    }
                }
            } catch {
                print("Error toggling kudo: \(error)")
            }
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        return String(format: "%.2f km", km)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatElevation(_ meters: Double) -> String {
        String(format: "%.0f m", meters)
    }
}

// MARK: - Comment Section

struct CommentSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let activityId: String
    
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    
    private let socialService = SocialService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            // Existing comments
            ForEach(comments) { comment in
                CommentRow(comment: comment)
            }
            
            // New comment field
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("Comment Field")
                
                Button("Post") {
                    postComment()
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("Post Comment")
            }
        }
        .task {
            loadComments()
        }
    }
    
    private func loadComments() {
        do {
            comments = try socialService.getComments(activityId: activityId, modelContext: modelContext)
        } catch {
            print("Error loading comments: \(error)")
        }
    }
    
    private func postComment() {
        guard let userId = appState.currentUserId else { return }
        
        Task {
            do {
                try await socialService.addComment(
                    userId: userId,
                    activityId: activityId,
                    text: newCommentText,
                    modelContext: modelContext
                )
                
                await MainActor.run {
                    newCommentText = ""
                    loadComments()
                }
            } catch {
                print("Error posting comment: \(error)")
            }
        }
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            Circle()
                .fill(Color.gray.gradient)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@user\(comment.userId.prefix(8))")
                        .font(.caption.bold())
                    Text(comment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(comment.text)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
}

#Preview {
    FeedView()
        .modelContainer(for: Activity.self, inMemory: true)
        .environment(AppState())
}
