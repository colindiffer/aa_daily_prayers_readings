# Codemagic Setup Guide for AA Readings & Prayers

## 🚀 Quick Start with Codemagic

Your AA Readings & Prayers app is now ready for automated CI/CD with Codemagic! Here's how to set it up:

### 1. Connect to Codemagic

1. Go to [Codemagic.io](https://codemagic.io)
2. Sign in with your GitHub account
3. Click "Add application"
4. Select this repository: `colindiffer/aa_reading_app`
5. Choose the `version-2` branch
6. Codemagic will automatically detect the `codemagic.yaml` configuration

### 2. Configure Environment Variables

#### For iOS Builds:
1. Go to App settings > Environment variables
2. Add these variables:
   - `APP_STORE_ID`: Your App Store Connect app ID (get from App Store Connect)
   - `BUNDLE_ID`: `com.aareadingsandprayers.app` (already set in config)

#### For Android Builds:
1. Add these variables:
   - `PACKAGE_NAME`: `com.aareadingsandprayers.app` (already set in config)
   - `KEYSTORE_PASSWORD`: Your Android keystore password
   - `KEY_PASSWORD`: Your Android signing key password  
   - `KEY_ALIAS`: Your Android key alias

### 3. Upload Signing Files

#### iOS Signing:
1. Go to App settings > Code signing identities
2. Upload your iOS Distribution Certificate (.p12 file)
3. Upload your App Store Provisioning Profile
4. Or use automatic code signing with App Store Connect integration

#### Android Signing:
1. Go to App settings > Code signing identities
2. Upload your Android release keystore file (.jks or .keystore)
3. Set the keystore reference name as `keystore_reference`

### 4. Set up Integrations

#### App Store Connect (for iOS):
1. Go to App settings > Integrations
2. Add App Store Connect integration
3. Upload your App Store Connect API key
4. This enables automatic code signing and publishing

#### Google Play Console (for Android):
1. Go to App settings > Integrations  
2. Add Google Play integration
3. Upload your Google Play service account JSON file
4. Set the variable `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`

### 5. Firebase Setup (Important!)

#### Android:
- ✅ `google-services.json` is already in the repository
- No additional setup needed

#### iOS:
1. **IMPORTANT**: Add `GoogleService-Info.plist` to your repository
2. Place it in `ios/Runner/GoogleService-Info.plist`
3. This must be done manually as it contains your Firebase iOS configuration

### 6. Build Configuration

The `codemagic.yaml` file is already configured with:

- **iOS Workflow**: Builds IPA and submits to TestFlight
- **Android Workflow**: Builds AAB and submits to Google Play Internal Track
- **Version**: 1.5.2 with auto-incrementing build numbers
- **Artifacts**: Saves build outputs and logs
- **Notifications**: Sends email notifications on success/failure

### 7. Trigger Your First Build

1. Push any commit to the `version-2` branch
2. Codemagic will automatically start building
3. Monitor the build in the Codemagic dashboard
4. Check logs if any issues occur

### 8. Publishing Settings

#### iOS:
- Builds will be submitted to TestFlight automatically
- Manual submission to App Store (set `submit_to_app_store: true` to automate)

#### Android:
- Builds will be submitted to Google Play Internal Track as drafts
- Promote to production manually in Google Play Console

## 🔧 Customization Options

### Build Triggers:
- Currently triggered on every push to `version-2` branch
- Can be configured for specific branches or tags

### Build Environments:
- iOS: `mac_mini_m1` for fast builds
- Android: `linux_x2` for efficient Android builds

### Notification Settings:
- Email notifications configured for `colin.differ@gmail.com`
- Can add Slack, Discord, or other integrations

## 🚨 Common Issues & Solutions

### iOS Build Fails:
1. **Check code signing**: Ensure certificates and profiles are uploaded
2. **Firebase iOS**: Make sure `GoogleService-Info.plist` is added
3. **Dependencies**: CocoaPods issues usually resolve with `pod install`

### Android Build Fails:
1. **Check keystore**: Ensure keystore file and passwords are correct
2. **Firebase Android**: `google-services.json` should be in the repo
3. **Gradle issues**: Usually resolve with clean builds

### Build Timeouts:
- iOS builds: 120 minutes max (usually 15-30 minutes)
- Android builds: 120 minutes max (usually 10-20 minutes)

## 📊 Monitoring & Logs

- **Build Status**: Monitor in Codemagic dashboard
- **Artifacts**: Download IPA/AAB files from completed builds
- **Logs**: View detailed build logs for troubleshooting
- **Email Reports**: Automatic notifications on build completion

## 🎯 Next Steps

1. **Set up Codemagic** following this guide
2. **Test with a commit** to trigger your first build
3. **Configure App Store Connect** for iOS publishing
4. **Set up Google Play Console** for Android publishing
5. **Monitor and iterate** on your CI/CD pipeline

## 🆘 Support

- **Codemagic Docs**: [docs.codemagic.io](https://docs.codemagic.io)
- **Flutter CI/CD**: [docs.codemagic.io/flutter](https://docs.codemagic.io/flutter)
- **Support**: Contact Codemagic support or create an issue in this repo

---

Your app is now ready for automated builds and deployments! 🚀
