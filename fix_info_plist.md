# Fix Info.plist Configuration

The duplicate Info.plist error has been resolved by removing the custom Info.plist file. Now you need to add the HealthKit permissions to your project settings:

## Steps to Fix in Xcode:

1. **Open the project in Xcode** (if not already open)
2. **Select the SleepChallenge project** in the navigator
3. **Select the SleepChallenge target**
4. **Go to the "Info" tab**
5. **Add the following Custom iOS Target Properties:**

### Required Properties to Add:

| Key | Type | Value |
|-----|------|-------|
| `NSHealthShareUsageDescription` | String | `Sleep Challenge needs access to your sleep data from Apple Health to track your sleep patterns and compete with friends in sleep challenges.` |
| `NSHealthUpdateUsageDescription` | String | `Sleep Challenge may update your health data to provide better sleep insights and challenge results.` |

### How to Add:

1. In the "Custom iOS Target Properties" section, click the "+" button
2. Type the key name (e.g., `NSHealthShareUsageDescription`)
3. Make sure the type is set to "String"
4. Enter the description value
5. Repeat for the second property

### Alternative Method:

If you prefer, you can also add these in the "Capabilities" tab:
1. Go to "Signing & Capabilities" tab
2. Click "+ Capability"
3. Add "HealthKit"
4. The usage descriptions will be added automatically, but you may need to customize them

After making these changes, the project should build successfully without the duplicate Info.plist error. 