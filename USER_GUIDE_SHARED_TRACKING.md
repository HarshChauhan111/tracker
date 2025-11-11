# User Guide: Tracking Other Users' Locations

## Overview
You can now view real-time locations of users who have granted you access, and grant access to others to view your location.

## How to Track Someone Else's Location

### Step 1: They Need to Grant You Access
The other person must:
1. Open their app and tap the **People icon** (👥) in the top toolbar
2. Go to the **"Sharing With"** tab
3. Search for you by your email address
4. Tap **"Grant Access"** button next to your name

### Step 2: View Their Location
Once they grant you access:
1. You'll automatically see their location marker on the map
   - **Blue marker with "Me"** = Your location
   - **Red marker with their name** = Their location
2. Tap any marker to open it in Google Maps for navigation

### Step 3: Check Who Can See Your Location
To see users tracking you:
1. Tap the **People icon** (👥) in the toolbar
2. Go to **"I Can View"** tab
3. You'll see:
   - List of users whose locations you can view
   - Green dot = Currently tracking/online
   - Grey dot = Location unavailable
   - "Last seen" time for each user

## How to Share Your Location with Others

### Grant Access to Someone
1. Tap the **People icon** (👥) in the toolbar
2. Stay on the **"Sharing With"** tab
3. Enter their email in the search box and tap **Search**
4. Find them in the results and tap **"Grant Access"**
5. They can now see your location on their map

### Revoke Access
1. Tap the **People icon** (👥) in the toolbar
2. Go to **"Sharing With"** tab
3. Scroll down to **"Currently Sharing With"** section
4. Tap the red ❌ icon next to the user
5. Confirm to revoke their access

## Features

### Real-Time Tracking
- Locations update automatically every 30 seconds
- No need to refresh - markers move live on the map
- Works in background even when app is closed

### Map Features
- **Tap markers** to open that location in Google Maps
- **Blue polyline** shows your path for today
- **Zoom/Pan** to see everyone's locations
- Uses OpenStreetMap (no API key needed)

### History Storage
Your location history is:
- **Stored locally** in SQLite database on your device
- **Synced to cloud** (Firestore) when online
- **Available offline** - view past routes anytime
- **Organized by date** - tap History (🕐) icon to browse

## Troubleshooting

### "Data not storing in history"
If your locations aren't appearing in history:

1. **Check tracking is active**:
   - Green "STOP TRACKING" button should be visible
   - You should see "Active Route" card with distance/points

2. **Check permissions**:
   - Location: "Allow all the time"
   - Notifications: Allowed
   - Battery optimization: Disabled

3. **Force sync**:
   - Go to Settings (⚙️)
   - Tap "Sync Now" button
   - Wait for "Synced successfully" message

4. **Check database**:
   - Go to History screen
   - Select today's date
   - You should see your route polyline

### "Can't see other person's location"
1. **Verify access granted**:
   - Ask them to check "Currently Sharing With" list
   - Your email should appear there

2. **Check they're tracking**:
   - They must have tracking active (green button)
   - Their app must be running or have background permission

3. **Check internet**:
   - Both devices need internet connection
   - Location data syncs through cloud

4. **Restart app**:
   - Close and reopen the app
   - Locations should appear within 30 seconds

### "Search can't find user"
- They must be registered with that exact email
- Search is case-sensitive
- They must have created account first

## Privacy & Security

### Your Location
- Only shared with users YOU explicitly grant access to
- You can revoke access anytime
- No public sharing - fully private

### Others' Locations
- You only see locations of users who granted YOU access
- Can't see who else they're sharing with
- Can't see their historical data (only live location)

### Data Storage
- Local data: Encrypted on device
- Cloud data: Firestore security rules protect access
- Location history: Only you can view your own history

## Tips

1. **Grant mutual access** - Both users grant each other access for two-way tracking
2. **Check battery optimization** - Disable for continuous tracking
3. **Keep app updated** - Check for updates regularly
4. **Use WiFi for sync** - Better battery life than mobile data
5. **Review shared users** - Periodically check who has access

## Need Help?

If you encounter issues:
1. Check this guide first
2. Go to Settings > Permissions to verify all are enabled
3. Try force sync from Settings
4. Restart the app
5. Reinstall if problems persist (data will be restored from cloud)

---

## Quick Reference

| Icon | Feature |
|------|---------|
| 👥 | Shared Locations - Manage who can track you |
| 🕐 | History - View past routes by date |
| ⚙️ | Settings - App preferences and sync |
| 🗺️ | Map - Main tracking view with all markers |

**Blue Marker** = Your location
**Red Marker** = Other users' locations
**Blue Line** = Your route today
