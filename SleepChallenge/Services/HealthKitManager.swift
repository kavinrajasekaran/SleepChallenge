import Foundation
import HealthKit
import SwiftData

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var authorizationError: Error?
    
    // HealthKit data types we need
    private let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    private let heartRateVariabilityType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.authorizationError = HealthKitError.notAvailable
            }
            return
        }
        
        // Check if Info.plist has required usage descriptions
        guard Bundle.main.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") != nil else {
            print("HealthKit: NSHealthShareUsageDescription not found in Info.plist")
            DispatchQueue.main.async {
                self.authorizationError = HealthKitError.notAvailable
                self.isAuthorized = false
            }
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            sleepAnalysisType,
            heartRateType,
            heartRateVariabilityType,
            restingHeartRateType
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            DispatchQueue.main.async {
                self.isAuthorized = true
                self.authorizationError = nil
            }
        } catch {
            print("HealthKit authorization error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.authorizationError = error
                self.isAuthorized = false
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        let status = healthStore.authorizationStatus(for: sleepAnalysisType)
        DispatchQueue.main.async {
            self.isAuthorized = status == .sharingAuthorized
        }
    }
    
    func fetchSleepData(for date: Date) async throws -> SleepData? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepAnalysisType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let sleepData = self.processSleepSamples(sleepSamples)
                continuation.resume(returning: sleepData)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    private func processSleepSamples(_ samples: [HKCategorySample]) -> SleepData? {
        guard !samples.isEmpty else { return nil }
        
        var totalSleepDuration: TimeInterval = 0
        var deepSleepDuration: TimeInterval = 0
        var remSleepDuration: TimeInterval = 0
        var lightSleepDuration: TimeInterval = 0
        var awakeTime: TimeInterval = 0
        
        var bedTime: Date?
        var wakeTime: Date?
        
        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                if bedTime == nil || sample.startDate < bedTime! {
                    bedTime = sample.startDate
                }
                if wakeTime == nil || sample.endDate > wakeTime! {
                    wakeTime = sample.endDate
                }
                
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                lightSleepDuration += duration
                totalSleepDuration += duration
                
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deepSleepDuration += duration
                totalSleepDuration += duration
                
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                remSleepDuration += duration
                totalSleepDuration += duration
                
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awakeTime += duration
                
            default:
                break
            }
        }
        
        guard let bedTime = bedTime, let wakeTime = wakeTime else {
            return nil
        }
        
        return SleepData(
            bedTime: bedTime,
            wakeTime: wakeTime,
            totalSleepDuration: totalSleepDuration,
            deepSleepDuration: deepSleepDuration,
            remSleepDuration: remSleepDuration,
            lightSleepDuration: lightSleepDuration,
            awakeTime: awakeTime
        )
    }
    
    func fetchHeartRateVariability(for date: Date) async throws -> Double? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateVariabilityType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let hrv = statistics?.averageQuantity()?.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: hrv)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    func fetchRestingHeartRate(for date: Date) async throws -> Double? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: restingHeartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let rhr = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: rhr)
            }
            
            self.healthStore.execute(query)
        }
    }
}

struct SleepData {
    let bedTime: Date
    let wakeTime: Date
    let totalSleepDuration: TimeInterval
    let deepSleepDuration: TimeInterval
    let remSleepDuration: TimeInterval
    let lightSleepDuration: TimeInterval
    let awakeTime: TimeInterval
    
    var sleepQuality: Double {
        guard totalSleepDuration > 0 else { return 0.0 }
        let deepSleepRatio = deepSleepDuration / totalSleepDuration
        let remSleepRatio = remSleepDuration / totalSleepDuration
        let awakeRatio = awakeTime / (totalSleepDuration + awakeTime)
        
        // Quality based on sleep stage distribution and minimal awake time
        return max(0.0, min(1.0, (deepSleepRatio * 0.4 + remSleepRatio * 0.4 + (1.0 - awakeRatio) * 0.2)))
    }
}

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case noData
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .noData:
            return "No sleep data available for the requested date"
        }
    }
} 