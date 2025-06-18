@echo off
echo Applying patches...
flutter pub get
cd %~dp0
flutter pub run patch_package
echo Patches applied successfully.
