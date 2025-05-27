import Foundation
import SwiftData
import HealthKit

@MainActor
class DataManager: ObservableObject {
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
        
        let descriptor = FetchDescriptor<User>()
        do {
            let users = try context.fetch(descriptor)
            if let user = users.first {
                currentUser = user
            }
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
    
    var isHealthKitAuthorized: Bool {
        healthKitManager.isAuthorized
    }
    
    func syncSleepData(for date: Date = Date()) async {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch sleep data from HealthKit
            guard let sleepData = try await healthKitManager.fetchSleepData(for: date) else {
                errorMessage = "No sleep data found for \(date.formatted(date: .abbreviated, time: .omitted))"
                isLoading = false
                return
            }
            
            // Fetch additional health metrics
            let hrv = try await healthKitManager.fetchHeartRateVariability(for: date)
            let rhr = try await healthKitManager.fetchRestingHeartRate(for: date)
            
            // Create or update sleep record
            let sleepRecord = SleepRecord(
                userId: user.id,
                date: date,
                bedTime: sleepData.bedTime,
                wakeTime: sleepData.wakeTime,
                totalSleepDuration: sleepData.totalSleepDuration
            )
            
            sleepRecord.sleepQuality = sleepData.sleepQuality
            sleepRecord.deepSleepDuration = sleepData.deepSleepDuration
            sleepRecord.remSleepDuration = sleepData.remSleepDuration
            sleepRecord.lightSleepDuration = sleepData.lightSleepDuration
            sleepRecord.awakeTime = sleepData.awakeTime
            sleepRecord.heartRateVariability = hrv
            sleepRecord.restingHeartRate = rhr
            
            // Check if record already exists for this date
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = #Predicate<SleepRecord> { record in
                record.userId == user.id && record.date >= startOfDay && record.date < endOfDay
            }
            
            let descriptor = FetchDescriptor<SleepRecord>(predicate: predicate)
            let existingRecords = try context.fetch(descriptor)
            
            // Remove existing records for this date
            for record in existingRecords {
                context.delete(record)
            }
            
            // Insert new record
            context.insert(sleepRecord)
            user.sleepRecords.append(sleepRecord)
            
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
        
        context.insert(challenge)
        
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to create challenge: \(error.localizedDescription)"
        }
    }
    
    func updateChallengeScores() async {
        guard let context = modelContext else { return }
        
        // Fetch active challenges
        let predicate = #Predicate<Challenge> { challenge in
            challenge.status == .active
        }
        
        let descriptor = FetchDescriptor<Challenge>(predicate: predicate)
        
        do {
            let activeChallenges = try context.fetch(descriptor)
            
            for challenge in activeChallenges {
                await updateScoresForChallenge(challenge)
            }
            
            try context.save()
            
        } catch {
            errorMessage = "Failed to update challenge scores: \(error.localizedDescription)"
        }
    }
    
    private func updateScoresForChallenge(_ challenge: Challenge) async {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        
        for participantId in challenge.participantIds {
            // Fetch sleep records for this participant during challenge period
            let predicate = #Predicate<SleepRecord> { record in
                record.userId == participantId &&
                record.date >= challenge.startDate &&
                record.date <= challenge.endDate
            }
            
            let descriptor = FetchDescriptor<SleepRecord>(predicate: predicate)
            
            do {
                let sleepRecords = try context.fetch(descriptor)
                let score = calculateChallengeScore(for: challenge.type, records: sleepRecords)
                challenge.updateScore(for: participantId, score: score)
            } catch {
                print("Failed to fetch sleep records for participant \(participantId): \(error)")
            }
        }
        
        // Check if challenge should be completed
        if Date() > challenge.endDate && challenge.status == .active {
            challenge.status = .completed
            challenge.winnerId = challenge.getWinner()
            
            // Update user statistics
            updateUserStatistics(for: challenge)
        }
    }
    
    private func calculateChallengeScore(for type: ChallengeType, records: [SleepRecord]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        
        switch type {
        case .duration:
            return records.map { $0.totalSleepDuration }.reduce(0, +) / Double(records.count) / 3600 // Average hours
            
        case .quality:
            return records.map { $0.sleepQuality }.reduce(0, +) / Double(records.count) * 100 // Average quality percentage
            
        case .consistency:
            let bedTimes = records.map { Calendar.current.component(.hour, from: $0.bedTime) * 60 + Calendar.current.component(.minute, from: $0.bedTime) }
            let wakeTimes = records.map { Calendar.current.component(.hour, from: $0.wakeTime) * 60 + Calendar.current.component(.minute, from: $0.wakeTime) }
            
            let bedTimeVariance = calculateVariance(bedTimes.map { Double($0) })
            let wakeTimeVariance = calculateVariance(wakeTimes.map { Double($0) })
            
            // Lower variance = higher consistency score
            let maxVariance = 120.0 // 2 hours in minutes
            let consistencyScore = max(0, 100 - ((bedTimeVariance + wakeTimeVariance) / 2) / maxVariance * 100)
            return consistencyScore
            
        case .overall:
            return records.map { $0.sleepScore }.reduce(0, +) / Double(records.count)
        }
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count - 1)
    }
    
    private func updateUserStatistics(for challenge: Challenge) {
        guard let context = modelContext else { return }
        
        // Fetch all participants
        let predicate = #Predicate<User> { user in
            challenge.participantIds.contains(user.id)
        }
        
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        
        do {
            let participants = try context.fetch(descriptor)
            
            for participant in participants {
                participant.totalChallengesParticipated += 1
                
                if participant.id == challenge.winnerId {
                    participant.totalChallengesWon += 1
                }
            }
            
        } catch {
            print("Failed to update user statistics: \(error)")
        }
    }
    
    func addFriend(email: String) {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        // In a real app, this would involve server communication
        // For now, we'll create a mock friend
        let friend = User(name: "Friend", email: email)
        context.insert(friend)
        user.friends.append(friend)
        
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to add friend: \(error.localizedDescription)"
        }
    }
} 