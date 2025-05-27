import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @Query private var sleepRecords: [SleepRecord]
    @Query private var challenges: [Challenge]
    @State private var showingSyncSheet = false
    
    private var recentSleepRecords: [SleepRecord] {
        sleepRecords
            .filter { $0.userId == dataManager.currentUser?.id }
            .sorted { $0.date > $1.date }
            .prefix(7)
            .map { $0 }
    }
    
    private var activeChallenges: [Challenge] {
        challenges.filter { challenge in
            challenge.status == .active &&
            challenge.participantIds.contains(dataManager.currentUser?.id ?? UUID())
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Sleep Summary
                    sleepSummarySection
                    
                    // Active Challenges
                    activeChallengesSection
                    
                    // Recent Sleep Data
                    recentSleepSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await syncSleepData()
            }
        }
        .sheet(isPresented: $showingSyncSheet) {
            SyncDataView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Good \(greetingTime), \(dataManager.currentUser?.name ?? "User")!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Ready to track your sleep?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingSyncSheet = true }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 15) {
                QuickActionCard(
                    icon: "moon.zzz.fill",
                    title: "Sync Sleep",
                    subtitle: "Update from Health",
                    color: .blue
                ) {
                    Task {
                        await syncSleepData()
                    }
                }
                
                QuickActionCard(
                    icon: "trophy.fill",
                    title: "New Challenge",
                    subtitle: "Challenge friends",
                    color: .orange
                ) {
                    // Navigate to create challenge
                }
            }
        }
    }
    
    private var sleepSummarySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("This Week's Sleep")
                .font(.headline)
            
            if let lastNightSleep = recentSleepRecords.first {
                SleepSummaryCard(sleepRecord: lastNightSleep)
            } else {
                EmptyStateCard(
                    icon: "moon.zzz",
                    title: "No Sleep Data",
                    subtitle: "Sync your data to see your sleep summary"
                )
            }
        }
    }
    
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Active Challenges")
                    .font(.headline)
                
                Spacer()
                
                if !activeChallenges.isEmpty {
                    Text("\(activeChallenges.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            
            if activeChallenges.isEmpty {
                EmptyStateCard(
                    icon: "trophy",
                    title: "No Active Challenges",
                    subtitle: "Create a challenge to compete with friends"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(activeChallenges, id: \.id) { challenge in
                        ChallengeCard(challenge: challenge)
                    }
                }
            }
        }
    }
    
    private var recentSleepSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Sleep")
                .font(.headline)
            
            if recentSleepRecords.isEmpty {
                EmptyStateCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Sleep Records",
                    subtitle: "Start tracking your sleep to see your progress"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(recentSleepRecords, id: \.id) { record in
                        SleepRecordRow(record: record)
                    }
                }
            }
        }
    }
    
    private var greetingTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        case 17..<22:
            return "evening"
        default:
            return "night"
        }
    }
    
    private func syncSleepData() async {
        await dataManager.syncSleepData()
        await dataManager.updateChallengeScores()
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct SleepSummaryCard: View {
    let sleepRecord: SleepRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Last Night")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(sleepRecord.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text(sleepRecord.formattedDuration)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Sleep Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(sleepRecord.sleepScore))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(sleepRecord.sleepScore))
                    Text("Sleep Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Sleep stages
            HStack(spacing: 15) {
                SleepStageView(
                    title: "Deep",
                    duration: sleepRecord.deepSleepDuration,
                    color: .purple
                )
                
                SleepStageView(
                    title: "REM",
                    duration: sleepRecord.remSleepDuration,
                    color: .blue
                )
                
                SleepStageView(
                    title: "Light",
                    duration: sleepRecord.lightSleepDuration,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...:
            return .green
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
}

struct SleepStageView: View {
    let title: String
    let duration: TimeInterval
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formatDuration(duration))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .environmentObject(DataManager())
        .modelContainer(for: [User.self, SleepRecord.self, Challenge.self], inMemory: true)
} 