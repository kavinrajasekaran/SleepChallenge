import SwiftUI

struct SyncDataView: View {
    @EnvironmentObject var dataManager: SimpleDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDays = 7
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
                    
                    Text("Import your sleep data from Apple Health")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // HealthKit Status
                statusSection
                
                if dataManager.isHealthKitAuthorized {
                    // Sync Options
                    syncOptionsSection
                    
                    // Sync Button
                    Button(action: syncData) {
                        HStack {
                            if isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            
                            Text(isSyncing ? "Syncing..." : "Sync Data")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isSyncing)
                } else {
                    // Enable HealthKit
                    Button("Enable HealthKit Access") {
                        Task {
                            await dataManager.requestHealthKitAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sync Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("HealthKit Status")
                        .font(.headline)
                    
                    Text(dataManager.healthKitStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var syncOptionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sync Options")
                .font(.headline)
            
            VStack(spacing: 12) {
                Text("How many days of sleep data would you like to sync?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Days to Sync", selection: $selectedDays) {
                    Text("1 Day").tag(1)
                    Text("3 Days").tag(3)
                    Text("7 Days").tag(7)
                    Text("14 Days").tag(14)
                    Text("30 Days").tag(30)
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var statusIcon: String {
        switch dataManager.healthKitStatus {
        case "Authorized":
            return "checkmark.circle.fill"
        case "Denied":
            return "xmark.circle.fill"
        case "Not Requested":
            return "questionmark.circle.fill"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch dataManager.healthKitStatus {
        case "Authorized":
            return .green
        case "Denied":
            return .red
        case "Not Requested":
            return .orange
        default:
            return .gray
        }
    }
    
    private func syncData() {
        isSyncing = true
        
        Task {
            let calendar = Calendar.current
            
            for i in 0..<selectedDays {
                let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
                await dataManager.syncSleepData(for: date)
            }
            
            isSyncing = false
            dismiss()
        }
    }
}

#Preview {
    SyncDataView()
        .environmentObject(SimpleDataManager())
} 