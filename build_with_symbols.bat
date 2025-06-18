@echo off
echo "Building Android App Bundle with debug symbols..."

:: Clean the build to ensure fresh build
flutter clean

:: Build the app bundle with debug symbols
flutter build appbundle --release --obfuscate --split-debug-info=./symbols

:: Create symbols directory if it doesn't exist
if not exist "symbols\android-arm" mkdir symbols\android-arm
if not exist "symbols\android-arm64" mkdir symbols\android-arm64
if not exist "symbols\android-x64" mkdir symbols\android-x64

echo "Creating debug symbols ZIP file..."
cd symbols

:: Using PowerShell to create the ZIP file
powershell Compress-Archive -Path * -DestinationPath ..\app-symbols.zip -Force

cd ..
echo "Debug symbols ZIP file created at app-symbols.zip"
echo "Upload this file to the Google Play Console for better crash reporting."
