//
//  SleepChallengeApp.swift
//  SleepChallenge
//
//  Created by Kavin Rajasekaran on 2025-05-27.
//

import SwiftUI
import SwiftData

@main
struct SleepChallengeApp: App {
    @StateObject private var dataManager = SimpleDataManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            SleepRecord.self,
            Challenge.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .onAppear {
                    dataManager.setModelContext(sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
