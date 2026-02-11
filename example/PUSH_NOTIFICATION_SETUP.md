# Firebase Push Notification Setup Guide 🔔

Complete step-by-step guide to set up push notifications for Flutter Chat Kits.

## Why Do We Need This?

The `push_notification.json` file contains credentials that allow your app to send push notifications through Firebase Cloud Messaging (FCM) from the client side.

## 📋 Prerequisites

- Firebase project created
- Firebase Console access

## 🔐 Step-by-Step Setup

### Step 1: Access Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. You should see your project dashboard

### Step 2: Navigate to Service Accounts

1. Click the **⚙️ gear icon** (Settings) next to "Project Overview"
2. Select **"Project settings"** from the dropdown
3. In the Project Settings page, click on the **"Service accounts"** tab at the top

### Step 3: Generate Private Key

1. You'll see a section titled **"Firebase Admin SDK"**
2. Below that, click the button **"Generate new private key"**
3. A popup will appear warning you about keeping the key secure
4. Click **"Generate key"** to confirm
5. A JSON file will automatically download to your computer
    - Filename format: `your-project-name-firebase-adminsdk-xxxxx-xxxxxxxxxx.json`

### Step 4: Move to Project

1. **Create the secrets folder** (if it doesn't exist):
   ```bash
   mkdir -p example/assets/secrets
   ```

2. **Rename the downloaded file** to `push_notification.json`

3. **Move it to the project**:
   ```bash
   # From your Downloads folder
   mv ~/Downloads/your-project-*-firebase-adminsdk-*.json example/assets/secrets/push_notification.json
   ```

   Or simply:
    - Copy the downloaded JSON file
    - Paste it into `example/assets/secrets/`
    - Rename it to `push_notification.json`

### Step 5: Verify File Structure

Your file should look like this:

```json
{
  "type": "service_account",
  "project_id": "your-actual-project-id",
  "private_key_id": "abc123def456...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBg...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "1234567890123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40your-project-id.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
```

**Important Fields:**
- `project_id`: Your Firebase project ID
- `private_key`: The authentication key (keep this secret!)
- `client_email`: Service account email

### Step 6: Update Code Configuration

Open `example/lib/push_notification.dart`:

```dart
class PushNotifications {
  const PushNotifications._();

  // ⬇️ CHANGE THIS LINE ⬇️
  static const projectId = 'your-actual-project-id'; // Must match the JSON file
  // ⬆️ CHANGE THIS LINE ⬆️
  
  // ... rest of the code
}
```

**Where to find your project ID:**
- It's in the `push_notification.json` file under `"project_id"`
- Or in Firebase Console → Project Settings → General → Project ID

### Step 7: Verify Setup in pubspec.yaml

Ensure the assets are included:

```yaml
flutter:
  assets:
    - assets/
    - assets/secrets/
```

### Step 8: Test the Setup

Run this code snippet to verify:

```dart
import 'package:flutter/services.dart';

Future<bool> verifyPushNotificationSetup() async {
  try {
    // Try to load the file
    final raw = await rootBundle.loadString(
      'assets/secrets/push_notification.json',
    );
    
    // Parse it
    final json = jsonDecode(raw);
    
    // Verify required fields
    if (json['project_id'] == null) {
      print('❌ Missing project_id');
      return false;
    }
    
    if (json['private_key'] == null) {
      print('❌ Missing private_key');
      return false;
    }
    
    print('✅ push_notification.json is valid!');
    print('📱 Project ID: ${json['project_id']}');
    return true;
  } catch (e) {
    print('❌ Error loading push_notification.json: $e');
    return false;
  }
}
```

## 📁 Final File Structure

```
example/
├── assets/
│   └── secrets/
│       └── push_notification.json  ← Your service account key
├── lib/
│   ├── push_notification.dart      ← Update projectId here
│   └── ...
└── pubspec.yaml                    ← Ensure assets are declared
```

## 🔒 Security Best Practices

### ✅ DO:
- ✅ Keep `push_notification.json` secret
- ✅ Add `assets/secrets/` to `.gitignore`
- ✅ Never commit this file to public repositories
- ✅ Use environment variables in production
- ✅ Rotate keys if compromised

### ❌ DON'T:
- ❌ Share the JSON file publicly
- ❌ Commit it to version control
- ❌ Email or message it unencrypted
- ❌ Use the same key across multiple apps

### Adding to .gitignore

Create/edit `.gitignore` in your project root:

```gitignore
# Firebase secrets
assets/secrets/push_notification.json
**/secrets/*.json

# Firebase config (if you want to keep private)
# Uncomment if needed:
# android/app/google-services.json
# ios/Runner/GoogleService-Info.plist
```

## 🧪 Testing Push Notifications

### Manual Test

1. Run the app on a real device (emulator won't receive notifications)
2. Login and go to a chat
3. Send a message from another account
4. You should receive a notification

### Debug Mode

Add logging to see if notifications are being sent:

```dart
// In push_notification.dart
static Future<Map<String, dynamic>?> send({...}) async {
  print('🔔 Attempting to send notification...');
  final accessToken = await serviceToken();
  print('🔑 Token obtained: ${accessToken != null}');
  
  // ... rest of the code
  
  final response = await http.post(...);
  print('📤 Response: ${response.statusCode}');
  print('📝 Body: ${response.body}');
  
  return response;
}
```

## ❓ Troubleshooting

### Error: "Unable to load asset"

**Problem:** App can't find `push_notification.json`

**Solution:**
1. Verify file is in `assets/secrets/push_notification.json`
2. Check `pubspec.yaml` includes assets
3. Run `flutter clean` and `flutter pub get`
4. Rebuild the app

### Error: "Invalid credentials"

**Problem:** File content is wrong or corrupted

**Solution:**
1. Re-download from Firebase Console
2. Ensure it's valid JSON (use a JSON validator)
3. Check all required fields are present
4. Verify no extra spaces or characters

### Error: "Project not found"

**Problem:** Project ID mismatch

**Solution:**
1. Check `project_id` in JSON matches `projectId` in code
2. Verify it matches your Firebase project
3. Check spelling and case-sensitivity

### Notifications Not Received

**Problem:** Setup is correct but notifications don't arrive

**Solution:**
1. Test on a real device (not emulator)
2. Check internet connection
3. Verify FCM token is being generated
4. Check Firebase Cloud Messaging is enabled
5. Review device notification permissions
6. Check app is in background (notifications only show when app is backgrounded)

## 📚 Additional Resources

- [Firebase Admin SDK Setup](https://firebase.google.com/docs/admin/setup)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Service Accounts](https://cloud.google.com/iam/docs/service-accounts)

## 🆘 Still Having Issues?

1. Double-check all steps were followed exactly
2. Verify Firebase project is active
3. Check service account has correct permissions
4. Try regenerating the key
5. Review Firebase Console logs for errors

## ✅ Success Checklist

- [ ] Service account key downloaded from Firebase
- [ ] File renamed to `push_notification.json`
- [ ] File placed in `assets/secrets/`
- [ ] Project ID updated in `push_notification.dart`
- [ ] Assets declared in `pubspec.yaml`
- [ ] File added to `.gitignore`
- [ ] App rebuilt and tested
- [ ] Notifications working on real device

---

**Now you're ready to send push notifications! 🚀**