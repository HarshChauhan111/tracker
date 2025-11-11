# Visual UI Guide: Tracking Others' Locations

## 📱 Main Map Screen

### What You'll See:
```
┌─────────────────────────────────────┐
│ Location Tracker      👥 🕐 ⚙️     │ ← Toolbar with buttons
├─────────────────────────────────────┤
│                                     │
│       🔵 Me                         │ ← Your location (blue marker)
│         │                           │
│         │ Blue line (your path)     │
│         │                           │
│       📍 John Doe                   │ ← Shared user (red marker)
│                                     │
│                                     │
│  ┌─────────────────────────────┐  │
│  │ Active Route                 │  │ ← Route info card
│  │ Distance: 2.5 km            │  │
│  │ Points: 45                  │  │
│  │ Duration: 1h 23m            │  │
│  └─────────────────────────────┘  │
│                                     │
│         [STOP TRACKING]             │ ← Control button
└─────────────────────────────────────┘
```

**Key Elements:**
- 👥 = Shared Locations button
- 🕐 = History button  
- ⚙️ = Settings button
- 🔵 = Your location marker (blue)
- 📍 = Other users' markers (red)

---

## 👥 Shared Locations Screen

### Tab 1: "I Can View"
Shows users who are sharing their location with you.

```
┌─────────────────────────────────────┐
│ ← Shared Locations                  │
├─────────────────────────────────────┤
│   I Can View   │   Sharing With     │ ← Tabs
├─────────────────────────────────────┤
│                                     │
│  ┌────────────────────────────┐   │
│  │ 🅹 Jane Smith              🟢 │   │ ← Online (green dot)
│  │    jane@example.com         │   │
│  │    📍 Last seen: 2m ago     │   │
│  └────────────────────────────┘   │
│                                     │
│  ┌────────────────────────────┐   │
│  │ 🅴 John Doe                ⚪ │   │ ← Offline (grey dot)
│  │    john@example.com         │   │
│  │    ⭕ Location unavailable  │   │
│  └────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**Color Indicators:**
- 🟢 Green dot = Currently tracking
- ⚪ Grey dot = Offline/not tracking
- Last seen time shows how recent the location is

---

### Tab 2: "Sharing With"
Manage who can view YOUR location.

```
┌─────────────────────────────────────┐
│ ← Shared Locations                  │
├─────────────────────────────────────┤
│   I Can View   │   Sharing With     │ ← Current tab
├─────────────────────────────────────┤
│                                     │
│  Grant Access to Users              │
│  ┌──────────────────────┬────────┐ │
│  │ 🔍 Search by email... │ Search │ │ ← Search bar
│  └──────────────────────┴────────┘ │
│                                     │
│  Search Results:                    │
│  ┌────────────────────────────┐   │
│  │ 🅼 Mike Wilson              │   │
│  │    mike@example.com         │   │
│  │              [Grant Access] │   │ ← Grant button
│  └────────────────────────────┘   │
│                                     │
│  ─────────────────────────────     │
│                                     │
│  Currently Sharing With             │
│  ┌────────────────────────────┐   │
│  │ 🅹 Jane Smith           ❌  │   │ ← Revoke button
│  │    jane@example.com         │   │
│  └────────────────────────────┘   │
│                                     │
│  ┌────────────────────────────┐   │
│  │ 🅱 Bob Johnson          ❌  │   │
│  │    bob@example.com          │   │
│  └────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 🕐 History Screen

View past location data and routes.

```
┌─────────────────────────────────────┐
│ ← History                      📅   │ ← Calendar icon
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐  │
│  │ Friday, November 7, 2025     │  │ ← Date selector
│  │ 234 location points recorded │  │
│  └─────────────────────────────┘  │
│                                     │
│        (Map showing route)          │
│                                     │
│    Start ────────────────→ End     │ ← Route polyline
│                                     │
│                                     │
│  ┌─────────────────────────────┐  │
│  │  ▶️ Play Route              │  │ ← Playback button
│  └─────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## ⚙️ Settings Screen

App configuration and account management.

```
┌─────────────────────────────────────┐
│ ← Settings                          │
├─────────────────────────────────────┤
│                                     │
│  Account                            │
│  ┌─────────────────────────────┐  │
│  │ 📧 user@example.com          │  │
│  │ 👤 Display Name              │  │
│  └─────────────────────────────┘  │
│                                     │
│  Data & Sync                        │
│  ┌─────────────────────────────┐  │
│  │ [Sync Now]                   │  │ ← Force sync
│  │ Last synced: 2 mins ago      │  │
│  └─────────────────────────────┘  │
│                                     │
│  Appearance                         │
│  ⚪ Light  🔘 Dark  ⚪ System       │
│                                     │
│  Privacy                            │
│  ┌─────────────────────────────┐  │
│  │ [Manage Permissions]         │  │
│  │ [Export Data]                │  │
│  │ [Delete Account]             │  │
│  └─────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## 📋 Step-by-Step Workflow

### Scenario: You want to track your friend's location

#### Step 1: Your Friend Shares Location with You
```
Friend's Phone:
1. Open app
2. Tap 👥 (People icon)
3. Go to "Sharing With" tab
4. Search your email
5. Tap [Grant Access]
```

#### Step 2: You See Their Location
```
Your Phone:
1. Markers update automatically
2. See red marker with friend's name
3. Tap marker to open in Google Maps
```

#### Visual Flow:
```
Friend's App                Your App
    👥                         📱
     ↓                          ↓
[Grant Access]    →     [Auto-update]
     ↓                          ↓
  ✅ Done!                  📍 See them!
```

---

## 🎨 Color Code Reference

### Markers on Map:
- 🔵 **Blue** = Your location ("Me")
- 🔴 **Red** = Shared users' locations
- 🔷 **Blue Line** = Your route path today

### Status Indicators:
- 🟢 **Green** = User is tracking/online
- ⚪ **Grey** = User offline/unavailable
- ✅ **Green Check** = Successfully synced
- ⚠️ **Yellow** = Warning/attention needed
- ❌ **Red X** = Error or revoke action

### Buttons:
- 🟢 **Green Button** = "Start Tracking"
- 🔴 **Red Button** = "Stop Tracking"
- 🔵 **Blue Button** = Primary action
- ⚪ **Grey Button** = Secondary action

---

## 💡 Quick Tips

### Reading the Map:
1. **Zoom in** to see exact marker positions
2. **Tap marker** for Google Maps navigation
3. **Blue line** shows where you've been today
4. **Multiple red markers** = Multiple users sharing

### Managing Access:
- **Search is instant** - type and search
- **Revoke is immediate** - tap ❌ to remove
- **Changes sync fast** - usually within seconds
- **No limits** - share with unlimited users

### Troubleshooting Visual Cues:
- **Grey dot** = They stopped tracking or lost connection
- **No marker** = They haven't granted access yet
- **Marker not moving** = Check "Last seen" time
- **Empty "I Can View"** = No one sharing with you yet

---

## 📊 What Data You See

### About YOUR location:
✅ Your real-time position
✅ Your complete route history
✅ Your distance/duration stats
✅ Your route exports

### About OTHERS' locations:
✅ Their current position only
✅ Last update timestamp
✅ Online/offline status
❌ NOT their history
❌ NOT their stats
❌ NOT who else they share with

**Privacy Protected:** You only see what they explicitly share!

---

## 🚀 Getting Started Checklist

To start tracking others:
- [ ] Both users registered in app
- [ ] Both users granted location permission
- [ ] Friend granted you access via "Sharing With" tab
- [ ] Friend has tracking active (green button)
- [ ] Both devices have internet connection
- [ ] Check map for red marker with their name

If all checked and still not working → Check USER_GUIDE_SHARED_TRACKING.md troubleshooting section!
