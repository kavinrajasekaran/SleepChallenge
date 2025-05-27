import Foundation
import SwiftData
import HealthKit

@MainActor
class SimpleDataManager: ObservableObject {
    private let healthKitManager = HealthKitManager()
    private var modelContext: ModelContext?
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
        // Only request HealthKit authorization if properly configured
        // This prevents crashes when Info.plist entries are missing
        do {
            await healthKitManager.requestAuthorization()
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
            // Continue without HealthKit - app will use mock data
        }
    }
    
    var isHealthKitAuthorized: Bool {
        healthKitManager.isAuthorized
    }
    
    func syncSleepData(for date: Date = Date()) async {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // For demo purposes, create mock sleep data if HealthKit fails
            let sleepRecord = SleepRecord(
                userId: user.id,
                date: date,
                bedTime: Calendar.current.date(byAdding: .hour, value: -8, to: date) ?? date,
                wakeTime: date,
                totalSleepDuration: 7.5 * 3600 // 7.5 hours
            )
            
            // Set some mock values
            sleepRecord.sleepQuality = Double.random(in: 0.7...0.95)
            sleepRecord.deepSleepDuration = 1.5 * 3600
            sleepRecord.remSleepDuration = 1.8 * 3600
            sleepRecord.lightSleepDuration = 4.2 * 3600
            sleepRecord.awakeTime = 0.3 * 3600
            
            // Try to get real HealthKit data
            if let healthData = try await healthKitManager.fetchSleepData(for: date) {
                sleepRecord.totalSleepDuration = healthData.totalSleepDuration
                sleepRecord.sleepQuality = healthData.sleepQuality
                sleepRecord.deepSleepDuration = healthData.deepSleepDuration
                sleepRecord.remSleepDuration = healthData.remSleepDuration
                sleepRecord.lightSleepDuration = healthData.lightSleepDuration
                sleepRecord.awakeTime = healthData.awakeTime
                sleepRecord.bedTime = healthData.bedTime
                sleepRecord.wakeTime = healthData.wakeTime
            }
            
            // Remove existing records for this date (simple approach)
            let allRecords = try context.fetch(FetchDescriptor<SleepRecord>())
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            for record in allRecords {
                if record.userId == user.id && 
                   record.date >= startOfDay && 
                   record.date < endOfDay {
                    context.delete(record)
                }
            }
            
            context.insert(sleepRecord)
            try context.save()
            
        } catch {
            errorMessage = "Failed to sync sleep data: \(error.localizedDescription)"
        }
        
        isLoading = false
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
        
        // Set initial status to active for demo
        challenge.status = .active
        
        context.insert(challenge)
        
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to create challenge: \(error.localizedDescription)"
        }
    }
    
    func addFriend(email: String) {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        let friendNames = ["Alex", "Jordan", "Casey", "Taylor", "Morgan", "Riley", "Avery", "Quinn"]
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
} 