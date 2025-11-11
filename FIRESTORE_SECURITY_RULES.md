# Firestore Security Rules for Location Tracker

## Required Security Rules

Add these rules to your Firestore Security Rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if requesting user is the owner
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Helper function to check if user has permission to view another user's data
    function canViewUser(userId) {
      return isAuthenticated() && (
        // User can view their own data
        request.auth.uid == userId ||
        // Or user has been granted access
        exists(/databases/$(database)/documents/users/$(userId)) &&
        request.auth.uid in get(/databases/$(database)/documents/users/$(userId)).data.sharedWithUsers
      );
    }
    
    // Users collection
    match /users/{userId} {
      // Anyone authenticated can read any user (for search)
      allow read: if isAuthenticated();
      
      // Only the owner can create/update their own user document
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      
      // Only the owner can delete their own user document
      allow delete: if isOwner(userId);
    }
    
    // Locations collection (history)
    match /locations/{locationId} {
      // Only owner can write their locations
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      
      // Can read if you're the owner OR if owner has shared with you
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid ||
        (exists(/databases/$(database)/documents/users/$(resource.data.userId)) &&
         request.auth.uid in get(/databases/$(database)/documents/users/$(resource.data.userId)).data.sharedWithUsers)
      );
      
      // Only owner can update/delete their locations
      allow update, delete: if isAuthenticated() && 
                               resource.data.userId == request.auth.uid;
    }
    
    // Live locations collection (real-time tracking)
    match /live_locations/{userId} {
      // Only the owner can write their live location
      allow create, update: if isOwner(userId);
      
      // Can read if you're the owner OR if owner has shared with you
      allow read: if isAuthenticated() && (
        request.auth.uid == userId ||
        (exists(/databases/$(database)/documents/users/$(userId)) &&
         request.auth.uid in get(/databases/$(database)/documents/users/$(userId)).data.sharedWithUsers)
      );
      
      // Only owner can delete their live location
      allow delete: if isOwner(userId);
    }
  }
}
```

## How to Apply These Rules

1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project
3. Click on **Firestore Database** in the left sidebar
4. Click on the **Rules** tab
5. Replace the existing rules with the rules above
6. Click **Publish**

## What These Rules Do

### Users Collection
- ✅ Any authenticated user can read any user (needed for search functionality)
- ✅ Users can only modify their own profile
- ✅ Prevents unauthorized access to user data

### Locations Collection (History)
- ✅ Users can only write their own locations
- ✅ Users can read their own location history
- ✅ Users can read locations of users who granted them access
- ✅ Prevents unauthorized location data access

### Live Locations Collection (Real-time)
- ✅ Users can only update their own live location
- ✅ Users can view their own live location
- ✅ Users can view live locations of users who granted them access via `sharedWithUsers` array
- ✅ Prevents unauthorized real-time tracking

## Testing the Rules

After applying the rules, test in Firebase Console:

### Test 1: User can write their own live location
```
Operation: create
Path: /live_locations/USER_UID_HERE
Auth: Authenticated as USER_UID_HERE
Data: { userId: "USER_UID_HERE", latitude: 0, longitude: 0, timestamp: now }
Expected: ✅ Allow
```

### Test 2: User cannot write another user's live location
```
Operation: create
Path: /live_locations/OTHER_USER_UID
Auth: Authenticated as USER_UID_HERE
Data: { userId: "OTHER_USER_UID", latitude: 0, longitude: 0 }
Expected: ❌ Deny
```

### Test 3: User can read shared user's live location
```
Operation: read
Path: /live_locations/SHARED_USER_UID
Auth: Authenticated as USER_UID_HERE
Precondition: users/SHARED_USER_UID has sharedWithUsers containing USER_UID_HERE
Expected: ✅ Allow
```

### Test 4: User cannot read non-shared user's live location
```
Operation: read
Path: /live_locations/OTHER_USER_UID
Auth: Authenticated as USER_UID_HERE
Precondition: users/OTHER_USER_UID does NOT have sharedWithUsers containing USER_UID_HERE
Expected: ❌ Deny
```

## Important Notes

⚠️ **Before Publishing:**
- Make sure you've backed up your existing rules
- Test the rules in the Firebase Console simulator
- Deploy during low-traffic time if possible

✅ **After Publishing:**
- Monitor Firestore usage in Firebase Console
- Check for any denied requests in the logs
- Test the app to ensure everything works

🔒 **Security Best Practices:**
- These rules are production-ready and secure
- They prevent unauthorized access to location data
- They allow proper data sharing based on user permissions
- They protect user privacy

## Troubleshooting

If you get permission errors after applying these rules:

1. **Check authentication**: Make sure users are logged in
2. **Check sharedWithUsers array**: Verify it's properly set when granting access
3. **Check userId field**: Ensure it matches the authenticated user's UID
4. **Check Firestore logs**: Firebase Console > Firestore > Usage tab

## Additional Security Considerations

For production apps, consider adding:
- Rate limiting on write operations
- Data validation (check required fields)
- Maximum document size limits
- Timestamp validation to prevent old data injection
