import SwiftUI
import SwiftData

struct ChallengesView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @Query private var challenges: [Challenge]
    @State private var showingCreateChallenge = false
    @State private var selectedFilter: ChallengeFilter = .active
    
    enum ChallengeFilter: String, CaseIterable {
        case active = "Active"
        case pending = "Pending"
        case completed = "Completed"
        case all = "All"
    }
    
    private var filteredChallenges: [Challenge] {
        let userChallenges = challenges.filter { challenge in
            challenge.participantIds.contains(dataManager.currentUser?.id ?? UUID())
        }
        
        switch selectedFilter {
        case .active:
            return userChallenges.filter { $0.status == .active }
        case .pending:
            return userChallenges.filter { $0.status == .pending }
        case .completed:
            return userChallenges.filter { $0.status == .completed }
        case .all:
            return userChallenges
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ChallengeFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Challenges List
                if filteredChallenges.isEmpty {
                    Spacer()
                    
                    EmptyStateView(
                        icon: "trophy",
                        title: "No \(selectedFilter.rawValue) Challenges",
                        subtitle: selectedFilter == .active ? 
                            "Create a new challenge to compete with friends" :
                            "Challenges you've participated in will appear here",
                        actionTitle: selectedFilter == .active ? "Create Challenge" : nil
                    ) {
                        showingCreateChallenge = true
                    }
                    
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredChallenges.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { challenge in
                                NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                                    ChallengeCard(challenge: challenge)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Challenges")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateChallenge = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateChallenge) {
            CreateChallengeView()
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

struct ChallengeDetailView: View {
    let challenge: Challenge
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @Query private var sleepRecords: [SleepRecord]
    
    private var challengeSleepRecords: [SleepRecord] {
        sleepRecords.filter { record in
            challenge.participantIds.contains(record.userId) &&
            record.date >= challenge.startDate &&
            record.date <= challenge.endDate
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Challenge Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: challenge.type.icon)
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(challenge.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(challenge.type.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Label(challenge.status.rawValue, systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundColor(statusColor)
                        
                        Spacer()
                        
                        Text("\(challenge.startDate.formatted(date: .abbreviated, time: .omitted)) - \(challenge.endDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Leaderboard
                if !challenge.scores.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Leaderboard")
                            .font(.headline)
                        
                        LazyVStack(spacing: 10) {
                            ForEach(Array(challenge.scores.sorted(by: { $0.value > $1.value }).enumerated()), id: \.element.key) { index, participant in
                                LeaderboardRow(
                                    rank: index + 1,
                                    participantId: participant.key,
                                    score: participant.value,
                                    challengeType: challenge.type,
                                    isWinner: challenge.winnerId == participant.key
                                )
                            }
                        }
                    }
                }
                
                // Sleep Records Chart (if active or completed)
                if challenge.status == .active || challenge.status == .completed {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Daily Progress")
                            .font(.headline)
                        
                        if challengeSleepRecords.isEmpty {
                            Text("No sleep data available for this challenge period")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            // Simple chart showing daily scores
                            LazyVStack(spacing: 8) {
                                ForEach(challengeSleepRecords.sorted(by: { $0.date > $1.date }), id: \.id) { record in
                                    if record.userId == dataManager.currentUser?.id {
                                        DailyProgressRow(record: record, challengeType: challenge.type)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Challenge Details")
        .navigationBarTitleDisplayMode(.inline)
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
}

struct LeaderboardRow: View {
    let rank: Int
    let participantId: UUID
    let score: Double
    let challengeType: ChallengeType
    let isWinner: Bool
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 30)
            
            // Trophy for winner
            if isWinner {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
            }
            
            // Participant name
            Text(participantName)
                .font(.subheadline)
                .fontWeight(isCurrentUser ? .medium : .regular)
            
            Spacer()
            
            // Score
            Text(formattedScore)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isCurrentUser ? .blue : .primary)
        }
        .padding()
        .background(isCurrentUser ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var isCurrentUser: Bool {
        participantId == dataManager.currentUser?.id
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .brown
        default:
            return .secondary
        }
    }
    
    private var participantName: String {
        if isCurrentUser {
            return "You"
        }
        
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

struct DailyProgressRow: View {
    let record: SleepRecord
    let challengeType: ChallengeType
    
    var body: some View {
        HStack {
            Text(record.date, style: .date)
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(scoreText)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
    
    private var scoreText: String {
        switch challengeType {
        case .duration:
            return record.formattedDuration
        case .quality:
            return String(format: "%.0f%%", record.sleepQuality * 100)
        case .consistency:
            return "Consistent" // Simplified for now
        case .overall:
            return String(format: "%.0f", record.sleepScore)
        }
    }
}

#Preview {
    ChallengesView()
        .environmentObject(DataManager())
        .modelContainer(for: [Challenge.self, User.self, SleepRecord.self], inMemory: true)
} 