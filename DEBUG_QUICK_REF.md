# Quick Debug Reference Card

## 🚀 Start Debugging

```powershell
cd d:\MCA\Flutter\tracker
flutter run -v
```

## 🔍 In-App Debug Tool

**Settings → Firestore Debug → Run Tests**

Look for:
- ❌ = Problem found
- ✅ = Working correctly
- ⚠️ = Potential issue

## 📊 Key Log Messages to Watch

### ✅ Good Signs (These should appear)
```
Starting to listen for shared locations for user: <uid>
My user canViewUsers: [<uid1>, <uid2>]
Stream: Retrieved 2 shared users
Updating live location for user: <uid>
Live location updated successfully
Received location update for user@email.com: Found
Location: lat=12.345, lng=67.890
```

### ❌ Bad Signs (Problems!)
```
canViewUsers array is empty
Stream: Retrieved 0 shared users
Live location document does NOT exist
Error updating live location: [FirebaseException]
Permission denied
```

## 🔧 Quick Fixes

### Fix 1: No Shared Users Showing
```
1. Open app → Shared Locations → Sharing With
2. Search for other user's email
3. Tap "Grant Access"
4. Ask other user to do the same for you
5. Check "I Can View" tab - should see each other
```

### Fix 2: Live Location Not Updating
```
1. Check location permission: "Allow all the time"
2. Stop tracking
3. Force close app
4. Reopen app
5. Start tracking again
6. Wait 60 seconds
7. Check logs for "Updating live location"
```

### Fix 3: Permission Denied Errors
```
1. Open Firebase Console
2. Firestore Database → Rules tab
3. Copy rules from TROUBLESHOOTING.md (Problem 1)
4. Click "Publish"
5. Restart app
```

### Fix 4: Stale Data (Old Timestamps)
```
1. Stop tracking on tracking device
2. Start tracking again
3. Keep app in foreground for 2 minutes
4. Check Firebase Console → live_locations
5. Timestamp should be < 2 minutes old
```

## 🧪 Firebase Console Checks

**🌐 https://console.firebase.google.com/**

### Check 1: User Document
```
Firestore → users → <your-uid>
Should have:
  - email: "your@email.com"
  - canViewUsers: ["other-uid"]
  - sharedWithUsers: ["other-uid"]
```

### Check 2: Live Location
```
Firestore → live_locations → <user-uid>
Should have:
  - latitude: 12.345
  - longitude: 67.890
  - timestamp: <within last 5 minutes>
```

### Check 3: Historical Locations
```
Firestore → locations
Filter: userId == "<your-uid>"
Filter: timestamp > <today>
Should see: Multiple documents
```

## 📱 Two-Device Testing

### Setup (5 minutes)
1. **Device A & B**: Grant each other access (Shared Locations)
2. **Device A**: Start tracking
3. **Device B**: Wait 60 seconds, check map for red marker

### If Red Marker Doesn't Appear on Device B:

**On Device A (tracking):**
```
flutter run -v
Look for: "Updating live location" (every 30-60s)
```

**On Device B (viewing):**
```
flutter run -v
Look for: "Received location update for <email>: Found"
Settings → Firestore Debug → Run Tests
Look for: ✅ next to shared user's name
```

**In Firebase Console:**
```
live_locations → <device-a-uid>
Check: timestamp is recent (< 2 min)
Check: latitude/longitude are not 0
```

## 🆘 Emergency Reset

```powershell
flutter clean
Remove-Item -Recurse -Force build/
flutter pub get
flutter run -v

Then:
1. Logout from app
2. Login again
3. Re-grant location permissions ("Allow all the time")
4. Re-grant shared access (both directions)
5. Start tracking
6. Wait 2 minutes
7. Check logs and Firebase Console
```

## 📋 Debug Checklist

Before reporting:
- [ ] Ran with `flutter run -v`
- [ ] Used Firestore Debug screen
- [ ] Checked Firebase Console for data
- [ ] Verified security rules published
- [ ] Location permission: "Allow all the time"
- [ ] Both users granted each other access
- [ ] Tracking is started (tapped button)
- [ ] Waited at least 60 seconds
- [ ] Checked live_locations timestamp
- [ ] Network is stable

## 📄 Full Guides

- **TROUBLESHOOTING.md** - Complete troubleshooting guide
- **DEBUGGING_GUIDE.md** - Detailed debugging procedures
- **USER_GUIDE_SHARED_TRACKING.md** - Feature user guide

## 💡 Most Common Issue

**90% of cases:** Firestore security rules not published

**Fix:** Firebase Console → Firestore → Rules → Copy from TROUBLESHOOTING.md → Publish
