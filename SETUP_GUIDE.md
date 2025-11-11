# Location Tracker App - Setup Guide

## Complete Setup Instructions

### 1. Firebase Configuration

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: "Location Tracker"
4. Follow the setup wizard

#### Step 2: Add Android App
1. In Firebase Console, click "Add App" → Android
2. Android package name: `com.example.tracker` (or your package name)
3. Download `google-services.json`
4. Place it in `android/app/google-services.json` (already present)

#### Step 3: Enable Authentication
1. In Firebase Console → Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method

#### Step 4: Create Firestore Database
1. In Firebase Console → Firestore Database
2. Click "Create Database"
3. Choose "Start in test mode" (for development)
4. Select your region
5. Add these security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /locations/{locationId} {
      allow read: if request.auth != null && (
        resource.data.userId == request.auth.uid ||
        get(/databases/$(database)/documents/users/$(resource.data.userId))
          .data.sharedWithUsers.hasAny([request.auth.uid])
      );
      allow write: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

### 2. Google Maps API Key

#### Step 1: Enable Google Maps API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (if building for iOS)

#### Step 2: Create API Key
1. Go to Credentials
2. Create API Key
3. Restrict the key (optional but recommended):
   - Application restrictions: Android apps
   - Add your package name and SHA-1 certificate fingerprint

#### Step 3: Add API Key to App
1. Open `android/app/src/main/AndroidManifest.xml`
2. Find this line:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
   ```
3. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key

### 3. Android Configuration

The AndroidManifest.xml is already configured with required permissions:
- Location (Fine, Coarse, Background)
- Foreground Service
- Internet
- Notifications

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Run the App

```bash
# For debug mode
flutter run

# For release mode
flutter run --release
```

## Testing the App

### First Run Checklist
1. ✅ App launches without errors
2. ✅ Registration screen appears
3. ✅ Can create account with email/password
4. ✅ Firebase Authentication creates user
5. ✅ User document created in Firestore
6. ✅ Map screen loads
7. ✅ Location permissions requested
8. ✅ Can start tracking
9. ✅ Locations saved to SQLite
10. ✅ Locations synced to Firestore

### Permission Testing
1. Grant location permissions (select "Always Allow")
2. Disable battery optimization when prompted
3. Check notification shows when tracking

### Background Tracking Test
1. Start tracking
2. Close the app
3. Wait 2-3 minutes
4. Open app
5. Check if locations were recorded

## Troubleshooting

### Firebase Connection Issues
**Problem**: Firebase not initializing
**Solution**: 
- Ensure `google-services.json` is in `android/app/`
- Check Firebase console for correct package name
- Run `flutter clean` and rebuild

### Location Not Updating
**Problem**: Location tracking stops
**Solution**:
- Check location permissions (must be "Always Allow")
- Disable battery optimization
- Check if notification is showing (indicates tracking is active)

### Google Maps Not Showing
**Problem**: Map shows gray screen
**Solution**:
- Verify Google Maps API key is correct
- Ensure Maps SDK for Android is enabled
- Check API key restrictions

### Build Errors
**Problem**: Build fails
**Solution**:
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

## App Structure

```
lib/
├── models/              # Data models
│   ├── user_model.dart
│   ├── location_model.dart
│   ├── route_model.dart
│   └── geofence_model.dart
├── services/            # Business logic
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── database_service.dart
│   ├── location_service.dart
│   ├── sync_service.dart
│   └── geofence_service.dart
├── providers/           # State management
│   ├── auth_provider.dart
│   ├── location_provider.dart
│   └── theme_provider.dart
├── screens/             # UI screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── map_screen.dart
│   ├── history_screen.dart
│   ├── settings_screen.dart
│   └── permissions_screen.dart
├── utils/               # Utilities
│   ├── permission_helper.dart
│   └── route_export_service.dart
└── main.dart           # App entry point
```

## Features Implemented

✅ Firebase Authentication (Email/Password)
✅ Real-time location tracking
✅ Background location tracking
✅ SQLite local storage
✅ Firebase Firestore sync
✅ Offline support with auto-sync
✅ Google Maps integration
✅ Route history with date picker
✅ Route playback animation
✅ Location sharing permissions
✅ User search and access control
✅ Light/Dark theme support
✅ Route export (CSV/JSON)
✅ Geofencing service
✅ Permission handling
✅ Battery optimization warnings
✅ Material 3 design
✅ Clean architecture

## Next Steps

### Optional Enhancements
1. Add real-time location sharing on map
2. Implement geofence UI and alerts
3. Add push notifications
4. Create statistics dashboard
5. Add social features
6. Implement Apple Watch support

### Production Deployment
1. Update Firestore security rules for production
2. Add proper error tracking (e.g., Sentry)
3. Add analytics (Firebase Analytics)
4. Create app icons and splash screens
5. Test on multiple devices
6. Prepare for Play Store/App Store

## Support & Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Background Locator](https://pub.dev/packages/background_locator_2)

## Important Notes

⚠️ **Battery Usage**: Background location tracking uses significant battery. Users should be informed.

⚠️ **Privacy**: Ensure users understand data collection and sharing policies.

⚠️ **Testing**: Test thoroughly on different Android versions and devices.

⚠️ **API Keys**: Never commit API keys to public repositories. Use environment variables or secure storage.

---

**Happy Tracking! 🗺️📍**
