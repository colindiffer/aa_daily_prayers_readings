# AA Readings & Prayers

A Flutter application providing daily AA readings and prayers for members of Alcoholics Anonymous and those in recovery.

## 📱 App Information

- **Name**: AA Readings & Prayers
- **Version**: 1.5.2
- **Platforms**: Android, iOS
- **Bundle ID**: com.aareadingsandprayers.app

## 🚀 Features

- Daily AA readings and meditations
- Text-to-speech functionality
- Notification reminders
- Sobriety counter
- Clean, accessible interface
- Offline functionality
- Multiple reading collections

## 🏗️ CI/CD with Codemagic

This project is configured for automated builds using Codemagic CI/CD.

### Codemagic Setup Instructions

1. **Connect Repository**
   - Go to [Codemagic](https://codemagic.io)
   - Connect this GitHub repository
   - Select the `version-2` branch for builds

2. **Configure Environment Variables**

   **For iOS builds:**
   - `APP_STORE_ID`: Your App Store Connect app ID
   - Apple Developer credentials via App Store Connect integration

   **For Android builds:**
   - `KEYSTORE_PASSWORD`: Android keystore password
   - `KEY_PASSWORD`: Android key password
   - `KEY_ALIAS`: Android key alias
   - `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`: Google Play Console service account

3. **Upload Certificates**
   - **iOS**: Upload your distribution certificate and provisioning profile
   - **Android**: Upload your release keystore file

4. **Firebase Configuration**
   - Ensure `google-services.json` is in `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/` (when building on macOS)

### Manual Build Commands

**Android:**
```bash
flutter build appbundle --release --build-name=1.5.2 --build-number=2
```

**iOS (macOS only):**
```bash
flutter build ipa --release --build-name=1.5.2 --build-number=2
```

## 📋 Development Setup

### Prerequisites
- Flutter SDK (stable channel)
- Android Studio / Xcode
- Firebase project configured

### Local Development
```bash
# Clone the repository
git clone https://github.com/colindiffer/aa_reading_app.git
cd aa_reading_app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### iOS Development (macOS only)
```bash
# Install CocoaPods dependencies
cd ios
pod install
cd ..

# Open in Xcode
open ios/Runner.xcworkspace
```

## 🔧 Configuration Files

- `codemagic.yaml` - CI/CD configuration
- `android/app/google-services.json` - Firebase Android config
- `ios/Runner/GoogleService-Info.plist` - Firebase iOS config (add when building)
- `ios/Podfile` - iOS dependencies
- Various setup guides in the project root

## 📱 App Store Information

### Google Play Store
- **Package Name**: com.aareadingsandprayers.app
- **Target API**: 34 (Android 14)
- **Minimum API**: 21 (Android 5.0)

### Apple App Store
- **Bundle ID**: com.aareadingsandprayers.app
- **Minimum iOS**: 12.0
- **Device Support**: iPhone, iPad

## 🔐 Permissions

**Android:**
- Notifications (for daily reminders)
- Internet (for analytics)
- Storage (for offline readings)

**iOS:**
- Notifications (for daily reminders)
- Background processing (for scheduled notifications)

## 📖 Documentation

Additional setup guides available:
- `IOS_SETUP_GUIDE.md` - Complete iOS setup instructions
- `FIREBASE_IOS_SETUP.md` - Firebase iOS configuration
- `IOS_PREPARATION_SUMMARY.md` - Overview of iOS changes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is intended for the recovery community and AA fellowship.

## 🆘 Support

For technical support or questions:
- Email: colin.differ@gmail.com
- Create an issue in this repository

## 🏷️ Version History

- **1.5.2** - Complete iOS preparation, Google Play release readiness
- **1.5.0** - UI improvements, edge-to-edge support
- **1.4.x** - Feature additions and bug fixes

---

Built with ❤️ for the recovery community

# App Setup Instructions

## Before running the app

Before running the app for the first time or after a `flutter clean`, you need to apply patches:

```bash
# On Windows
.\apply_patches.bat

# On Unix/Mac
./apply_patches.sh
```

This will fix the Google Mobile Ads plugin namespace issue with newer versions of Android Gradle Plugin.

# Patch Information

This project includes patches for the Google Mobile Ads plugin to fix build issues.

## Issue
The Google Mobile Ads plugin (version 3.1.0) is missing the required namespace definition in its build.gradle file, causing build failures with newer Android Gradle Plugin versions.

## Solution
A patch has been added that inserts the namespace declaration:

```diff
android {
+    namespace 'io.flutter.plugins.googlemobileads'
    compileSdkVersion 33
    ...
}
```

## How to apply patches
Run the following command before building:
```
./build.bat
```

Or manually apply the patch:
```
patch -N "$HOME/AppData/Local/Pub/Cache/hosted/pub.dev/google_mobile_ads-3.1.0/android/build.gradle" < "$HOME/app/aa_readings_25/patches/google_mobile_ads+3.1.0/android/build.gradle.patch"
```

## Running the app

After applying patches, you can run the app normally:

```bash
flutter run
```
