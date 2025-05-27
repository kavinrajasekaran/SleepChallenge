# Sleep Challenge iOS App

A competitive sleep tracking app that lets you challenge friends to see who gets the better sleep using Apple's HealthKit API.

## Features

### 🏆 Sleep Challenges
- **Duration Challenges**: Compete to see who sleeps the longest
- **Quality Challenges**: Compare sleep quality scores
- **Consistency Challenges**: Maintain the most consistent sleep schedule
- **Overall Score Challenges**: Comprehensive sleep scoring

### 📊 Sleep Tracking
- Automatic sync with Apple Health
- Detailed sleep stage analysis (Deep, REM, Light sleep)
- Sleep quality scoring
- Heart rate variability and resting heart rate integration
- Historical sleep data visualization

### 👥 Social Features
- Add friends by email
- Create group challenges
- Real-time leaderboards
- Win/loss statistics
- Friend sleep data comparison

### 📱 Modern UI
- Clean, intuitive SwiftUI interface
- Tab-based navigation
- Real-time data updates
- Beautiful sleep data visualizations
- Onboarding flow for new users

## Technical Stack

- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Core Data replacement for data persistence
- **HealthKit** - Apple's health data framework
- **iOS 17+** - Latest iOS features and APIs

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Apple Developer account (for HealthKit entitlements)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd SleepChallenge
   ```

2. **Open in Xcode**
   ```bash
   open SleepChallenge.xcodeproj
   ```

3. **Configure HealthKit Capabilities**
   - In Xcode, select your project
   - Go to "Signing & Capabilities"
   - Add "HealthKit" capability
   - Ensure your Apple Developer account has HealthKit entitlements

4. **Update Bundle Identifier**
   - Change the bundle identifier to your own unique identifier
   - Update the development team to your Apple Developer team

5. **Build and Run**
   - Select your target device or simulator
   - Press Cmd+R to build and run

### HealthKit Setup

The app requires the following HealthKit permissions:
- **Sleep Analysis** - Read access to sleep data
- **Heart Rate** - Read access to heart rate data
- **Heart Rate Variability** - Read access to HRV data
- **Resting Heart Rate** - Read access to resting heart rate

These permissions are automatically requested during the onboarding process.

## App Architecture

### Data Models

#### User
- Profile information (name, email, profile image)
- Challenge statistics (wins, participation rate)
- Friends list
- Sleep records

#### SleepRecord
- Sleep duration and timing
- Sleep stages (deep, REM, light, awake)
- Sleep quality score
- Heart rate metrics
- Calculated sleep score

#### Challenge
- Challenge metadata (name, type, duration)
- Participant list
- Real-time scoring
- Status tracking (pending, active, completed)

### Services

#### HealthKitManager
- Handles HealthKit authorization
- Fetches sleep data from Apple Health
- Processes sleep samples into usable data
- Retrieves heart rate metrics

#### DataManager
- Coordinates between HealthKit and SwiftData
- Manages user data and relationships
- Handles challenge creation and scoring
- Synchronizes sleep data

### Views

#### Onboarding
- Welcome screens
- User registration
- HealthKit permission requests

#### Dashboard
- Sleep summary cards
- Active challenges overview
- Quick actions for syncing data
- Recent sleep history

#### Challenges
- Challenge list with filtering
- Challenge creation flow
- Detailed challenge views with leaderboards
- Progress tracking

#### Friends
- Friends list management
- Add friends functionality
- Friend sleep statistics

#### Profile
- User profile management
- Sleep insights and statistics
- App settings and preferences

## Usage Guide

### Getting Started

1. **First Launch**
   - Complete the onboarding process
   - Enter your name and email
   - Grant HealthKit permissions

2. **Sync Sleep Data**
   - Tap the sync button on the dashboard
   - Select dates to sync from Apple Health
   - View your sleep summary

3. **Add Friends**
   - Go to the Friends tab
   - Tap the "+" button
   - Enter friend's email address
   - (Note: In this demo version, friends are created locally)

4. **Create Challenges**
   - Go to the Challenges tab
   - Tap "+" to create a new challenge
   - Choose challenge type and duration
   - Select friends to invite
   - Start competing!

### Challenge Types

#### Sleep Duration
- **Goal**: Sleep the longest on average
- **Scoring**: Average hours of sleep per night
- **Best for**: Encouraging longer sleep

#### Sleep Quality
- **Goal**: Achieve the highest sleep quality
- **Scoring**: Based on sleep stage distribution and minimal wake time
- **Best for**: Improving sleep efficiency

#### Sleep Consistency
- **Goal**: Maintain consistent bedtime and wake time
- **Scoring**: Lower variance in sleep schedule = higher score
- **Best for**: Building healthy sleep habits

#### Overall Sleep Score
- **Goal**: Best comprehensive sleep performance
- **Scoring**: Combination of duration, quality, and sleep stages
- **Best for**: Overall sleep improvement

### Tips for Best Results

1. **Consistent Tracking**
   - Wear your Apple Watch to bed
   - Enable sleep tracking in the Health app
   - Sync data regularly

2. **Challenge Strategy**
   - Start with shorter challenges (3-7 days)
   - Focus on one aspect of sleep at a time
   - Use challenges to build healthy habits

3. **Data Accuracy**
   - Ensure your Apple Watch is properly fitted
   - Keep your devices charged
   - Manually log sleep if automatic tracking fails

## Privacy & Security

- All sleep data remains on your device
- HealthKit data is never shared with external servers
- Friend connections are local to the app
- No personal data is transmitted over the internet

## Limitations

This is a demo/prototype version with the following limitations:

- Friends are created locally (no real user accounts)
- No server backend for real friend connections
- Limited to Apple ecosystem (requires HealthKit)
- Requires Apple Watch for best sleep tracking

## Future Enhancements

- [ ] Real user accounts and friend connections
- [ ] Push notifications for challenge updates
- [ ] Advanced sleep analytics and insights
- [ ] Integration with other fitness metrics
- [ ] Social features like comments and reactions
- [ ] Custom challenge types and rules
- [ ] Sleep coaching and recommendations

## Contributing

This is a demonstration project. For production use, consider:

1. Implementing a proper backend service
2. Adding user authentication
3. Enhancing data validation and error handling
4. Adding comprehensive testing
5. Implementing proper friend invitation system

## License

This project is for educational and demonstration purposes. Please ensure you have proper licensing for any production use.

## Support

For questions or issues with this demo app, please refer to the code comments and Apple's HealthKit documentation.

---

**Note**: This app is designed to encourage healthy sleep habits through friendly competition. Always consult with healthcare professionals for serious sleep concerns. 