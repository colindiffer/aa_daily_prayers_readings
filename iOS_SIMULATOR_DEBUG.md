# iOS Simulator Debugging Guide

## 🐛 Problem: App launches in iOS Simulator but doesn't work

This usually indicates one of these issues:

## 🔍 **Common Causes & Solutions**

### **1. App Crashes on Startup**
**Symptoms**: Simulator opens, app briefly appears, then disappears
**Solutions**:
```bash
# Check for crash logs
flutter run -d ios --verbose
# Look for error messages in the console
```

### **2. Firebase Configuration Issues**
**Symptoms**: App launches but gets stuck or crashes when using analytics
**Check**: Your `GoogleService-Info.plist` file
```bash
# Verify Firebase config
cat ios/Runner/GoogleService-Info.plist | grep PROJECT_ID
```

### **3. Permission Issues**
**Symptoms**: App works but certain features (TTS, notifications) don't work
**Check**: Info.plist permissions
```bash
# Check permissions
grep -A 2 -B 2 "UsageDescription" ios/Runner/Info.plist
```

### **4. Bundle ID Mismatch**
**Symptoms**: App builds but doesn't match App Store Connect
**Check**: Bundle identifier consistency
```bash
# Check bundle ID
grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

## 🚀 **Debugging Steps**

### **Step 1: Local Testing**
```bash
# Run with verbose logging
flutter run -d ios --verbose

# If that fails, try clean build
flutter clean
flutter pub get
flutter run -d ios --verbose
```

### **Step 2: Check iOS Specific Logs**
```bash
# Open iOS Simulator Console
# In Simulator: Device > Console (or Cmd+/)
# Look for your app name and error messages
```

### **Step 3: Test with Codemagic Debug Workflow**
```bash
# Push to trigger comprehensive debugging
git checkout -b ios-debug
git push origin ios-debug
```
This will run the `ios-debug-comprehensive` workflow with detailed logging.

## 📱 **iOS Simulator Specific Issues**

### **TTS (Text-to-Speech) Problems**
- **Issue**: TTS might not work properly in simulator
- **Solution**: Test on real device or check TTS service initialization

### **Background Audio**
- **Issue**: Background audio modes might not work in simulator
- **Solution**: This is expected - test on real device

### **Notifications**
- **Issue**: Push notifications don't work in simulator
- **Solution**: Normal behavior - use real device for notification testing

### **Firebase Analytics**
- **Issue**: Analytics might not initialize properly
- **Solution**: Check if `GoogleService-Info.plist` is properly configured

## 🔧 **Quick Fixes**

### **1. Reset iOS Simulator**
```bash
# Reset simulator to clean state
xcrun simctl erase all
```

### **2. Clean Flutter Build**
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d ios
```

### **3. Check Flutter Doctor**
```bash
flutter doctor -v
# Fix any iOS-related issues shown
```

### **4. Verify Dependencies**
```bash
# Check if all dependencies support iOS
flutter pub deps --style=tree
```

## 📊 **Expected Behavior**

Your AA Daily Readings app should:
1. ✅ Launch successfully in simulator
2. ✅ Show onboarding screens
3. ✅ Navigate through voice selection
4. ⚠️ TTS might not work perfectly in simulator (normal)
5. ✅ Display readings and content
6. ⚠️ Background audio might not work (normal in simulator)

## 🚨 **Red Flags to Look For**

- **Immediate crash**: Check console logs for specific errors
- **White/black screen**: Usually Firebase or initialization issue
- **Stuck on splash**: Check for infinite loops in initialization
- **Permission dialogs**: Should appear for microphone/notifications

## 📞 **Getting Help**

1. **Run the debug workflow**: `git push origin ios-debug`
2. **Check build logs**: Look for specific error messages
3. **Test on real device**: Many issues only appear in simulator
4. **Verify Firebase**: Ensure proper iOS configuration

The debug workflow will provide detailed logs to identify the exact issue!
