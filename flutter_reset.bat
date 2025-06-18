@echo off
echo Flutter Debug Connection Reset Tool
echo =================================
echo.

echo Step 1: Closing any running Flutter processes...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM flutter.exe >nul 2>&1
timeout /t 2 >nul

echo Step 2: Cleaning Flutter project...
call flutter clean
echo.

echo Step 3: Getting packages...
call flutter pub get
echo.

echo Step 4: Clearing Flutter tool cache...
rmdir /s /q %LOCALAPPDATA%\Temp\flutter_tools.* 2>nul
echo.

echo Step 5: Verifying devices...
call flutter devices
echo.

echo All done! Try running your app again with:
echo flutter run --verbose
echo.
echo Or use the VS Code launch configuration.
