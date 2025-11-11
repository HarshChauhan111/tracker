# Quick Start Guide - Location Tracker

## ⚡ Get Started in 5 Minutes

### Prerequisites
- Flutter SDK installed
- Android Studio or VS Code
- Android device or emulator

### Step 1: Firebase Setup (2 minutes)
1. Go to https://console.firebase.google.com/
2. Create new project: "Location Tracker"
3. Add Android app with package name: `com.example.tracker`
4. Download `google-services.json` → place in `android/app/`
5. Enable Authentication → Email/Password
6. Create Firestore Database → Start in test mode

### Step 2: Google Maps API (2 minutes)
1. Go to https://console.cloud.google.com/
2. Select your Firebase project
3. Enable "Maps SDK for Android"
4. Create API key
5. Open `android/app/src/main/AndroidManifest.xml`
6. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your key

### Step 3: Run the App (1 minute)
```bash
cd tracker
flutter pub get
flutter run
```

## ✅ First Time Use

1. **Register**: Create account with email/password
2. **Permissions**: Allow location access (select "Always")
3. **Start Tracking**: Tap the green FAB button
4. **View Map**: See your location and route
5. **History**: Tap history icon to view past routes
6. **Settings**: Manage theme and permissions

## 🎯 Key Features to Try

### Track Your Location
- Tap "Start Tracking" on map screen
- Walk around and watch your route draw
- Stats card shows distance and duration

### View History
- History icon → Select a date
- Watch route playback animation
- Export routes as CSV/JSON

### Share Location
- Settings → Manage Permissions
- Search users by email
- Grant/revoke access

### Customize
- Settings → Theme
- Choose Light, Dark, or System

## 🐛 Troubleshooting

**Map shows gray?**
→ Add Google Maps API key

**Location not updating?**
→ Grant "Always Allow" permission
→ Disable battery optimization

**Firebase error?**
→ Check google-services.json is in android/app/

**Build failed?**
```bash
flutter clean
flutter pub get
flutter run
```

## 📚 Documentation

- **README.md**: Project overview
- **SETUP_GUIDE.md**: Detailed setup
- **PROJECT_SUMMARY.md**: Complete feature list

## 🎉 You're All Set!

Your location tracking app is ready to use with:
- ✅ Real-time tracking
- ✅ Background support
- ✅ Cloud sync
- ✅ Location sharing
- ✅ Route history
- ✅ Modern UI

**Happy Tracking! 🗺️**
