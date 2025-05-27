import Foundation
import SwiftData
import HealthKit

@Model
final class SleepRecord {
    var id: UUID
    var userId: UUID
    var date: Date
    var bedTime: Date
    var wakeTime: Date
    var totalSleepDuration: TimeInterval // in seconds
    var sleepQuality: Double // 0.0 to 1.0 scale
    var deepSleepDuration: TimeInterval
    var remSleepDuration: TimeInterval
    var lightSleepDuration: TimeInterval
    var awakeTime: TimeInterval
    var heartRateVariability: Double?
    var restingHeartRate: Double?
    
    init(userId: UUID, date: Date, bedTime: Date, wakeTime: Date, totalSleepDuration: TimeInterval) {
        self.id = UUID()
        self.userId = userId
        self.date = date
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.totalSleepDuration = totalSleepDuration
        self.sleepQuality = 0.0
        self.deepSleepDuration = 0.0
        self.remSleepDuration = 0.0
        self.lightSleepDuration = 0.0
        self.awakeTime = 0.0
        self.heartRateVariability = nil
        self.restingHeartRate = nil
    }
    
    var sleepScore: Double {
        // Calculate a sleep score based on duration, quality, and sleep stages
        let durationScore = min(totalSleepDuration / (8 * 3600), 1.0) // 8 hours = perfect
        let qualityScore = sleepQuality
        let stageScore = (deepSleepDuration + remSleepDuration) / totalSleepDuration
        
        return (durationScore * 0.4 + qualityScore * 0.4 + stageScore * 0.2) * 100
    }
    
    var formattedDuration: String {
        let hours = Int(totalSleepDuration) / 3600
        let minutes = Int(totalSleepDuration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
} 