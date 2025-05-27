import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject var dataManager: SimpleDataManager
    @Environment(\.modelContext) private var modelContext
    @Query private var sleepRecords: [SleepRecord]
    @State private var showingEditProfile = false
    
    private var userSleepRecords: [SleepRecord] {
        sleepRecords
            .filter { $0.userId == dataManager.currentUser?.id }
            .sorted { $0.date > $1.date }
    }
    
    private var averageSleepDuration: TimeInterval {
        guard !userSleepRecords.isEmpty else { return 0 }
        return userSleepRecords.map { $0.totalSleepDuration }.reduce(0, +) / Double(userSleepRecords.count)
    }
    
    private var averageSleepScore: Double {
        guard !userSleepRecords.isEmpty else { return 0 }
        return userSleepRecords.map { $0.sleepScore }.reduce(0, +) / Double(userSleepRecords.count)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Cards
                    statsSection
                    
                    // Sleep Insights
                    sleepInsightsSection
                    
                    // Settings
                    settingsSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 15) {
            // Profile Image
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(dataManager.currentUser?.name.prefix(1).uppercased() ?? "U")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.blue)
                )
            
            // User Info
            VStack(spacing: 5) {
                Text(dataManager.currentUser?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(dataManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Member since \(dataManager.currentUser?.dateJoined.formatted(date: .abbreviated, time: .omitted) ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Stats")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                StatCard(
                    title: "Total Challenges",
                    value: "\(dataManager.currentUser?.totalChallengesParticipated ?? 0)",
                    icon: "trophy",
                    color: .blue
                )
                
                StatCard(
                    title: "Challenges Won",
                    value: "\(dataManager.currentUser?.totalChallengesWon ?? 0)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Win Rate",
                    value: "\(Int((dataManager.currentUser?.winRate ?? 0) * 100))%",
                    icon: "percent",
                    color: .green
                )
                
                StatCard(
                    title: "Sleep Records",
                    value: "\(userSleepRecords.count)",
                    icon: "moon.zzz",
                    color: .purple
                )
            }
        }
    }
    
    private var sleepInsightsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sleep Insights")
                .font(.headline)
            
            VStack(spacing: 12) {
                InsightRow(
                    title: "Average Sleep Duration",
                    value: formatDuration(averageSleepDuration),
                    icon: "clock",
                    color: .blue
                )
                
                InsightRow(
                    title: "Average Sleep Score",
                    value: "\(Int(averageSleepScore))",
                    icon: "star.fill",
                    color: scoreColor(averageSleepScore)
                )
                
                InsightRow(
                    title: "Best Sleep Score",
                    value: "\(Int(userSleepRecords.map { $0.sleepScore }.max() ?? 0))",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                InsightRow(
                    title: "Total Friends",
                    value: "\(dataManager.currentUser?.friends.count ?? 0)",
                    icon: "person.2.fill",
                    color: .green
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings")
                .font(.headline)
            
            VStack(spacing: 0) {
                SettingRow(
                    title: "HealthKit Access",
                    subtitle: dataManager.healthKitStatus,
                    icon: "heart.fill",
                    color: dataManager.isHealthKitAuthorized ? .green : (dataManager.healthKitStatus == "Simulator Mode" ? .blue : .red)
                ) {
                    if !dataManager.isHealthKitAuthorized && dataManager.healthKitStatus != "Simulator Mode" {
                        Task {
                            await dataManager.requestHealthKitAuthorization()
                        }
                    }
                }
                
                Divider()
                
                SettingRow(
                    title: "Sync Sleep Data",
                    subtitle: "Update from Apple Health",
                    icon: "arrow.clockwise",
                    color: .blue
                ) {
                    Task {
                        await dataManager.syncSleepData()
                    }
                }
                
                Divider()
                
                SettingRow(
                    title: "Privacy Policy",
                    subtitle: "Learn about data usage",
                    icon: "lock.shield",
                    color: .gray
                ) {
                    // Open privacy policy
                }
                
                Divider()
                
                SettingRow(
                    title: "About",
                    subtitle: "App version and info",
                    icon: "info.circle",
                    color: .gray
                ) {
                    // Show about screen
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)h \(minutes)m"
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct SettingRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

struct EditProfileView: View {
    @EnvironmentObject var dataManager: SimpleDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Image
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(name.prefix(1).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                    )
                
                // Form
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Name")
                            .font(.headline)
                        TextField("Your name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.headline)
                        TextField("Your email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
        .onAppear {
            name = dataManager.currentUser?.name ?? ""
            email = dataManager.currentUser?.email ?? ""
        }
    }
    
    private func saveProfile() {
        // Update user profile
        dataManager.currentUser?.name = name
        dataManager.currentUser?.email = email
        dismiss()
    }
}

#Preview {
    ProfileView()
        .environmentObject(SimpleDataManager())
        .modelContainer(for: [User.self, SleepRecord.self], inMemory: true)
} 