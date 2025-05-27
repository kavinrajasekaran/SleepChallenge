import SwiftUI
import SwiftData

struct CreateChallengeView: View {
    @EnvironmentObject var dataManager: SimpleDataManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var challengeName = ""
    @State private var selectedType: ChallengeType = .duration
    @State private var selectedDuration = 7 // days
    @State private var selectedFriends: Set<UUID> = []
    @State private var isCreating = false
    
    private var friends: [User] {
        dataManager.currentUser?.friends ?? []
    }
    
    private let durationOptions = [1, 3, 7, 14, 30]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    headerSection
                    
                    // Challenge Details
                    challengeDetailsSection
                    
                    // Challenge Type
                    challengeTypeSection
                    
                    // Duration
                    durationSection
                    
                    // Friends Selection
                    friendsSelectionSection
                    
                    // Create Button
                    createButtonSection
                }
                .padding()
            }
            .navigationTitle("New Challenge")
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
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Create Sleep Challenge")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Challenge your friends to see who gets the best sleep")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var challengeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Challenge Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Challenge Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter challenge name", text: $challengeName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
            }
        }
    }
    
    private var challengeTypeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Challenge Type")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ChallengeType.allCases, id: \.self) { type in
                    ChallengeTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Duration")
                .font(.headline)
            
            Picker("Duration", selection: $selectedDuration) {
                ForEach(durationOptions, id: \.self) { days in
                    Text("\(days) \(days == 1 ? "day" : "days")")
                        .tag(days)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var friendsSelectionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Select Friends")
                    .font(.headline)
                
                Spacer()
                
                Text("\(selectedFriends.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if friends.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.2")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No friends added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Add friends to challenge them")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(friends, id: \.id) { friend in
                        FriendSelectionRow(
                            friend: friend,
                            isSelected: selectedFriends.contains(friend.id)
                        ) {
                            if selectedFriends.contains(friend.id) {
                                selectedFriends.remove(friend.id)
                            } else {
                                selectedFriends.insert(friend.id)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var createButtonSection: some View {
        VStack(spacing: 15) {
            if !selectedFriends.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenge Summary")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("• \(selectedFriends.count + 1) participants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• \(selectedDuration) day\(selectedDuration == 1 ? "" : "s") duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• \(selectedType.rawValue) competition")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Button(action: createChallenge) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trophy.fill")
                    }
                    
                    Text(isCreating ? "Creating..." : "Create Challenge")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCreateChallenge ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canCreateChallenge || isCreating)
        }
    }
    
    private var canCreateChallenge: Bool {
        !challengeName.isEmpty && !selectedFriends.isEmpty
    }
    
    private func createChallenge() {
        isCreating = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dataManager.createChallenge(
                name: challengeName,
                type: selectedType,
                friendIds: Array(selectedFriends),
                duration: selectedDuration
            )
            
            isCreating = false
            dismiss()
        }
    }
}

struct ChallengeTypeCard: View {
    let type: ChallengeType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                Text(type.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct FriendSelectionRow: View {
    let friend: User
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                // Profile image
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(friend.name.prefix(1).uppercased())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )
                
                // Friend info
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(friend.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(friend.totalChallengesWon)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("wins")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateChallengeView()
        .environmentObject(SimpleDataManager())
        .modelContainer(for: [User.self, Challenge.self], inMemory: true)
} 