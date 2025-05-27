import SwiftUI
import SwiftData

struct ChallengeCard: View {
    let challenge: Challenge
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: challenge.type.icon)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(challenge.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(challenge.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .clipShape(Capsule())
                    
                    Text("\(challenge.durationInDays) days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress
            if challenge.isActive {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(timeRemaining)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: progressValue)
                        .tint(.blue)
                }
            }
            
            // Participants and Scores
            if !challenge.scores.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Leaderboard")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVStack(spacing: 4) {
                        ForEach(sortedParticipants, id: \.0) { participantId, score in
                            ParticipantRow(
                                participantId: participantId,
                                score: score,
                                isCurrentUser: participantId == dataManager.currentUser?.id,
                                challengeType: challenge.type
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var statusColor: Color {
        switch challenge.status {
        case .pending:
            return .orange
        case .active:
            return .green
        case .completed:
            return .blue
        case .cancelled:
            return .red
        }
    }
    
    private var progressValue: Double {
        let totalDuration = challenge.endDate.timeIntervalSince(challenge.startDate)
        let elapsed = Date().timeIntervalSince(challenge.startDate)
        return min(max(elapsed / totalDuration, 0), 1)
    }
    
    private var timeRemaining: String {
        let remaining = challenge.endDate.timeIntervalSince(Date())
        if remaining <= 0 {
            return "Ended"
        }
        
        let days = Int(remaining) / (24 * 3600)
        let hours = Int(remaining) % (24 * 3600) / 3600
        
        if days > 0 {
            return "\(days)d \(hours)h left"
        } else {
            return "\(hours)h left"
        }
    }
    
    private var sortedParticipants: [(UUID, Double)] {
        challenge.scores.sorted { $0.value > $1.value }
    }
}

struct ParticipantRow: View {
    let participantId: UUID
    let score: Double
    let isCurrentUser: Bool
    let challengeType: ChallengeType
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            // Rank indicator
            Circle()
                .fill(isCurrentUser ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // Participant name
            Text(participantName)
                .font(.caption)
                .fontWeight(isCurrentUser ? .medium : .regular)
                .foregroundColor(isCurrentUser ? .primary : .secondary)
            
            Spacer()
            
            // Score
            Text(formattedScore)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isCurrentUser ? .blue : .secondary)
        }
    }
    
    private var participantName: String {
        if isCurrentUser {
            return "You"
        }
        
        // Fetch user name from database
        let predicate = #Predicate<User> { user in
            user.id == participantId
        }
        
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first?.name ?? "Unknown"
        } catch {
            return "Unknown"
        }
    }
    
    private var formattedScore: String {
        switch challengeType {
        case .duration:
            return String(format: "%.1fh", score)
        case .quality, .consistency, .overall:
            return String(format: "%.0f", score)
        }
    }
}

#Preview {
    let challenge = Challenge(
        name: "Weekly Sleep Challenge",
        type: .duration,
        creatorId: UUID(),
        participantIds: [UUID(), UUID()],
        startDate: Date().addingTimeInterval(-2 * 24 * 3600),
        endDate: Date().addingTimeInterval(5 * 24 * 3600)
    )
    challenge.status = .active
    challenge.updateScore(for: UUID(), score: 7.5)
    challenge.updateScore(for: UUID(), score: 8.2)
    
    return ChallengeCard(challenge: challenge)
        .environmentObject(DataManager())
        .modelContainer(for: [User.self, Challenge.self], inMemory: true)
        .padding()
} 