@echo off
echo ========================================
echo   AA Readings App - Production Build
echo ========================================
echo.
echo This script builds a RELEASE APK to test
echo the production rating behavior.
echo.
echo In release mode:
echo - In-app ratings show real Android dialog
echo - Users can rate 1-5 stars in the app
echo - Store links open Google Play Store
echo.
echo Building release APK...
echo.

flutter clean
flutter pub get
flutter build apk --release

echo.
echo ========================================
echo Build complete!
echo.
echo APK location: build\app\outputs\flutter-apk\app-release.apk
echo.
echo To install on connected device:
echo   flutter install
echo.
echo To test rating system:
echo 1. Open the app
echo 2. Go to About page
echo 3. Tap "Rating System Demo"
echo 4. Test the different rating options
echo.
echo ========================================
pause
