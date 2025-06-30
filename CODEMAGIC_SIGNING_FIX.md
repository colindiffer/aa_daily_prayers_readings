# iOS Code Signing Fix - Manual Certificate Setup

## Current Issue
```
No development certificates available to code sign app for device deployment
```

This means Codemagic cannot find the required certificates and provisioning profiles for App Store distribution.

## Solution: Manual Certificate Upload

### Step 1: Download Required Files from Apple Developer Portal

1. **Go to Apple Developer Portal** → [developer.apple.com](https://developer.apple.com)
2. **Navigate to Certificates, Identifiers & Profiles**

#### Download Distribution Certificate:
3. Go to **Certificates** → **All**
4. Look for **Apple Distribution** or **iOS Distribution** certificate
5. Download the certificate (.cer file)
6. **Convert to P12 format:**
   - Open **Keychain Access** on Mac
   - Import the .cer file
   - Right-click the certificate → **Export**
   - Choose **Personal Information Exchange (.p12)**
   - Set a password (remember this!)

#### Download Provisioning Profile:
7. Go to **Profiles** → **All**
8. Look for **App Store** profile for bundle ID `com.aareadingsandprayers.aaReadings25`
9. If it doesn't exist, create one:
   - Click **+** → **App Store**
   - Select your App ID: `com.aareadingsandprayers.aaReadings25`
   - Select your Distribution certificate
   - Name it (e.g., "AA Readings App Store")
   - Download the .mobileprovision file

### Step 2: Upload to Codemagic

1. **Go to Codemagic Dashboard** → Your App → **Settings** → **Code signing identities**

2. **Upload Certificate:**
   - Click **Add certificate**
   - Upload your .p12 file
   - Enter the password you set

3. **Upload Provisioning Profile:**
   - Click **Add provisioning profile**
   - Upload your .mobileprovision file

### Step 3: Test the Setup

Create a branch and push to test:

```bash
git checkout -b signing-debug
git push origin signing-debug
```

This will trigger the `ios-signing-debug` workflow to check the setup.

## Alternative: Fix App Store Connect Integration

If you prefer automatic signing:

1. **Check Codemagic Teams Integration:**
   - Go to **Teams** → **Integrations** → **App Store Connect**
   - Ensure `code_magic` integration is properly authenticated
   - Re-authenticate if needed

2. **Verify Apple Developer Account:**
   - Account must have App Store Connect access
   - Bundle ID must be registered in Apple Developer Portal
   - Must have valid Apple Developer Program membership

## Expected Files Needed:
- ✅ **Distribution Certificate** (.p12) with password
- ✅ **App Store Provisioning Profile** (.mobileprovision) for `com.aareadingsandprayers.aaReadings25`

## Next Steps:
1. Download and upload the certificate and provisioning profile
2. Test with `signing-debug` branch
3. Once working, the main workflow should succeed

## Troubleshooting:
- Ensure certificate is **Distribution** type (not Development)
- Ensure provisioning profile is **App Store** type (not Ad Hoc)
- Ensure bundle ID exactly matches: `com.aareadingsandprayers.aaReadings25`
- Certificate and profile must be from the same Apple Developer account
