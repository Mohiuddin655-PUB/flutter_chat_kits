# Quick Start Guide - 5 Minutes Setup ⚡

Get the Flutter Chat Kits example running in 5 minutes!

## 1️⃣ Firebase Setup (2 minutes)

### Create Project
1. Go to https://console.firebase.google.com/
2. Click "Add project" → Enter name → Continue
3. Disable Google Analytics (optional) → Create project

### Enable Services
Click on each service and enable:
- **Authentication** → Email/Password
- **Firestore Database** → Create database → Test mode → Enable
- **Storage** → Get started → Test mode → Enable
- **Realtime Database** → Create database → Test mode → Enable

### Add Your App
**Android:**
1. Click Android icon → Register app
2. Package name: `com.example.example`
3. Download `google-services.json`
4. Place in `example/android/app/google-services.json`

**iOS:**
1. Click iOS icon → Register app
2. Bundle ID: `com.example.example`
3. Download `GoogleService-Info.plist`
4. Add to Xcode project in `example/ios/Runner/`

## 2️⃣ Generate Firebase Config (1 minute)

```bash
# Install FlutterFire CLI (one-time only)
dart pub global activate flutterfire_cli

# Go to example folder
cd example

# Generate config
flutterfire configure
```

Select your Firebase project and platforms. This creates `lib/firebase_options.dart`.

## 3️⃣ Push Notification Setup (1 minute)

### Download Service Account Key
1. Firebase Console → ⚙️ Project Settings
2. Service accounts tab
3. Click "Generate new private key"
4. Download JSON file

### Setup in Project
```bash
# Create secrets folder
mkdir -p assets/secrets

# Move the downloaded file
mv ~/Downloads/your-project-*.json assets/secrets/push_notification.json
```

### Update Project ID
Open `lib/push_notification.dart`:
```dart
static const projectId = 'your-firebase-project-id'; // ← Change this
```

## 4️⃣ Security Rules (1 minute)

### Firestore Rules
Firebase Console → Firestore Database → Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Rules
Firebase Console → Storage → Rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Realtime Database Rules
Firebase Console → Realtime Database → Rules:
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

## 5️⃣ Run the App! (30 seconds)

```bash
flutter pub get
flutter run
```

## ✅ Verification Checklist

Make sure you have:
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] `firebase_options.dart` generated
- [ ] `assets/secrets/push_notification.json` created
- [ ] Project ID updated in `push_notification.dart`
- [ ] All Firebase services enabled
- [ ] Security rules published

## 🎉 Done!

You should see the login screen. Create an account and start chatting!

## ⚠️ Common Issues

**Build fails?**
```bash
flutter clean
flutter pub get
```

**Can't login?**
- Check Authentication is enabled in Firebase
- Verify email/password is enabled

**Messages not sending?**
- Check Firestore rules are set
- Verify internet connection

**No notifications?**
- Confirm `push_notification.json` exists
- Check project ID is correct

## 📖 Need More Details?

See [EXAMPLE_README.md](./EXAMPLE_README.md) for full documentation.

---

**Happy Chatting! 💬**