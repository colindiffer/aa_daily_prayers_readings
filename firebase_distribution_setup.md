# Firebase App Distribution Setup

1. Install the Firebase CLI:
   ```
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```
   firebase login
   ```

3. Add Firebase App Distribution to your project:
   ```
   firebase init app-distribution
   ```

4. Distribute your app:
   ```
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app [your-firebase-app-id] --groups "testers"
   ```

Replace `[your-firebase-app-id]` with your actual Firebase app ID.
