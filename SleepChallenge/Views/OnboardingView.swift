import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var dataManager: SimpleDataManager
    @State private var name = ""
    @State private var email = ""
    @State private var currentStep = 0
    @State private var isRequestingPermissions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // App Icon and Title
                VStack(spacing: 20) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Sleep Challenge")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Compete with friends for better sleep")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Onboarding Steps
                if currentStep == 0 {
                    welcomeStep
                } else if currentStep == 1 {
                    userInfoStep
                } else if currentStep == 2 {
                    healthKitStep
                }
                
                Spacer()
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 2 ? "Get Started" : "Next") {
                        handleNextStep()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep == 1 && (name.isEmpty || email.isEmpty))
                    .disabled(currentStep == 2 && isRequestingPermissions)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Text("Welcome to Sleep Challenge!")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(icon: "trophy.fill", title: "Compete with Friends", description: "Challenge your friends to see who gets the best sleep")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Track Your Progress", description: "Monitor your sleep quality and duration over time")
                FeatureRow(icon: "heart.fill", title: "Health Integration", description: "Seamlessly sync with Apple Health for accurate data")
            }
        }
    }
    
    private var userInfoStep: some View {
        VStack(spacing: 20) {
            Text("Tell us about yourself")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 15) {
                TextField("Your Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                
                TextField("Email Address", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
    }
    
    private var healthKitStep: some View {
        VStack(spacing: 20) {
            Text("Enable Health Access")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("To track your sleep and compete with friends, we need access to your Health data.")
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Your data is private and secure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "iphone")
                        .foregroundColor(.blue)
                    Text("Data stays on your device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isRequestingPermissions {
                ProgressView("Requesting permissions...")
                    .padding()
            }
        }
    }
    
    private func handleNextStep() {
        if currentStep < 2 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Final step - create user and request permissions
            Task {
                isRequestingPermissions = true
                await dataManager.requestHealthKitAuthorization()
                dataManager.createUser(name: name, email: email)
                isRequestingPermissions = false
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(SimpleDataManager())
} 