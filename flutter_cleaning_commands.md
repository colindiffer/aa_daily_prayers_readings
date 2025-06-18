# Flutter Cleaning Commands

## Basic Cleaning Commands

- `flutter clean`
  - Deletes the build/ directory and .dart_tool/ directories
  - Useful when you're experiencing build issues

- `flutter pub cache clean`
  - Cleans the pub cache
  - Removes cached packages that are no longer needed

## Dependency Management

- `flutter pub get`
  - Gets all the dependencies listed in pubspec.yaml
  - Run after cleaning to reinstall dependencies

- `flutter pub upgrade`
  - Updates all dependencies to their latest versions

- `flutter pub outdated`
  - Shows which dependencies have newer versions available

## Maintenance Commands

- `flutter doctor`
  - Verifies Flutter installation and dependencies
  - Diagnoses issues with your development setup

- `flutter analyze`
  - Analyzes code for errors and warnings

- `dart fix --apply`
  - Automatically fixes common issues in Dart code

- `flutter format .`
  - Formats all Dart files in the project according to Dart guidelines

## iOS Specific

- `rm -rf ios/Pods ios/Podfile.lock`
  - Removes CocoaPods dependencies (run `pod install` afterward)
  
## Android Specific

- `cd android && ./gradlew clean`
  - Cleans the Android build

## Complete Reset

For a complete reset when facing persistent issues:
```bash
flutter clean
rm -rf pubspec.lock
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod deintegrate && pod setup && cd ..
flutter pub get
cd ios && pod install && cd ..
```
