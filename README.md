# Location Tracker - Real-Time Location Tracking App

A comprehensive Flutter application for real-time location tracking with background support, Firebase integration, and location sharing capabilities.

## Features

### Core Features
- **Real-time Location Tracking**: Track your location continuously throughout the day
- **Background Tracking**: Continue tracking even when the app is closed or in the background
- **Firebase Authentication**: Secure email/password authentication
- **Cloud Sync**: Automatic synchronization of location data to Firebase Firestore
- **Offline Support**: Local SQLite storage with automatic sync when online
- **Location Sharing**: Grant or revoke access to your location for specific users
- **Route History**: View past routes with date selection and playback animation
- **Google Maps Integration**: Visual representation of your location and routes

### Advanced Features
- **Route Playback**: Animate through your historical routes
- **Location Permissions Management**: Control who can see your location
- **Theme Support**: Light, Dark, and System themes
- **Route Export**: Export routes as CSV or JSON files
- **Geofencing**: Set up geofence alerts (service implemented)
- **Battery Optimization Handling**: Prompts for unrestricted battery usage

## Setup Instructions

### Prerequisites
1. Flutter SDK (3.9.2 or higher)
2. Firebase project with Authentication and Firestore enabled

### Firebase Setup
1. Add `google-services.json` to `android/app/`
2. Enable Email/Password authentication in Firebase Console
3. Create Firestore database

### Google Maps API Key
Add your API key to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### Installation
```bash
flutter pub get
flutter run
```

## Usage

1. **Register/Login** with email and password
2. **Grant Permissions** (location always allow)
3. **Start Tracking** on the map screen
4. **View History** to see past routes
5. **Manage Permissions** in settings to share location

## Architecture
- **Models**: Data structures
- **Services**: Business logic (Database, Firebase, Location, Sync)
- **Providers**: State management
- **Screens**: UI components
- **Utils**: Helper functions

## Key Technologies
- Flutter & Dart
- Firebase (Auth, Firestore)
- SQLite (Local storage)
- Google Maps
- Background Location Tracking
- Provider (State Management)

---
**Built with Flutter 🚀**
