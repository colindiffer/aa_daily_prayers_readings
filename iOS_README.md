# iOS Setup for AA Daily Readings

## Prerequisites

1. **macOS with Xcode**: iOS development requires macOS with Xcode installed
2. **Apple Developer Account**: For App Store distribution
3. **Flutter iOS setup**: Run `flutter doctor` to ensure iOS toolchain is installed

## Firebase iOS Configuration

**⚠️ IMPORTANT**: Replace the placeholder `GoogleService-Info.plist` file:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (gear icon)
4. Click "Add App" and select iOS
5. Use bundle ID: `com.aareadingsandprayers.aaReadings25`
6. Download the `GoogleService-Info.plist` file
7. Replace `ios/Runner/GoogleService-Info.plist` with the downloaded file

## App Configuration

### Bundle ID
- **Production**: `com.aareadingsandprayers.aaReadings25`
- **Version**: 8.1.1 (Build 10)
- **Min iOS Version**: 12.0

### App Store Information
- **App Name**: AA Daily Readings
- **Category**: Lifestyle
- **Bundle Display Name**: AA Daily Readings

## Building for iOS

### Development Build (Simulator)
```bash
flutter run -d ios
```

### Release Build (No Code Sign)
```bash
flutter build ios --release --no-codesign
```

### Archive for App Store
```bash
flutter build ios --release
```

## Code Signing & App Store

1. **Apple Developer Account**: Required for distribution
2. **Certificates**: iOS Distribution Certificate needed
3. **Provisioning Profiles**: App Store provisioning profile
4. **App Store Connect**: Create app listing

## iOS-Specific Features

### Enhanced Features on iOS:
- **High-Quality Voices**: iOS Siri voices (superior to Android TTS)
- **System Integration**: Native App Store reviews
- **Background Audio**: Excellent background playback support
- **Native Notifications**: iOS notification system

### Voice Selection on iOS:
Your app will automatically use iOS system voices:
- **US English**: High-quality male/female voices
- **UK English**: Native British accent voices
- **Better Quality**: iOS voices are generally superior to Android

### Permissions Already Configured:
- ✅ Microphone (for TTS engine)
- ✅ Local Network (for voice models)
- ✅ Notifications (for daily reminders)
- ✅ Background Audio (for continuous playback)

## Testing

### iOS Simulator Testing:
```bash
# List available simulators
flutter devices

# Run on specific simulator
flutter run -d "iPhone 15 Pro"
```

### Physical Device Testing:
Requires:
- Apple Developer Account
- Device registered in developer portal
- Development provisioning profile

## App Store Submission

1. **Archive in Xcode**: Open `ios/Runner.xcworkspace` in Xcode
2. **Upload to App Store Connect**: Use Xcode's archive organizer
3. **App Store Review**: Submit for Apple's review process

## Troubleshooting

### Common Issues:
- **Code signing errors**: Ensure proper certificates and profiles
- **Firebase errors**: Verify `GoogleService-Info.plist` is correct
- **Voice issues**: iOS voices should work better than Android
- **Background playback**: Should work seamlessly on iOS

### VS Code Tasks Available:
- `Flutter Build iOS (No Code Sign)`: Release build without signing
- `Flutter Build iOS Simulator`: Simulator-specific build
- `Flutter Run iOS Simulator`: Run on iOS simulator

## iOS vs Android Differences

### Advantages on iOS:
1. **Better TTS Quality**: iOS Siri voices are superior
2. **Smooth Background Audio**: iOS handles this excellently
3. **Native App Store Reviews**: Better integration
4. **Professional Notifications**: iOS notification system

### No Major Limitations:
All your Android features work on iOS, often with better quality!
