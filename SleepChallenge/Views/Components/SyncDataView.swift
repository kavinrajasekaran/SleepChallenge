import SwiftUI

struct SyncDataView: View {
    @EnvironmentObject var dataManager: SimpleDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var isSyncing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Sync Sleep Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose a date to sync your sleep data from Apple Health")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Date Picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Date")
                        .font(.headline)
                    
                    DatePicker(
                        "Sleep Date",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Health Kit Status
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: dataManager.isHealthKitAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(dataManager.isHealthKitAuthorized ? .green : .orange)
                        
                        Text("HealthKit Access")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    Text(dataManager.isHealthKitAuthorized ? 
                         "Connected to Apple Health" : 
                         "HealthKit access required to sync sleep data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !dataManager.isHealthKitAuthorized {
                        Button("Request Access") {
                            Task {
                                await dataManager.requestHealthKitAuthorization()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                // Sync Button
                Button(action: syncData) {
                    HStack {
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        
                        Text(isSyncing ? "Syncing..." : "Sync Sleep Data")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(dataManager.isHealthKitAuthorized ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!dataManager.isHealthKitAuthorized || isSyncing)
            }
            .padding()
            .navigationTitle("Sync Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func syncData() {
        Task {
            isSyncing = true
            await dataManager.syncSleepData(for: selectedDate)
            isSyncing = false
            dismiss()
        }
    }
}

#Preview {
    SyncDataView()
        .environmentObject(SimpleDataManager())
} 