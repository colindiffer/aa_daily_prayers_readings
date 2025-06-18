# aa_readings_25

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

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
