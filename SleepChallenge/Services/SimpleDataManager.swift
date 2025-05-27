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
    @Published var healthKitStatus: String = "Simulator Mode"
    
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
            
            // Generate some initial mock sleep data for the past week
            Task {
                await generateInitialMockData()
            }
        } catch {
            errorMessage = "Failed to create user: \(error.localizedDescription)"
        }
    }
    
    private func generateInitialMockData() async {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        print("🎯 Generating initial mock sleep data...")
        
        // Generate sleep records for the past 7 days
        for i in 1...7 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            let sleepRecord = SleepRecord(
                userId: user.id,
                date: date,
                bedTime: Calendar.current.date(byAdding: .hour, value: -8, to: date) ?? date,
                wakeTime: date,
                totalSleepDuration: Double.random(in: 6.5...8.5) * 3600 // 6.5-8.5 hours
            )
            
            // Realistic sleep stage distribution
            let totalSleep = sleepRecord.totalSleepDuration
            sleepRecord.deepSleepDuration = totalSleep * Double.random(in: 0.15...0.25) // 15-25% deep sleep
            sleepRecord.remSleepDuration = totalSleep * Double.random(in: 0.20...0.30) // 20-30% REM sleep
            sleepRecord.lightSleepDuration = totalSleep - sleepRecord.deepSleepDuration - sleepRecord.remSleepDuration
            sleepRecord.awakeTime = Double.random(in: 0.1...0.5) * 3600 // 6-30 minutes awake
            sleepRecord.sleepQuality = Double.random(in: 0.65...0.95)
            
            context.insert(sleepRecord)
        }
        
        // Add some sample friends
        let friendData = [
            ("Alex Johnson", "alex@example.com"),
            ("Jordan Smith", "jordan@example.com"),
            ("Casey Brown", "casey@example.com")
        ]
        
        for (name, email) in friendData {
            let friend = User(name: name, email: email)
            friend.totalChallengesWon = Int.random(in: 2...8)
            friend.totalChallengesParticipated = friend.totalChallengesWon + Int.random(in: 1...4)
            
            context.insert(friend)
            user.friends.append(friend)
        }
        
        do {
            try context.save()
            print("✅ Initial mock data generated successfully")
        } catch {
            print("❌ Failed to generate mock data: \(error.localizedDescription)")
        }
    }
    
    func requestHealthKitAuthorization() async {
        // Only request HealthKit authorization if properly configured
        // This prevents crashes when Info.plist entries are missing
        do {
            await healthKitManager.requestAuthorization()
            if healthKitManager.isAuthorized {
                healthKitStatus = "Connected"
            } else {
                healthKitStatus = "Not Available"
            }
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
            healthKitStatus = "Simulator Mode"
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
            // Create mock sleep data (always works)
            let sleepRecord = SleepRecord(
                userId: user.id,
                date: date,
                bedTime: Calendar.current.date(byAdding: .hour, value: -8, to: date) ?? date,
                wakeTime: date,
                totalSleepDuration: 7.5 * 3600 // 7.5 hours
            )
            
            // Set realistic mock values
            sleepRecord.sleepQuality = Double.random(in: 0.7...0.95)
            sleepRecord.deepSleepDuration = 1.5 * 3600
            sleepRecord.remSleepDuration = 1.8 * 3600
            sleepRecord.lightSleepDuration = 4.2 * 3600
            sleepRecord.awakeTime = 0.3 * 3600
            
            // Check if we already have data for this date to avoid regenerating
            let allRecords = try context.fetch(FetchDescriptor<SleepRecord>())
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let existingRecord = allRecords.first { record in
                record.userId == user.id && 
                record.date >= startOfDay && 
                record.date < endOfDay
            }
            
            // If we already have data for today, don't regenerate it
            if existingRecord != nil {
                print("ℹ️ Sleep data already exists for today")
                isLoading = false
                return
            }
            
            // Try to get real HealthKit data (only if properly configured)
            if isHealthKitAuthorized {
                do {
                    if let healthData = try await healthKitManager.fetchSleepData(for: date) {
                        sleepRecord.totalSleepDuration = healthData.totalSleepDuration
                        sleepRecord.sleepQuality = healthData.sleepQuality
                        sleepRecord.deepSleepDuration = healthData.deepSleepDuration
                        sleepRecord.remSleepDuration = healthData.remSleepDuration
                        sleepRecord.lightSleepDuration = healthData.lightSleepDuration
                        sleepRecord.awakeTime = healthData.awakeTime
                        sleepRecord.bedTime = healthData.bedTime
                        sleepRecord.wakeTime = healthData.wakeTime
                        print("✅ Successfully synced real HealthKit data")
                    }
                } catch {
                    print("ℹ️ HealthKit sync failed, using mock data")
                    // Continue with mock data - this is normal in simulator
                }
            } else {
                print("ℹ️ Using mock sleep data (HealthKit not available)")
            }
            
            // Since we checked for existing records above, we can directly insert
            
            context.insert(sleepRecord)
            try context.save()
            
            print("✅ Sleep data synced successfully")
            
        } catch {
            // Only show user-facing errors for serious issues (not HealthKit unavailability)
            if error.localizedDescription.contains("healthkit") || error.localizedDescription.contains("entitlement") {
                print("ℹ️ HealthKit not available, using mock data")
                // Don't set errorMessage for HealthKit issues - they're expected
            } else {
                errorMessage = "Failed to sync sleep data: \(error.localizedDescription)"
            }
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