//
//  ContentView.swift
//  SleepChallenge
//
//  Created by Kavin Rajasekaran on 2025-05-27.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    
    var body: some View {
        Group {
            if dataManager.currentUser == nil {
                OnboardingView()
            } else {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Dashboard")
                        }
                        .tag(0)
                    
                    ChallengesView()
                        .tabItem {
                            Image(systemName: "trophy.fill")
                            Text("Challenges")
                        }
                        .tag(1)
                    
                    FriendsView()
                        .tabItem {
                            Image(systemName: "person.2.fill")
                            Text("Friends")
                        }
                        .tag(2)
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("Profile")
                        }
                        .tag(3)
                }
                .accentColor(.blue)
            }
        }
        .alert("Error", isPresented: .constant(dataManager.errorMessage != nil)) {
            Button("OK") {
                dataManager.errorMessage = nil
            }
        } message: {
            Text(dataManager.errorMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
        .modelContainer(for: [User.self, SleepRecord.self, Challenge.self], inMemory: true)
}
