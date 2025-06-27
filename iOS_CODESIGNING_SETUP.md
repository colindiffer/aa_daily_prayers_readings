# iOS Code Signing Setup for Codemagic

## 🔐 The Issue
**Error**: "No matching profiles found for bundle identifier 'com.aareadingsandprayers.aaReadings25' and distribution type 'app_store'"

This means you need to set up iOS code signing certificates and provisioning profiles.

## 📋 **Prerequisites**
1. **Apple Developer Account** ($99/year)
2. **App Store Connect Access**
3. **Xcode** (on macOS)

## 🛠️ **Step-by-Step Setup**

### **1. Create App in App Store Connect**
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **"My Apps"** → **"+"** → **"New App"**
3. Fill in:
   - **Platform**: iOS
   - **Name**: AA Daily Readings
   - **Primary Language**: English
   - **Bundle ID**: `com.aareadingsandprayers.aaReadings25`
   - **SKU**: `aa-readings-25` (unique identifier)

### **2. Generate Certificates & Provisioning Profiles**

#### **Option A: Automatic (Recommended)**
1. In Codemagic:
   - Go to **Teams** → **Code signing identities**
   - Click **"iOS"** → **"Automatic code signing"**
   - Connect your Apple Developer account
   - Codemagic will automatically generate certificates and profiles

#### **Option B: Manual**
1. **Apple Developer Portal** → **Certificates**:
   - Create **iOS Distribution Certificate**
   - Download the certificate (.cer file)
   - Export as .p12 with password

2. **Apple Developer Portal** → **Profiles**:
   - Create **App Store Distribution Profile**
   - Select your app's Bundle ID
   - Select the distribution certificate
   - Download the provisioning profile (.mobileprovision)

### **3. Upload to Codemagic**
1. Go to **Teams** → **Code signing identities**
2. Click **"iOS"** → **"Add certificate"**
3. Upload:
   - **Certificate**: .p12 file + password
   - **Provisioning Profile**: .mobileprovision file

### **4. App Store Connect API Key**
1. **App Store Connect** → **Users and Access** → **Keys**
2. Click **"+"** to generate new key
3. Give it **App Manager** role
4. Download the **private key** (.p8 file)
5. Note the **Key ID** and **Issuer ID**

### **5. Configure Codemagic Integration**
1. **Codemagic** → **Teams** → **Integrations**
2. Add **App Store Connect** integration:
   - **Issuer ID**: From App Store Connect
   - **Key ID**: From App Store Connect  
   - **Private Key**: Upload the .p8 file

## 🚀 **Test Your Setup**

### **Immediate Testing (No Signing Required)**
Use the new `ios-test-workflow` I added:
```bash
# Push to a test branch to trigger the unsigned build
git checkout -b test/ios-setup
git push origin test/ios-setup
```

This will build your iOS app without code signing to verify everything works.

### **Full Pipeline (With Signing)**
Once signing is set up:
```bash
# Push to main to trigger the full pipeline
git push origin main
```

## 📱 **What Each Workflow Does**

### **`ios-workflow`** (Full Production)
- ✅ Code signing with certificates
- ✅ Builds signed .ipa file
- ✅ Uploads to TestFlight
- ✅ Ready for App Store submission

### **`ios-test-workflow`** (Testing Only)
- ✅ No code signing required
- ✅ Builds unsigned app
- ✅ Tests that your code compiles
- ✅ Perfect for development testing

## 🔧 **Troubleshooting**

### **Certificate Issues**
- Ensure certificate is **iOS Distribution** (not Development)
- Verify certificate hasn't expired
- Check that provisioning profile matches the certificate

### **Bundle ID Issues**
- Confirm Bundle ID in App Store Connect matches exactly: `com.aareadingsandprayers.aaReadings25`
- Check iOS project settings in Xcode

### **Profile Issues**
- Ensure provisioning profile is **App Store Distribution**
- Verify it includes your Bundle ID
- Check expiration date

## 📞 **Next Steps**
1. **Set up Apple Developer Account** (if not done)
2. **Create app in App Store Connect**
3. **Use automatic code signing** in Codemagic (easiest)
4. **Test with `ios-test-workflow`** first
5. **Enable full pipeline** once signing works

The `ios-test-workflow` will let you test your app builds immediately without any signing setup!
