import SwiftUI
import SwiftData

struct FriendsView: View {
    @EnvironmentObject var dataManager: SimpleDataManager
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddFriend = false
    
    private var friends: [User] {
        dataManager.currentUser?.friends ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if friends.isEmpty {
                    Spacer()
                    
                    EmptyStateView(
                        icon: "person.2",
                        title: "No Friends Yet",
                        subtitle: "Add friends to start competing in sleep challenges together",
                        actionTitle: "Add Friend"
                    ) {
                        showingAddFriend = true
                    }
                    
                    Spacer()
                } else {
                    List {
                        ForEach(friends, id: \.id) { friend in
                            FriendRow(friend: friend)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFriend = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView()
        }
    }
}

struct FriendRow: View {
    let friend: User
    @Environment(\.modelContext) private var modelContext
    @Query private var sleepRecords: [SleepRecord]
    
    private var friendSleepRecords: [SleepRecord] {
        sleepRecords
            .filter { $0.userId == friend.id }
            .sorted { $0.date > $1.date }
    }
    
    private var lastSleepRecord: SleepRecord? {
        friendSleepRecords.first
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile Image Placeholder
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.name.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                
                Text(friend.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastSleep = lastSleepRecord {
                    HStack {
                        Text("Last sleep: \(lastSleep.formattedDuration)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(sleepScoreColor(lastSleep.sleepScore))
                            .frame(width: 8, height: 8)
                    }
                } else {
                    Text("No sleep data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(friend.totalChallengesWon)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Wins")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if friend.totalChallengesParticipated > 0 {
                    Text("\(Int(friend.winRate * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func sleepScoreColor(_ score: Double) -> Color {
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

struct AddFriendView: View {
    @EnvironmentObject var dataManager: SimpleDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isAdding = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Add Friend")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your friend's email address to add them to your friends list")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Email Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Friend's Email")
                        .font(.headline)
                    
                    TextField("Enter email address", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                Spacer()
                
                // Add Button
                Button(action: addFriend) {
                    HStack {
                        if isAdding {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.plus")
                        }
                        
                        Text(isAdding ? "Adding..." : "Add Friend")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(email.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(email.isEmpty || isAdding)
            }
            .padding()
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addFriend() {
        isAdding = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dataManager.addFriend(email: email)
            isAdding = false
            dismiss()
        }
    }
}

#Preview {
    FriendsView()
        .environmentObject(SimpleDataManager())
        .modelContainer(for: [User.self, SleepRecord.self], inMemory: true)
} 