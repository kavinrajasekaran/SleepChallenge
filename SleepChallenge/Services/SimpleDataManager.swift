import Foundation
import SwiftData

@MainActor
class SimpleDataManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    private let healthKitManager = HealthKitManager()
    
    // Simple computed property to access HealthKit status
    var healthKitStatus: String {
        return healthKitManager.authorizationStatus
    }
    
    var isHealthKitAuthorized: Bool {
        return healthKitManager.isAuthorized
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadCurrentUser()
    }
    
    private func loadCurrentUser() {
        guard let context = modelContext else { return }
        
        do {
            let users = try context.fetch(FetchDescriptor<User>())
            currentUser = users.first
        } catch {
            errorMessage = "Failed to load user: \(error.localizedDescription)"
        }
    }
    
    func createUser(name: String, email: String) {
        guard let context = modelContext else { return }
        
        let user = User(name: name, email: email)
        context.insert(user)
        
        do {
            try context.save()
            currentUser = user
        } catch {
            errorMessage = "Failed to create user: \(error.localizedDescription)"
        }
    }
    
    func requestHealthKitAuthorization() async {
        await healthKitManager.requestAuthorization()
    }
    
    func syncSleepData(for date: Date = Date()) async {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        isLoading = true
        
        // Check if we already have data for this date
        let allRecords = try? context.fetch(FetchDescriptor<SleepRecord>())
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let existingRecord = allRecords?.first { record in
            record.userId == user.id && 
            record.date >= startOfDay && 
            record.date < endOfDay
        }
        
        if existingRecord != nil {
            print("Sleep data already exists for this date")
            isLoading = false
            return
        }
        
        // Try to get real HealthKit data
        if let healthData = await healthKitManager.fetchSleepData(for: date) {
            let sleepRecord = SleepRecord(
                userId: user.id,
                date: healthData.date,
                bedTime: healthData.bedTime,
                wakeTime: healthData.wakeTime,
                totalSleepDuration: healthData.duration
            )
            
            context.insert(sleepRecord)
            
            do {
                try context.save()
                print("Successfully saved HealthKit sleep data")
            } catch {
                errorMessage = "Failed to save sleep data: \(error.localizedDescription)"
            }
        } else {
            print("No HealthKit data available for this date")
        }
        
        isLoading = false
    }
    
    func generateInitialData() {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        // Generate sample data for the past 7 days
        let calendar = Calendar.current
        
        for i in 1...7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let startOfDay = calendar.startOfDay(for: date)
            
            let sleepRecord = SleepRecord(
                userId: user.id,
                date: startOfDay,
                bedTime: calendar.date(byAdding: .hour, value: -8, to: startOfDay) ?? startOfDay,
                wakeTime: startOfDay,
                totalSleepDuration: Double.random(in: 6...9) * 3600
            )
            
            context.insert(sleepRecord)
        }
        
        // Add sample friends
        let friendNames = ["Alex Thompson", "Sarah Wilson", "Mike Chen", "Emma Davis"]
        for name in friendNames {
            let friend = User(name: name, email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@example.com")
            friend.totalChallengesWon = Int.random(in: 0...10)
            friend.totalChallengesParticipated = friend.totalChallengesWon + Int.random(in: 0...5)
            
            context.insert(friend)
            user.friends.append(friend)
        }
        
        do {
            try context.save()
            print("Initial sample data generated")
        } catch {
            errorMessage = "Failed to generate initial data: \(error.localizedDescription)"
        }
    }
    
    func addFriend(email: String) {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        let friendNames = ["Alex", "Jordan", "Casey", "Taylor", "Morgan"]
        let randomName = friendNames.randomElement() ?? "Friend"
        
        let friend = User(name: randomName, email: email)
        friend.totalChallengesWon = Int.random(in: 0...10)
        friend.totalChallengesParticipated = friend.totalChallengesWon + Int.random(in: 0...5)
        
        context.insert(friend)
        user.friends.append(friend)
        
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to add friend: \(error.localizedDescription)"
        }
    }
    
    func createChallenge(name: String, type: ChallengeType, friendIds: [UUID], duration: Int) {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: duration, to: startDate)!
        
        var participantIds = friendIds
        participantIds.append(user.id)
        
        let challenge = Challenge(
            name: name,
            type: type,
            creatorId: user.id,
            participantIds: participantIds,
            startDate: startDate,
            endDate: endDate
        )
        
        challenge.status = .active
        context.insert(challenge)
        
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to create challenge: \(error.localizedDescription)"
        }
    }
} 