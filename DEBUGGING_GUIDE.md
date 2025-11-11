# Debugging Shared Location Tracking

## Current Issue
Users who have granted location access are not appearing on the map, and historical location data is not showing up.

## Debug Logging Added

I've added extensive debug logging throughout the codebase to help identify where the issue is occurring.

### 1. Run the App with Debug Output

```powershell
# Navigate to project directory
cd d:\MCA\Flutter\tracker

# Run with verbose logging
flutter run -v
```

### 2. What to Look For in Logs

#### A. When App Starts (Location Provider Initialization)
```
Starting to listen for shared locations for user: <your-uid>
```

#### B. When Shared Users Stream Activates
```
Creating stream for users I can view: <your-uid>
My user canViewUsers: [<list-of-uids>]
Stream: Retrieved X shared users
```
- **If X = 0**: The canViewUsers array is empty in Firestore
- **If "My user is null"**: User document doesn't exist in Firestore

#### C. For Each Shared User
```
Processing shared user: <email>
Creating location subscription for: <email>
Creating live location stream for user: <uid>
```

#### D. When Location Updates Arrive
```
Live location snapshot for <uid> - exists: true
Live location data for <uid>: {latitude: X, longitude: Y, ...}
Parsed location for <uid>: lat=X, lng=Y, time=<timestamp>
Received location update for <email>: Found
Location: lat=X, lng=Y, timestamp=<time>
```
- **If "exists: false"**: No live_locations document exists for that user
- **If data is null**: Document exists but is empty

#### E. When Your Location is Updated
```
Updating live location for user: <your-uid>
Location: lat=X, lng=Y, time=<timestamp>
Live location updated successfully for <your-uid>
```

## Common Problems and Solutions

### Problem 1: "canViewUsers array is empty"
**Cause**: Permissions not properly set in Firestore

**Solution**:
1. Open Firebase Console → Firestore Database
2. Navigate to `users` collection
3. Find your user document (by UID)
4. Check if `canViewUsers` field exists and contains the other user's UID
5. If missing, add it manually:
   ```json
   {
     "canViewUsers": ["<other-user-uid>"]
   }
   ```

### Problem 2: "Live location document does not exist"
**Cause**: The other user hasn't started tracking yet, or tracking isn't updating Firestore

**Solution**:
1. Have the other user start tracking (tap Start Tracking button)
2. Wait 30-60 seconds
3. Check Firebase Console → Firestore → `live_locations` collection
4. Look for document with ID = other user's UID
5. If missing, check next section

### Problem 3: Live Location Not Being Written
**Cause**: Background service or foreground tracking not updating Firestore

**Look for these logs**:
```
Updating live location for user: <uid>
Live location updated successfully for <uid>
```

**If these don't appear**:
- Check location permissions are granted
- Check network connectivity
- Check Firebase is properly initialized
- Try force-stopping and restarting the app

### Problem 4: "Error updating live location: [FirebaseException]"
**Cause**: Firestore security rules blocking writes

**Solution**:
1. Open Firebase Console → Firestore Database → Rules
2. Apply the rules from `FIRESTORE_SECURITY_RULES.md`
3. Click "Publish"

Test rules (TEMPORARY - for debugging only):
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

### Problem 5: Historical Data Not Showing
**Cause**: Locations not syncing from SQLite to Firestore

**Look for these logs**:
```
Syncing X locations to Firestore...
Batch X: Syncing Y locations
```

**If these don't appear**:
- Open History Screen
- Tap "Sync Now" button
- Check logs for "Starting sync..."
- Check Firebase Console → `locations` collection for documents

## Manual Firestore Verification

### Check Your User Document
1. Firebase Console → Firestore → `users` → `<your-uid>`
2. Should have:
   ```json
   {
     "uid": "your-uid",
     "email": "your@email.com",
     "displayName": "Your Name",
     "canViewUsers": ["other-user-uid"],
     "sharedWithUsers": ["other-user-uid"],
     "lastUpdated": <timestamp>
   }
   ```

### Check Other User's User Document
1. Firebase Console → Firestore → `users` → `<other-uid>`
2. Should have:
   ```json
   {
     "uid": "other-uid",
     "email": "other@email.com",
     "displayName": "Other Name",
     "canViewUsers": ["your-uid"],
     "sharedWithUsers": ["your-uid"],
     "lastUpdated": <timestamp>
   }
   ```

### Check Live Locations Collection
1. Firebase Console → Firestore → `live_locations`
2. Should have document with ID = user's UID
3. Document should contain:
   ```json
   {
     "userId": "uid",
     "latitude": 12.345,
     "longitude": 67.890,
     "accuracy": 10.0,
     "speed": 0.0,
     "timestamp": <recent-timestamp>,
     "isSynced": true
   }
   ```

### Check Locations Collection (History)
1. Firebase Console → Firestore → `locations`
2. Query: `userId == <uid>` and `timestamp > <today>`
3. Should see multiple location documents
4. If empty, locations not syncing from SQLite

## Step-by-Step Testing Procedure

### Test with 2 Devices/Accounts

**Device A (Alice):**
1. Login as alice@test.com
2. Go to "Shared Locations" tab
3. Go to "Sharing With" tab
4. Search for bob@test.com
5. Tap "Grant Access"
6. Go back to Map Screen
7. Tap "Start Tracking"
8. Wait 1 minute

**Device B (Bob):**
1. Login as bob@test.com
2. Go to "Shared Locations" tab
3. Go to "Sharing With" tab
4. Search for alice@test.com
5. Tap "Grant Access"
6. Go to "Shared Locations" tab
7. Go to "I Can View" tab
8. Should see Alice with green dot (online) - **If not, CHECK LOGS**
9. Go back to Map Screen
10. Should see red marker with "Alice" label - **If not, CHECK LOGS**
11. Tap the red marker → Should open Alice's location in Google Maps

**Check Logs on Both Devices:**
- Alice: Should see "Updating live location" every 30-60 seconds
- Bob: Should see "Received location update for alice@test.com: Found"

## Firestore Security Rules

Copy these rules to Firebase Console:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Location history - users can write their own, read those shared with them
    match /locations/{locationId} {
      allow write: if request.auth.uid == resource.data.userId || 
                     request.auth.uid == request.resource.data.userId;
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.userId ||
        exists(/databases/$(database)/documents/users/$(resource.data.userId)) &&
        request.auth.uid in get(/databases/$(database)/documents/users/$(resource.data.userId)).data.sharedWithUsers
      );
    }
    
    // Live locations - similar access rules
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

## Quick Verification Checklist

- [ ] Flutter app runs without errors
- [ ] Can see debug logs in terminal
- [ ] User document exists in Firestore with correct fields
- [ ] canViewUsers array contains other user's UID
- [ ] Other user's canViewUsers array contains your UID
- [ ] Start Tracking button works
- [ ] "Updating live location" appears in logs every 30-60 seconds
- [ ] live_locations/{uid} document exists in Firestore
- [ ] live_locations document has recent timestamp (< 2 minutes)
- [ ] "Received location update" appears in other user's logs
- [ ] Red marker appears on map for shared user
- [ ] Firestore security rules are published
- [ ] Network connectivity is stable
- [ ] Location permissions granted (Allow all the time)

## Next Steps After Reviewing Logs

1. **Run the app** with `flutter run -v`
2. **Copy all log output** related to location tracking
3. **Check Firebase Console** for data in:
   - users collection
   - live_locations collection
   - locations collection
4. **Share findings**: Note which logs appear and which don't
5. **Focus on the first missing log** in the sequence above

## Emergency Reset (If All Else Fails)

```powershell
# Stop app
flutter clean

# Delete build folder
Remove-Item -Recurse -Force build/

# Get dependencies
flutter pub get

# Run again
flutter run -v
```

Then:
1. Logout from app
2. Login again
3. Re-grant location permissions
4. Start tracking again
5. Check logs from beginning
