import Foundation
import SwiftData

enum ChallengeType: String, CaseIterable, Codable {
    case duration = "Sleep Duration"
    case quality = "Sleep Quality"
    case consistency = "Sleep Consistency"
    case overall = "Overall Sleep Score"
    
    var description: String {
        switch self {
        case .duration:
            return "Who can sleep the longest?"
        case .quality:
            return "Who has the best sleep quality?"
        case .consistency:
            return "Who maintains the most consistent sleep schedule?"
        case .overall:
            return "Who has the best overall sleep score?"
        }
    }
    
    var icon: String {
        switch self {
        case .duration:
            return "clock.fill"
        case .quality:
            return "star.fill"
        case .consistency:
            return "calendar"
        case .overall:
            return "trophy.fill"
        }
    }
}

enum ChallengeStatus: String, Codable {
    case pending = "Pending"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

@Model
final class Challenge {
    var id: UUID
    var name: String
    var type: ChallengeType
    var status: ChallengeStatus
    var creatorId: UUID
    var participantIds: [UUID]
    var startDate: Date
    var endDate: Date
    var winnerId: UUID?
    var scores: [UUID: Double] // userId: score
    var createdAt: Date
    
    init(name: String, type: ChallengeType, creatorId: UUID, participantIds: [UUID], startDate: Date, endDate: Date) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.status = .pending
        self.creatorId = creatorId
        self.participantIds = participantIds
        self.startDate = startDate
        self.endDate = endDate
        self.winnerId = nil
        self.scores = [:]
        self.createdAt = Date()
    }
    
    var isActive: Bool {
        return status == .active && Date() >= startDate && Date() <= endDate
    }
    
    var isCompleted: Bool {
        return status == .completed || Date() > endDate
    }
    
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var durationInDays: Int {
        return Int(duration / (24 * 3600))
    }
    
    func getWinner() -> UUID? {
        guard !scores.isEmpty else { return nil }
        return scores.max(by: { $0.value < $1.value })?.key
    }
    
    func updateScore(for userId: UUID, score: Double) {
        scores[userId] = score
    }
} 