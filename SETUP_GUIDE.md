# Sleep Challenge App - Setup Guide

## ✅ Issues Fixed

The following issues have been resolved:

1. **Duplicate Info.plist error** - Removed custom Info.plist file
2. **DataManager environment object mismatch** - Updated all views to use `SimpleDataManager`
3. **Build compilation errors** - All Swift files now compile successfully

## 🔧 Remaining Configuration Steps

To complete the setup and fix the HealthKit permission issues, follow these steps in Xcode:

### 1. Open Project in Xcode

```bash
open SleepChallenge.xcodeproj
```

### 2. Configure HealthKit Entitlements

1. **Select the SleepChallenge project** in the navigator (top-level blue icon)
2. **Select the SleepChallenge target** (under TARGETS)
3. **Go to the "Signing & Capabilities" tab**
4. **Click the "+ Capability" button**
5. **Search for and add "HealthKit"**

### 3. Add HealthKit Usage Descriptions

1. **Stay in the SleepChallenge target**
2. **Go to the "Info" tab**
3. **Add the following Custom iOS Target Properties:**

| Key | Type | Value |
|-----|------|-------|
| `NSHealthShareUsageDescription` | String | `Sleep Challenge needs access to your sleep data from Apple Health to track your sleep patterns and compete with friends in sleep challenges.` |
| `NSHealthUpdateUsageDescription` | String | `Sleep Challenge may update your health data to provide better sleep insights and track your progress.` |

### 4. Configure Development Team (Required for HealthKit)

1. **In the "Signing & Capabilities" tab**
2. **Select your development team** from the "Team" dropdown
3. **Ensure "Automatically manage signing" is checked**

> **Note:** You need an Apple Developer account (free or paid) to use HealthKit, even in the simulator.

### 5. Set the Entitlements File (Optional)

If you want to use the entitlements file that was created:

1. **In the "Build Settings" tab**
2. **Search for "Code Signing Entitlements"**
3. **Set the value to:** `SleepChallenge/SleepChallenge.entitlements`

## 🚀 Running the App

### Simulator Testing
- The app will build and run in the simulator
- HealthKit features will show mock data (no real health data available in simulator)
- You can test the UI and navigation

### Device Testing (Recommended)
- Connect a physical iOS device
- Select your device as the run destination
- The app will have full HealthKit functionality
- You can grant real health permissions and sync actual sleep data

## 📱 App Features

### Current Functionality
- ✅ Onboarding flow with user registration
- ✅ Dashboard with sleep overview
- ✅ Challenge creation and management
- ✅ Friends system (local demo)
- ✅ Profile management
- ✅ Mock data generation for testing
- ✅ HealthKit integration (when properly configured)

### Challenge Types
1. **Duration Challenge** - Compete for longest sleep duration
2. **Quality Challenge** - Compete for best sleep quality scores
3. **Consistency Challenge** - Compete for most consistent sleep schedule
4. **Overall Score Challenge** - Compete for highest overall sleep scores

## 🔍 Troubleshooting

### If you see HealthKit permission errors:
1. Ensure you've added the HealthKit capability
2. Verify the usage descriptions are added
3. Make sure you have a development team selected
4. Try running on a physical device instead of simulator

### If the app crashes on "Get Started":
1. Verify all views are using `SimpleDataManager` (this has been fixed)
2. Check that the environment object is properly injected in `SleepChallengeApp.swift`

### If you see build errors:
1. Clean the build folder: Product → Clean Build Folder
2. Restart Xcode
3. Try building again

## 📊 Mock Data

The app includes comprehensive mock data for testing:
- Sample users with different sleep patterns
- Various challenge types and statuses
- Realistic sleep records with scores
- Friend relationships and statistics

## 🔄 Data Sync

- **Simulator**: Uses mock data only
- **Device with HealthKit**: Can sync real sleep data from Apple Health
- **Manual sync**: Available through Profile → Sync Sleep Data

## 🎯 Next Steps

1. Complete the Xcode configuration steps above
2. Run the app on a device for full functionality
3. Test the onboarding flow
4. Create challenges with friends
5. Explore the different challenge types

The app is now ready to use! The core functionality works with mock data, and HealthKit integration will work once you complete the configuration steps in Xcode. 