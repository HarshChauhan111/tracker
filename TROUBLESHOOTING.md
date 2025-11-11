# Troubleshooting Shared Location Tracking

## Issue Summary
You can see your own location on the map, but:
1. **Shared users' locations don't appear** on the map (no red markers)
2. **Historical location data isn't showing** in the History screen

## What I've Added

### 1. Extensive Debug Logging
I've added debug print statements throughout the codebase to help identify where the data flow breaks:

**Files Modified:**
- `lib/providers/location_provider.dart` - Added logging to shared location streams
- `lib/services/firestore_service.dart` - Added logging to all Firestore queries and updates
- All key methods now print their inputs, outputs, and errors

### 2. Firestore Debug Screen
**New File:** `lib/screens/firestore_debug_screen.dart`

A diagnostic tool that checks:
- ✅ User document exists with correct permissions
- ✅ Live locations are being written
- ✅ Historical locations are being saved
- ✅ Shared users' data is accessible
- ✅ Timestamps are recent (not stale data)

**How to Access:**
1. Open app
2. Go to Settings screen (gear icon)
3. Scroll down to find **"Firestore Debug"**
4. Tap it
5. Tap **"Run Tests"** button
6. Read the output to see what's working and what's not

### 3. Complete Debugging Guide
**New File:** `DEBUGGING_GUIDE.md`

Contains:
- Step-by-step testing procedures
- What to look for in logs
- Common problems and solutions
- Firestore security rules
- Manual verification steps

## How to Debug

### Step 1: Run with Debug Logs

```powershell
cd d:\MCA\Flutter\tracker
flutter run -v
```

Watch for these key log messages:

**When app starts:**
```
Starting to listen for shared locations for user: <uid>
```

**When checking permissions:**
```
My user canViewUsers: [<list of UIDs>]
Stream: Retrieved X shared users
```

**When location updates:**
```
Updating live location for user: <uid>
Location: lat=X, lng=Y, time=<timestamp>
Live location updated successfully
```

**When receiving shared locations:**
```
Received location update for <email>: Found
Location: lat=X, lng=Y, timestamp=<time>
```

### Step 2: Use Firestore Debug Screen

1. Open the app
2. Go to **Settings** → **Firestore Debug**
3. Tap **"Run Tests"**
4. Check the output for:
   - ❌ Red X marks = Problems
   - ✅ Green checkmarks = Working
   - ⚠️ Warning signs = Potential issues

### Step 3: Check Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database**
4. Check these collections:

**users collection:**
- Find your user document (by UID)
- Check `canViewUsers` array contains other user's UID
- Check other user's `sharedWithUsers` array contains your UID

**live_locations collection:**
- Should have document with ID = each user's UID
- Check timestamp is recent (< 5 minutes old)
- If missing, tracking isn't updating Firestore

**locations collection:**
- Filter by `userId` = your UID
- Filter by `timestamp` > today
- Should see multiple location documents
- If empty, locations aren't syncing from SQLite

## Most Likely Problems

### Problem 1: Firestore Security Rules Not Applied ⚠️

**Symptoms:**
- Error messages mentioning "permission denied"
- Silent failures (no data appears)

**Solution:**
1. Open Firebase Console → Firestore Database → **Rules** tab
2. Replace with these rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Location history
    match /locations/{locationId} {
      allow write: if request.auth.uid == resource.data.userId || 
                     request.auth.uid == request.resource.data.userId;
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.userId ||
        exists(/databases/$(database)/documents/users/$(resource.data.userId)) &&
        request.auth.uid in get(/databases/$(database)/documents/users/$(resource.data.userId)).data.sharedWithUsers
      );
    }
    
    // Live locations
    match /live_locations/{userId} {
      allow write: if request.auth.uid == userId;
      allow read: if request.auth != null && (
        request.auth.uid == userId ||
        exists(/databases/$(database)/documents/users/$(userId)) &&
        request.auth.uid in get(/databases/$(database)/documents/users/$(userId)).data.sharedWithUsers
      );
    }
  }
}
```

3. Click **"Publish"**
4. Restart the app

**Quick Test (TEMPORARY - Remove after debugging):**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
If this fixes the issue, the problem is definitely security rules.

### Problem 2: Permissions Not Granted in Firestore

**Symptoms:**
- Debug screen shows "canViewUsers array is empty"
- Or "Stream: Retrieved 0 shared users"

**Solution:**
Manually grant access:

1. **User A** (the person tracking):
   - Open app → Shared Locations → Sharing With tab
   - Search for User B's email
   - Tap "Grant Access"

2. **User B** (the person viewing):
   - Open app → Shared Locations → Sharing With tab
   - Search for User A's email
   - Tap "Grant Access"

3. Both users should now see each other in "I Can View" tab

### Problem 3: Tracking Not Updating Firestore

**Symptoms:**
- Debug screen shows "Live location document does NOT exist"
- Or timestamp is very old (> 5 minutes)
- Logs don't show "Updating live location"

**Possible Causes:**
- Location permissions not granted ("Allow all the time")
- Background service not running
- Network connectivity issues
- Firebase not properly initialized

**Solution:**
1. Check location permissions:
   - Settings → Permissions → Location → "Allow all the time"
   
2. Restart tracking:
   - Stop tracking (if running)
   - Force close app
   - Reopen app
   - Start tracking again
   
3. Check logs for "Updating live location" messages
   - Should appear every 30-60 seconds
   - If not appearing, check next section

### Problem 4: Background Service Not Running

**Symptoms:**
- Logs show "Updating live location" only when app is open
- Location stops updating when app is closed

**Solution:**
1. Check battery optimization settings:
   - Android: Settings → Apps → Tracker → Battery → "Unrestricted"
   
2. Check background location permission:
   - Should be "Allow all the time" not just "While using the app"

3. Verify WorkManager is working:
   - Check logs for "callbackDispatcher" or "LocationCallbackHandler"

### Problem 5: Network Connectivity Issues

**Symptoms:**
- Intermittent failures
- Works sometimes but not always
- Long delays before data appears

**Solution:**
1. Check network connection is stable
2. Try switching between WiFi and mobile data
3. Check Firebase Console shows recent data (timestamp < 2 minutes)
4. Force sync: History screen → "Sync Now" button

## Testing with 2 Accounts

### Setup (Do this first!)

**Device A:**
1. Login as user_a@example.com
2. Settings → Firestore Debug → Run Tests
3. Verify user document exists
4. Go to Shared Locations → Sharing With
5. Search for user_b@example.com
6. Tap "Grant Access"

**Device B:**
1. Login as user_b@example.com
2. Settings → Firestore Debug → Run Tests
3. Verify user document exists
4. Go to Shared Locations → Sharing With
5. Search for user_a@example.com
6. Tap "Grant Access"

### Verify Permissions

**Both devices:**
1. Go to Shared Locations → "I Can View" tab
2. Should see the other user listed
3. If not, repeat grant access steps above

### Start Tracking

**Device A:**
1. Go to Map screen
2. Tap "Start Tracking" button
3. Wait 60 seconds
4. Check Firebase Console → live_locations → should see user A's document

**Verify on Device B:**
1. Open Map screen
2. Within 30-60 seconds, should see red marker with "User A" label
3. If not, check these logs on Device B:
   ```
   Received location update for user_a@example.com: Found
   Location: lat=X, lng=Y
   ```
4. If logs don't appear, run Firestore Debug on both devices

## What Each Log Message Means

| Log Message | Meaning | If Missing |
|------------|---------|-----------|
| `Starting to listen for shared locations` | App is initializing shared tracking | Check if LocationProvider.initialize() is called |
| `My user canViewUsers: [...]` | Permissions array from Firestore | User document missing or no permissions granted |
| `Stream: Retrieved X shared users` | Found users who granted access | X should be > 0, check Firebase Console |
| `Creating location subscription for: <email>` | Starting to listen for that user's location | Previous step failed |
| `Updating live location for user: <uid>` | Your location being written to Firestore | Tracking not started or permissions denied |
| `Live location updated successfully` | Write to Firestore succeeded | Check security rules if this appears |
| `Live location snapshot for <uid> - exists: true` | Found other user's location document | Check if they are tracking |
| `Received location update for <email>: Found` | Successfully received shared user's location | Should appear every 30-60 seconds |
| `Location: lat=X, lng=Y` | The actual coordinates | Verify coordinates are not 0,0 or null |

## Quick Checklist

Before reporting an issue, verify:

- [ ] Firebase Console → Firestore → users → my user document exists
- [ ] My user document has `canViewUsers` array with other user's UID
- [ ] Other user document has `sharedWithUsers` array with my UID
- [ ] Firestore security rules are published (see Problem 1 above)
- [ ] Location permissions set to "Allow all the time"
- [ ] I ran "flutter run -v" and can see logs
- [ ] I ran Firestore Debug screen and checked output
- [ ] Other user started tracking (tapped Start Tracking button)
- [ ] I checked Firebase Console → live_locations → other user's document exists
- [ ] Timestamp in live_locations is recent (< 5 minutes)
- [ ] Network connection is stable
- [ ] Both users granted each other access (mutual)

## Next Steps

1. **Run the app** with `flutter run -v`
2. **Open Settings** → **Firestore Debug** → **Run Tests**
3. **Copy the debug output** (you can select and copy the text)
4. **Check the Firebase Console** for data in:
   - users collection
   - live_locations collection
   - locations collection
5. **Look for the first problem** in the checklist above
6. **Fix that problem** before moving to the next

## If Still Not Working

After trying everything above:

1. **Capture logs:**
   ```powershell
   flutter run -v > debug_log.txt 2>&1
   ```
   Let it run for 2-3 minutes, then share the debug_log.txt file

2. **Capture Firestore Debug output:**
   - Screenshot or copy the entire output from Firestore Debug screen

3. **Check Firebase Console:**
   - Screenshot the users collection (showing your document)
   - Screenshot the live_locations collection
   - Note if collections are empty or have data

4. **Share specific error messages:**
   - Look for lines with "Error:" or "Exception:" in logs
   - Copy the full error message including stack trace

This information will help identify the exact point where data flow breaks.
