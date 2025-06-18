# Firebase iOS Configuration

## Steps to Configure Firebase for iOS

### 1. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create new one)
3. Click "Add app" → iOS
4. Enter iOS bundle ID: `com.aareadingsandprayers.app`
5. App nickname: "AA Readings & Prayers iOS"
6. Download `GoogleService-Info.plist`

### 2. Add GoogleService-Info.plist to Xcode
**Important**: Must be added through Xcode, not just copied to filesystem

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on "Runner" folder in Project Navigator
3. Select "Add Files to Runner"
4. Choose the downloaded `GoogleService-Info.plist`
5. Ensure "Add to target: Runner" is checked
6. Click "Add"

### 3. Verify Integration
The app already includes Firebase dependencies in `pubspec.yaml`:
- firebase_core
- firebase_auth  
- cloud_firestore
- firebase_analytics

### 4. Firebase Services Used
- **Analytics**: User behavior tracking (with consent)
- **Authentication**: User sign-in features
- **Firestore**: Cloud data storage
- **Core**: Firebase initialization

### 5. Privacy Compliance
- Analytics collection respects user consent
- No personal data collected without permission
- Complies with Apple's privacy requirements

## Template GoogleService-Info.plist Structure
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AD_UNIT_ID_FOR_BANNER_TEST</key>
    <string>ca-app-pub-3940256099942544/2934735716</string>
    <key>AD_UNIT_ID_FOR_INTERSTITIAL_TEST</key>
    <string>ca-app-pub-3940256099942544/4411468910</string>
    <key>CLIENT_ID</key>
    <string>YOUR_CLIENT_ID</string>
    <key>REVERSED_CLIENT_ID</key>
    <string>YOUR_REVERSED_CLIENT_ID</string>
    <key>API_KEY</key>
    <string>YOUR_API_KEY</string>
    <key>GCM_SENDER_ID</key>
    <string>YOUR_SENDER_ID</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>com.aareadingsandprayers.app</string>
    <key>PROJECT_ID</key>
    <string>YOUR_PROJECT_ID</string>
    <key>STORAGE_BUCKET</key>
    <string>YOUR_PROJECT_ID.appspot.com</string>
    <key>IS_ADS_ENABLED</key>
    <true/>
    <key>IS_ANALYTICS_ENABLED</key>
    <true/>
    <key>IS_APPINVITE_ENABLED</key>
    <false/>
    <key>IS_GCM_ENABLED</key>
    <true/>
    <key>IS_SIGNIN_ENABLED</key>
    <true/>
    <key>GOOGLE_APP_ID</key>
    <string>YOUR_GOOGLE_APP_ID</string>
    <key>DATABASE_URL</key>
    <string>YOUR_DATABASE_URL</string>
</dict>
</plist>
```

Note: Replace all "YOUR_*" values with actual values from Firebase Console.

## Next Steps
1. Create/access Firebase project
2. Add iOS app to project  
3. Download actual GoogleService-Info.plist
4. Add to Xcode project as described above
5. Build and test on iOS device/simulator
