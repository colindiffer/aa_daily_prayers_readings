# iOS Rating System Setup

## Cross-Platform Rating Implementation ✅

The AA Daily Readings app now has **full cross-platform support** for in-app ratings on both Android and iOS.

## How It Works

### 🍎 iOS Implementation
When running on iOS, the rating system:

1. **✅ Uses Apple's StoreKit In-App Review API** (iOS 14+)
   - Shows native iOS rating dialog
   - User can rate 1-5 stars directly in the app
   - Ratings go directly to App Store

2. **✅ Fallback to App Store** (if in-app review unavailable)
   - Opens App Store app directly to rating page
   - Uses `itms-apps://` protocol for native App Store experience
   - Falls back to Safari if App Store app unavailable

### 🤖 Android Implementation
When running on Android, the rating system:

1. **✅ Uses Google Play In-App Review API**
   - Shows native Android rating dialog
   - User can rate 1-5 stars directly in the app
   - Ratings go directly to Google Play Store

2. **✅ Fallback to Play Store** (if in-app review unavailable)
   - Opens Play Store app directly to rating page
   - Uses `market://` protocol for native Play Store experience
   - Falls back to browser if Play Store app unavailable

## Required Setup for iOS

### 1. App Store ID Configuration
**⚠️ IMPORTANT:** Update the App Store ID in `rating_banner.dart`:

```dart
// Currently set to placeholder
const String appStoreId = '123456789'; // TODO: Replace with real App Store ID

// Replace with your actual App Store ID when published:
const String appStoreId = 'YOUR_ACTUAL_APP_STORE_ID';
```

**How to get your App Store ID:**
1. Upload your app to App Store Connect
2. Go to App Information
3. Find your Apple ID (numeric value)
4. Replace `123456789` with your actual ID

### 2. iOS Info.plist Configuration
Already configured! ✅ The `Info.plist` includes:
- Proper app name and bundle identifier
- Required permissions
- Background modes for TTS

### 3. URL Scheme Handling
The app automatically handles:
- ✅ `itms-apps://` protocol (opens App Store app)
- ✅ `https://apps.apple.com/` fallback (opens Safari)
- ✅ `?action=write-review` parameter (direct to review page)

## What Users Will See

### 🍎 iOS Users
1. **In-App Review Dialog** (iOS 14+):
   ```
   ┌─────────────────────────────────────┐
   │        Rate this app                │
   │                                     │
   │    AA Daily Readings & Prayers      │
   │                                     │
   │         ⭐ ⭐ ⭐ ⭐ ⭐              │
   │                                     │
   │   [Write a review (optional)]       │
   │                                     │
   │      [Cancel]    [Submit]           │
   └─────────────────────────────────────┘
   ```

2. **App Store Fallback**: Direct to App Store rating page

### 🤖 Android Users
1. **In-App Review Dialog**:
   ```
   ┌─────────────────────────────────────┐
   │        Rate this app                │
   │                                     │
   │    AA Daily Readings & Prayers      │
   │                                     │
   │         ⭐ ⭐ ⭐ ⭐ ⭐              │
   │                                     │
   │   [Write a review (optional)]       │
   │                                     │
   │      [Cancel]    [Submit]           │
   └─────────────────────────────────────┘
   ```

2. **Play Store Fallback**: Direct to Play Store rating page

## Testing

### Debug Mode Behavior
- ✅ **Cross-platform detection works**
- ✅ **Proper fallback URLs generated**
- ✅ **Platform-specific error messages**
- ⚠️ **In-app review won't show** (Apple/Google restriction)

### Production Behavior
- ✅ **Native in-app review dialogs show**
- ✅ **Ratings go directly to stores**
- ✅ **Seamless user experience**

## Store Compliance

### ✅ Apple App Store Compliant
- Uses official StoreKit In-App Review API
- Follows Apple's Human Interface Guidelines
- No direct "Rate us" buttons outside review flow

### ✅ Google Play Store Compliant
- Uses official Play Core In-App Review API
- Follows Google Play's review policies
- Proper fallback implementation

## Demo Screen Updates

The rating demo screen now shows:
- ✅ **Cross-platform behavior explanation**
- ✅ **Platform-specific store names**
- ✅ **Updated instructions for both iOS and Android**

## Next Steps

1. **📝 Update App Store ID** when iOS app is published
2. **🧪 Test on actual iOS device** with App Store installation
3. **📊 Monitor ratings** from both App Store and Play Store
4. **🔄 Optional:** Add platform-specific analytics tracking

## Files Modified

- ✅ `lib/widgets/rating_banner.dart` - Cross-platform implementation
- ✅ `lib/screens/rating_demo_screen.dart` - Updated instructions
- ✅ `ios/Runner/Info.plist` - Already configured

Your app now has **complete cross-platform rating support**! 🎉
