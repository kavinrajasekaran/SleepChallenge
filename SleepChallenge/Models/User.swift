import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var name: String
    var email: String
    var profileImageData: Data?
    var dateJoined: Date
    var totalChallengesWon: Int
    var totalChallengesParticipated: Int
    var friends: [User]
    var sleepRecords: [SleepRecord]
    
    init(name: String, email: String, profileImageData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.profileImageData = profileImageData
        self.dateJoined = Date()
        self.totalChallengesWon = 0
        self.totalChallengesParticipated = 0
        self.friends = []
        self.sleepRecords = []
    }
    
    var winRate: Double {
        guard totalChallengesParticipated > 0 else { return 0.0 }
        return Double(totalChallengesWon) / Double(totalChallengesParticipated)
    }
} 