import Foundation
import HealthKit
import UIKit

@MainActor
class HealthKitManager: ObservableObject, @unchecked Sendable {
    @Published var isAuthorized = false
    @Published var authorizationStatus: String = "Unknown"
    
    private let healthStore = HKHealthStore()
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    
    init() {
        Task {
            checkAuthorizationStatus()
        }
    }
    
    func checkAuthorizationStatus() {
        print("🔍 Checking HealthKit authorization status...")
        
        // First check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit is not available on this device")
            authorizationStatus = "Not Available"
            isAuthorized = false
            return
        }
        
        let status = healthStore.authorizationStatus(for: sleepType)
        print("🔍 Raw authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            print("✅ Status: Not Determined (ready to request)")
            authorizationStatus = "Not Requested"
            isAuthorized = false
        case .sharingDenied:
            print("❌ Status: Sharing Denied")
            authorizationStatus = "Denied"
            isAuthorized = false
        case .sharingAuthorized:
            print("✅ Status: Sharing Authorized")
            authorizationStatus = "Authorized"
            isAuthorized = true
        @unknown default:
            print("⚠️ Status: Unknown (\(status.rawValue))")
            authorizationStatus = "Unknown"
            isAuthorized = false
        }
        
        print("🔍 Final status: \(authorizationStatus), isAuthorized: \(isAuthorized)")
    }
    
    func requestAuthorization() async {
        print("🚀 Starting FINAL authorization test...")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on this device.")
            return
        }

        // Requesting ONLY sleep analysis. This is the simplest possible request.
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        do {
            print("🚀 Requesting ONLY Sleep Analysis permission...")
            try await healthStore.requestAuthorization(toShare: [], read: [sleepType])
            print("🚀 Authorization request function completed.")
            
            await MainActor.run {
                self.checkAuthorizationStatus()
            }
            
        } catch {
            print("❌ FINAL TEST FAILED: HealthKit authorization error: \(error.localizedDescription)")
            await MainActor.run {
                self.authorizationStatus = "Error"
            }
        }
    }
    
    func fetchSleepData(for date: Date) async -> SleepData? {
        guard isAuthorized else { 
            print("❌ Cannot fetch sleep data - not authorized")
            return nil 
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                
                if let error = error {
                    print("❌ Error fetching sleep data: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    print("ℹ️ No sleep samples found for \(date)")
                    continuation.resume(returning: nil)
                    return
                }
                
                print("✅ Found \(sleepSamples.count) sleep samples")
                let sleepData = HealthKitManager.processSleepSamples(sleepSamples)
                continuation.resume(returning: sleepData)
            }
            
            healthStore.execute(query)
        }
    }
    
    static func processSleepSamples(_ samples: [HKCategorySample]) -> SleepData? {
        var bedTime: Date?
        var wakeTime: Date?
        var totalSleepDuration: TimeInterval = 0
        
        for sample in samples {
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                if bedTime == nil || sample.startDate < bedTime! {
                    bedTime = sample.startDate
                }
                if wakeTime == nil || sample.endDate > wakeTime! {
                    wakeTime = sample.endDate
                }
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                 HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                totalSleepDuration += sample.endDate.timeIntervalSince(sample.startDate)
            default:
                break
            }
        }
        
        guard let bedTime = bedTime, let wakeTime = wakeTime else { return nil }
        
        return SleepData(
            date: bedTime,
            bedTime: bedTime,
            wakeTime: wakeTime,
            duration: totalSleepDuration
        )
    }
}

struct SleepData {
    let date: Date
    let bedTime: Date
    let wakeTime: Date
    let duration: TimeInterval
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
} 