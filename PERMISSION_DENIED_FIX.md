# Permission Denied Fix - Document Conversion Storage Error

## Problem Identified

**Error Message**:
```
PathAccessCannot open file, path = '/storage/emulated/0/Download/Formatica/Documents/In Amigos Foundation_converted.pdf'
(OS Error: Permission denied, errno = 13)
```

## Root Cause

The app was **missing storage write permissions** in the Android manifest and had no runtime permission handling for Android's storage access requirements.

**Why It Happened**:
1. Backend successfully converts document and returns PDF bytes
2. App attempts to save file to public Downloads directory
3. Android blocks the write operation due to missing permissions
4. Results in errno=13 (Permission denied) error

## Solution Applied

### 1. Android Manifest Updates
Added missing storage permissions to `AndroidManifest.xml`:

```xml
<!-- Added permissions -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

**Permission Strategy**:
- `WRITE_EXTERNAL_STORAGE` (maxSdkVersion="32"): For Android 10 and below
- `MANAGE_EXTERNAL_STORAGE`: For Android 11+ scoped storage access
- Existing `READ_EXTERNAL_STORAGE`: Already present for reading files

### 2. Runtime Permission Handling
Added `_ensureStoragePermission()` method in `file_service.dart`:

**Features**:
- Detects Android version at runtime
- Requests appropriate permissions based on Android version:
  - **Android 11+ (API 30+)**: MANAGE_EXTERNAL_STORAGE
  - **Android 10 (API 29)**: Legacy storage with scoped storage support
  - **Android 9 and below**: Standard storage permission
- Includes fallback mechanisms if primary permission is denied
- Logs permission requests for debugging

### 3. Automatic Permission Requests
Modified file saving methods to request permissions before writing:

```dart
static Future<String> saveToCategory(...) async {
  // Request storage permission before writing
  await _ensureStoragePermission();
  
  // ... save file logic
}
```

**Methods Updated**:
- `saveToCategory()` - Main file saving method
- `saveOutput()` - On-device operations (Images to PDF, etc.)

## Files Modified

1. **AndroidManifest.xml**
   - Added `WRITE_EXTERNAL_STORAGE` permission
   - Added `MANAGE_EXTERNAL_STORAGE` permission

2. **file_service.dart**
   - Added `permission_handler` import
   - Added `_ensureStoragePermission()` method
   - Updated `saveToCategory()` to request permissions
   - Updated `saveOutput()` to request permissions

## Testing Instructions

1. **Build the app**:
   ```bash
   cd formatica_mobile
   flutter build apk --debug
   ```

2. **Install on device**:
   ```bash
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```

3. **Test document conversion**:
   - Open "Convert Document" tool
   - Select a DOCX file
   - Choose PDF as output format
   - Tap "Convert Now"
   - App should prompt for storage permission (if not already granted)
   - Grant the permission
   - Conversion should complete successfully
   - File should be saved to `/storage/emulated/0/Download/Formatica/Documents/`

## Expected Behavior

### First Time Usage
1. User taps "Convert Now"
2. App requests storage permission
3. System shows permission dialog
4. User grants permission
5. Conversion proceeds
6. File saves successfully

### Subsequent Usage
1. Permission already granted
2. No permission dialog shown
3. Conversion proceeds immediately
4. File saves successfully

## Compatibility

- ✅ **Android 9 (API 28)**: Standard storage permission
- ✅ **Android 10 (API 29)**: Scoped storage with legacy support
- ✅ **Android 11+ (API 30+)**: MANAGE_EXTERNAL_STORAGE permission
- ✅ **Android 13+ (API 33+)**: Media permissions already configured

## Notes

- The app will only request permissions when actually needed (lazy permission request)
- If user denies permission, conversion will fail with a clear error message
- Permission requests are logged for debugging purposes
- The MANAGE_EXTERNAL_STORAGE permission requires declaration in Google Play Console (if publishing)

## Next Steps

After building and testing:
1. Verify document conversion works end-to-end
2. Check that files are saved to correct location
3. Verify "Show in Folder" functionality works
4. Test on different Android versions if possible
