# Flutter Chat Kits - Example App

A complete example implementation of Flutter Chat Kits using Firebase as the backend.

## 📱 Features

- ✅ **Firebase Authentication** - Email/Password login
- ✅ **Real-time Messaging** - Text, Image, Video, Audio, Link messages
- ✅ **Push Notifications** - FCM integration with local notifications
- ✅ **Media Support** - Image/video capture, gallery picker, compression
- ✅ **Audio Recording** - Voice message support
- ✅ **Message Actions** - Edit, delete, reply, forward, react, pin
- ✅ **Online Status** - Real-time user presence
- ✅ **Typing Indicators** - See when others are typing
- ✅ **Read Receipts** - Message delivery and seen status
- ✅ **Direct & Group Chats** - Both conversation types supported

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.4.3)
- Firebase Project
- Android Studio / Xcode (for mobile development)
- A Firebase account

### Step 1: Firebase Project Setup

1. **Create Firebase Project**
    - Go to [Firebase Console](https://console.firebase.google.com/)
    - Click "Add project"
    - Enter project name and follow the setup wizard

2. **Enable Firebase Services**

   Enable these services in your Firebase project:

    - **Authentication**
        - Go to Authentication > Sign-in method
        - Enable "Email/Password"

    - **Firestore Database**
        - Go to Firestore Database
        - Create database in production mode
        - Start in test mode (or set up security rules)

    - **Firebase Storage**
        - Go to Storage
        - Get started with default settings

    - **Realtime Database** (for presence/status)
        - Go to Realtime Database
        - Create database

    - **Cloud Messaging** (for push notifications)
        - Already enabled by default

3. **Add Your Apps to Firebase**

   **For Android:**
    - Click "Add app" > Android icon
    - Register app with package name: `com.example.example` (or your package)
    - Download `google-services.json`
    - Place it in `android/app/google-services.json`

   **For iOS:**
    - Click "Add app" > iOS icon
    - Register app with bundle ID
    - Download `GoogleService-Info.plist`
    - Add it to `ios/Runner/GoogleService-Info.plist` in Xcode

### Step 2: Firebase Configuration Files

1. **Generate `firebase_options.dart`**

   Run the FlutterFire CLI to automatically generate configuration:

   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli

   # Generate firebase_options.dart
   flutterfire configure
   ```

   This creates `lib/firebase_options.dart` with your project configuration.

### Step 3: Push Notification Service Account Setup

This is **REQUIRED** for sending push notifications from the app.

1. **Create Service Account**

    - Go to [Firebase Console](https://console.firebase.google.com/)
    - Select your project
    - Click the gear icon ⚙️ > **Project settings**
    - Go to **Service accounts** tab
    - Click **Generate new private key**
    - Click **Generate key** - this downloads a JSON file

2. **Create `push_notification.json` File**

    - Create the secrets folder:
      ```bash
      mkdir -p assets/secrets
      ```

    - Rename the downloaded JSON file to `push_notification.json`

    - Move it to `assets/secrets/push_notification.json`

    - The file structure should look like this:
      ```json
      {
        "type": "service_account",
        "project_id": "your-project-id",
        "private_key_id": "abc123...",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQ...\n-----END PRIVATE KEY-----\n",
        "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
        "client_id": "1234567890",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/...",
        "universe_domain": "googleapis.com"
      }
      ```

3. **Update Project ID in Code**

   Open `lib/push_notification.dart` and update the project ID:

   ```dart
   static const projectId = 'YOUR_FIREBASE_PROJECT_ID'; // Change this!
   ```

### Step 4: Firestore Security Rules

Set up basic security rules for testing:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Rooms collection
    match /rooms/{roomId} {
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.participants;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       request.auth.uid in resource.data.participants;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow update: if request.auth != null;
        allow delete: if request.auth != null;
      }
      
      // Typing subcollection
      match /typing/{userId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

### Step 5: Realtime Database Rules

For user presence/status tracking:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": true,
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

### Step 6: Storage Rules

For media uploads:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /chats/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Step 7: Install Dependencies

```bash
cd example
flutter pub get
```

### Step 8: Platform-Specific Setup

**Android:**

1. Ensure `android/app/build.gradle` has:
   ```gradle
   android {
       compileSdk 34
       
       defaultConfig {
           minSdk 21
           targetSdk 34
       }
   }
   ```

2. Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   ```

**iOS:**

1. Add to `ios/Runner/Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need camera access to send photos</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>We need microphone access to record audio messages</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>We need photo library access to send images</string>
   ```

2. Minimum iOS version in `ios/Podfile`:
   ```ruby
   platform :ios, '13.0'
   ```

### Step 9: Run the App

```bash
# Run on connected device/emulator
flutter run

# Or specify platform
flutter run -d android
flutter run -d ios
```

## 📂 Project Structure

```
example/
├── lib/
│   ├── auth/
│   │   └── user.dart                    # User helper utilities
│   ├── pages/
│   │   ├── auth.dart                    # Login/Register page
│   │   ├── inbox_page.dart              # Chat list page
│   │   ├── chat_page.dart               # Chat conversation page
│   │   ├── user_list_page.dart          # User selection page
│   │   ├── forward_message_page.dart    # Message forwarding
│   │   ├── image_preview_page.dart      # Image preview before send
│   │   └── video_preview_page.dart      # Video preview before send
│   ├── services/
│   │   ├── message.dart                 # Message delegate implementation
│   │   ├── room.dart                    # Room delegate implementation
│   │   ├── profile.dart                 # Profile delegate implementation
│   │   ├── status.dart                  # Status delegate implementation
│   │   ├── typing.dart                  # Typing delegate implementation
│   │   ├── notification.dart            # Notification delegate
│   │   └── normalizer.dart              # Data normalizer
│   ├── widgets/
│   │   ├── chatting_appbar.dart         # Custom chat app bar
│   │   ├── chatting_input.dart          # Message input field
│   │   ├── message_*.dart               # Message type renderers
│   │   ├── inbox_*.dart                 # Inbox item widgets
│   │   └── ...                          # Other UI widgets
│   ├── firebase_options.dart            # Firebase configuration
│   ├── push_notification.dart           # FCM push notification service
│   ├── notification.dart                # Local notification handler
│   └── main.dart                        # App entry point
├── assets/
│   └── secrets/
│       └── push_notification.json       # Firebase service account key
├── android/
│   └── app/
│       └── google-services.json         # Android Firebase config
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist     # iOS Firebase config
└── pubspec.yaml
```

## 🔧 Configuration Checklist

Before running the app, ensure you have:

- [ ] Created Firebase project
- [ ] Enabled Authentication (Email/Password)
- [ ] Created Firestore Database
- [ ] Created Storage bucket
- [ ] Created Realtime Database
- [ ] Downloaded `google-services.json` (Android)
- [ ] Downloaded `GoogleService-Info.plist` (iOS)
- [ ] Generated `firebase_options.dart` using FlutterFire CLI
- [ ] Created service account and downloaded JSON
- [ ] Placed `push_notification.json` in `assets/secrets/`
- [ ] Updated project ID in `push_notification.dart`
- [ ] Set up Firestore security rules
- [ ] Set up Storage security rules
- [ ] Set up Realtime Database rules
- [ ] Added platform permissions

## 📝 How to Use

### Creating an Account

1. Launch the app
2. Click "Register"
3. Enter email and password
4. Create account

### Starting a Chat

1. Click the "+" button on inbox screen
2. Select a user from the list
3. Start chatting!

### Sending Messages

- **Text**: Type and press send
- **Image**: Click camera icon > Choose from gallery or take photo
- **Video**: Click camera icon > Choose video or record
- **Audio**: Hold the mic button to record voice message
- **Link**: Paste a URL in the text field

### Message Actions

- **Long press** on a message to see options:
    - Reply
    - Forward
    - Delete
    - Delete for me
    - Copy text
    - React with emoji
    - Pin/Unpin

## 🎨 Customization

### Changing Theme

Edit `main.dart`:

```dart
theme: ThemeData(
  primarySwatch: Colors.blue, // Change to your color
  scaffoldBackgroundColor: Colors.white,
  // ... customize more
),
```

### Custom Message Bubbles

Edit widgets in `lib/widgets/` folder to customize appearance.

### Custom UI Builders

All UI components are configurable in `main.dart` under `ChatUiConfigs`:

```dart
ChatUiConfigs(
  chatAppbarBuilder: (context, profile, status, typings) {
    // Your custom app bar
  },
  textBuilder: (context, msg) {
    // Your custom text message bubble
  },
  // ... more builders
)
```

## 🐛 Troubleshooting

### Push Notifications Not Working

1. Verify `push_notification.json` is in correct location
2. Check project ID is correct in `push_notification.dart`
3. Ensure FCM is enabled in Firebase Console
4. Check service account has correct permissions

### Images Not Uploading

1. Check Storage rules allow authenticated writes
2. Verify Storage bucket is created
3. Check internet connection

### Messages Not Syncing

1. Verify Firestore rules are correct
2. Check user is authenticated
3. Ensure room participants include current user

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
cd ios && pod install && cd ..
flutter run
```

## 📚 Learn More

- [Flutter Chat Kits Documentation](../README.md)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This example app is part of Flutter Chat Kits and follows the same license.

---

**Happy Coding! 🚀**

For questions or issues, please check the main package [README](../README.md).