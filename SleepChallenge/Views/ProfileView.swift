import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject var dataManager: SimpleDataManager
    
    var body: some View {
        VStack(spacing: 30) {
            Text("HealthKit Integration Test")
                .font(.title)

            VStack {
                Text("Status")
                    .font(.headline)
                Text(dataManager.healthKitStatus)
                    .font(.largeTitle)
                    .foregroundColor(dataManager.isHealthKitAuthorized ? .green : .red)
            }

            if !dataManager.isHealthKitAuthorized {
                Button(action: {
                    Task {
                        await dataManager.requestHealthKitAuthorization()
                    }
                }) {
                    Text("Enable HealthKit Access")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileView()
        .environmentObject(SimpleDataManager())
        .modelContainer(for: [User.self, SleepRecord.self], inMemory: true)
} 