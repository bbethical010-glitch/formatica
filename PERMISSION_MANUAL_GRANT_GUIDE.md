# Manual Permission Grant Guide - Android 15

## Problem
The app is showing "Permission denied, errno = 13" error even after the fix was applied.

## Why This Happens
- Android 15 (your device) has strict permission controls
- The `MANAGE_EXTERNAL_STORAGE` permission requires manual approval in Settings
- The permission dialog may not appear automatically on first launch

## Solution: Grant Permissions Manually

### Step-by-Step Instructions

1. **Open Android Settings**
   - Swipe down from top → Tap gear icon ⚙️
   - OR: Open Settings app from app drawer

2. **Go to Apps**
   - Tap "Apps" or "Apps & notifications"
   - Tap "See all apps" or "App info"

3. **Find Formatica**
   - Scroll down and tap "Formatica"
   - OR: Use search bar at top and type "Formatica"

4. **Open Permissions**
   - Tap "Permissions" or "App permissions"

5. **Grant Storage/Files Permission**
   - Look for one of these options:
     - **"Files and media"** → Tap → Select "Allow management of all files"
     - **"Photos and videos"** → Tap → Select "Allow all"
     - **"Music and audio"** → Tap → Select "Allow all"
     - **"Storage"** → Tap → Select "Allow"
   
   **For Android 15, you need:**
   - ✅ "Allow management of all files" (most important)
   - ✅ "Allow all" for Photos/Videos/Media

6. **Verify Permissions**
   - You should see:
     - Files and media: **Allowed**
     - Photos and videos: **Allowed**
     - Music and audio: **Allowed**

7. **Force Stop and Restart App**
   - Go back to Formatica app info page
   - Tap "Force stop"
   - Reopen Formatica from app drawer

8. **Test Document Conversion**
   - Open "Convert Document"
   - Select your DOCX file
   - Choose PDF format
   - Tap "Convert Now"
   - File should save successfully! ✅

## Alternative: Grant via ADB (Developer Method)

If you have ADB set up, you can grant permissions via command line:

```bash
# Grant MANAGE_EXTERNAL_STORAGE
adb shell appops set com.formatica.formatica_mobile MANAGE_EXTERNAL_STORAGE allow

# Grant storage permission
adb shell pm grant com.formatica.formatica_mobile android.permission.WRITE_EXTERNAL_STORAGE
adb shell pm grant com.formatica.formatica_mobile android.permission.READ_EXTERNAL_STORAGE

# Grant media permissions (Android 13+)
adb shell pm grant com.formatica.formatica_mobile android.permission.READ_MEDIA_IMAGES
adb shell pm grant com.formatica.formatica_mobile android.permission.READ_MEDIA_VIDEO
adb shell pm grant com.formatica.formatica_mobile android.permission.READ_MEDIA_AUDIO

# Force stop app
adb shell am force-stop com.formatica.formatica_mobile
```

## What Changed in This Update

1. **Better Permission Detection**: Removed Android version detection logic
2. **Always Request MANAGE_EXTERNAL_STORAGE**: Works on Android 11+
3. **Detailed Logging**: Shows permission status in logs
4. **Clear Error Messages**: Tells user exactly what to do if permission is denied
5. **Fallback to Storage Permission**: If MANAGE_EXTERNAL_STORAGE fails

## Debug Logs to Check

If it still doesn't work, check the logs:

```bash
adb logcat | Select-String "FileService"
```

You should see:
```
FileService: Checking storage permissions...
FileService: MANAGE_EXTERNAL_STORAGE status: PermissionStatus.granted
FileService: Storage permission granted
```

OR if permission is denied:
```
FileService: MANAGE_EXTERNAL_STORAGE status: PermissionStatus.denied
FileService: Requesting MANAGE_EXTERNAL_STORAGE permission
```

## Expected Behavior After Granting Permissions

1. **First conversion**: No permission dialog (already granted manually)
2. **File saves**: To `/storage/emulated/0/Download/Formatica/Documents/`
3. **Success message**: "Document converted successfully"
4. **Buttons appear**: "Open File" and "Show in Folder"

## If Still Not Working

1. **Uninstall and reinstall**:
   ```bash
   adb uninstall com.formatica.formatica_mobile
   adb install build\app\outputs\flutter-apk\app-debug.apk
   ```

2. **Clear app data**:
   - Settings → Apps → Formatica → Storage & cache → Clear storage

3. **Check Android version**:
   ```bash
   adb shell getprop ro.build.version.release
   ```
   Should show: 15

4. **Check SDK version**:
   ```bash
   adb shell getprop ro.build.version.sdk
   ```
   Should show: 36

## Quick Checklist

- [ ] App is force-stopped after permission changes
- [ ] "Files and media" permission set to "Allow management of all files"
- [ ] "Photos and videos" permission set to "Allow all"
- [ ] "Music and audio" permission set to "Allow all"
- [ ] App is reopened after granting permissions
- [ ] Document conversion is tested with a simple DOCX file

---

**After following these steps, the permission error should be resolved and document conversion will work!** ✅
