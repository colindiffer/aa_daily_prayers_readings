@echo off
echo "Building AA Readings app with native debug symbols..."

cd %~dp0

:: Clean the build directory
flutter clean

:: Build the app bundle with native debug symbols enabled
flutter build appbundle --release

echo "Extracting debug symbols..."

:: Directory for debug symbols
set SYMBOLS_DIR=native-debug-symbols

:: Get the version code from pubspec.yaml
for /F "tokens=2 delims=+" %%a in ('findstr /C:"version:" pubspec.yaml') do set VERSION_CODE=%%a

:: Zip the native debug symbols from build directory
cd build\app\intermediates\merged_native_libs\release\out\lib
powershell Compress-Archive -Path * -DestinationPath ..\..\..\..\..\..\%SYMBOLS_DIR%\native-symbols-v%VERSION_CODE%.zip -Force
cd ..\..\..\..\..\..\

echo "Debug symbols archived to %SYMBOLS_DIR%\native-symbols-v%VERSION_CODE%.zip"
echo "You can upload this file to Google Play Console as native debug symbols."

echo "Build completed successfully."
