@echo off
echo Updating release notes for version 4...

:: Get today's date in YYYY-MM-DD format
for /f "tokens=2 delims==" %%a in ('wmic OS get LocalDateTime /value') do set dt=%%a
set today=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%

:: Update the first line of the release notes with version 4
powershell -Command "(Get-Content RELEASE_NOTES.txt) | ForEach-Object { $_ -replace 'Version 1.0.0 \(May 2025\)', 'Version 1.0.0+4 (May 29, 2025)' } | Set-Content RELEASE_NOTES.txt"

echo Release notes updated to version 1.0.0+4

echo Creating version 4 release package...

:: Create a directory for this release if it doesn't exist
if not exist "releases" mkdir releases

:: Copy the key files to the release directory
copy build\app\outputs\bundle\release\app-release.aab releases\aa_readings_1.0.0+4.aab
copy RELEASE_NOTES.txt releases\RELEASE_NOTES-v4.txt
copy STORE_DESCRIPTIONS.txt releases\STORE_DESCRIPTIONS-v4.txt

:: If native debug symbols exist, copy those too
if exist native-debug-symbols\native-symbols-v4.zip copy native-debug-symbols\native-symbols-v4.zip releases\native-symbols-v4.zip

echo Done! Version 4 release files are in the 'releases' directory.
echo - App Bundle: releases\aa_readings_1.0.0+4.aab
echo - Release Notes: releases\RELEASE_NOTES-v4.txt
echo - Store Descriptions: releases\STORE_DESCRIPTIONS-v4.txt
echo - Native Debug Symbols: releases\native-symbols-v4.zip (if available)
