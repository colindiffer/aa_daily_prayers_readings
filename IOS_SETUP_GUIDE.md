# iOS App Setup Guide for AA Readings & Prayers

## Prerequisites
- **macOS** with Xcode installed (iOS development is only possible on macOS)
- **Apple Developer Account** (for App Store distribution)
- **Flutter SDK** installed on macOS

## Current Configuration

### App Details
- **App Name**: AA Readings & Prayers  
- **Bundle ID**: com.aareadingsandprayers.app
- **Version**: 1.5.2 (Build 2)
- **Minimum iOS Version**: 12.0
- **Target Devices**: iPhone and iPad

### Already Configured
✅ Bundle identifier updated to professional domain
✅ App display name updated to "AA Readings & Prayers"
✅ iOS permissions configured for notifications
✅ App icons are in place
✅ Firebase integration ready
✅ All Flutter dependencies iOS-compatible

## Setup Steps on macOS

### 1. Transfer Project
```bash
# Copy the entire project folder to your macOS machine
# Ensure all files are transferred including:
# - ios/ folder with all configurations  
# - lib/ folder with all source code
# - pubspec.yaml with dependencies
```

### 2. Install Dependencies
```bash
cd /path/to/aa_readings_25
flutter pub get
cd ios
pod install --repo-update
```

### 3. Open in Xcode
```bash
open ios/Runner.xcworkspace
```

### 4. Configure Code Signing
In Xcode:
1. Select "Runner" project in navigator
2. Go to "Signing & Capabilities" tab
3. Select your Apple Developer Team
4. Ensure Bundle Identifier is: `com.aareadingsandprayers.app`
5. Enable automatic code signing

### 5. Add Required Capabilities
In "Signing & Capabilities":
- ✅ Background Modes (for notifications)
- ✅ Push Notifications (if using remote notifications)

### 6. Firebase iOS Setup
1. Go to Firebase Console
2. Add iOS app with bundle ID: `com.aareadingsandprayers.app`
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/` folder in Xcode (not just file system)

### 7. Build and Test
```bash
# Clean build
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Build for iOS
flutter build ios --release

# Or run on iOS Simulator
flutter run -d ios
```

### 8. Archive for App Store
In Xcode:
1. Select "Any iOS Device" as target
2. Product → Archive
3. Use Organizer to upload to App Store Connect

## App Store Preparation

### App Store Connect Setup
1. Create new app in App Store Connect
2. Bundle ID: `com.aareadingsandprayers.app`
3. App Name: "AA Readings & Prayers"
4. Category: "Health & Fitness" or "Lifestyle"

### Required Assets
- ✅ App Icons (already configured)
- Screenshots for iPhone and iPad
- App description and keywords
- Privacy policy URL

### Privacy Requirements
The app requests:
- Notification permissions (for daily reminders)
- Analytics data (with user consent)

## Build Commands Summary

```bash
# Development build
flutter run -d ios

# Release build  
flutter build ios --release

# Clean build (if issues)
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

## Troubleshooting

### Common Issues
1. **Pod install fails**: Update CocoaPods with `sudo gem install cocoapods`
2. **Build errors**: Clean project with `flutter clean` then rebuild
3. **Firebase errors**: Ensure GoogleService-Info.plist is properly added in Xcode
4. **Code signing**: Verify Apple Developer account and certificates

### Support
- All iOS-specific configurations are complete
- The app is ready for development on macOS
- Contact Apple Developer Support for code signing issues

## Current Status
✅ iOS project configured and ready for macOS development
✅ Bundle ID and app name properly set
✅ Permissions and capabilities configured  
✅ Firebase integration prepared
✅ Version 1.5.2 ready for build

Next step: Transfer to macOS machine and follow setup steps above.
