import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_settings/app_settings.dart';

/// Output category determines which subfolder files go to
enum OutputCategory {
  documents, // Convert Document
  pdfs,      // Images to PDF, Merge, Split, Greyscale
  audio,     // Extract Audio
  video,     // Convert Video, Compress Video
  images,    // Convert Image
}

class FileService {
  static const _platform = MethodChannel('com.formatica/platform');
  static const _appFolderName = 'Formatica';

  /// Helper to get the Android SDK int
  static Future<int> _getAndroidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }
  
  /// Get the actual storage permission status based on the Android version
  static Future<PermissionStatus> getStoragePermissionStatus() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;
    final sdkInt = await _getAndroidSdkInt();
    
    if (sdkInt >= 33) {
      // Android 13+ requires granular media permissions
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      final audio = await Permission.audio.status;
      
      if (photos.isGranted && videos.isGranted && audio.isGranted) {
        return PermissionStatus.granted;
      } else if (photos.isPermanentlyDenied || videos.isPermanentlyDenied || audio.isPermanentlyDenied) {
        return PermissionStatus.permanentlyDenied;
      }
      return PermissionStatus.denied;
    } else if (sdkInt >= 30) {
      // Android 11-12 primarily use manageExternalStorage
      return await Permission.manageExternalStorage.status;
    } else {
      // Android 10 and below use traditional storage permission
      return await Permission.storage.status;
    }
  }
  
  /// Request all standard permissions at app startup
  static Future<void> requestInitialPermissions() async {
    if (!Platform.isAndroid) return;
    final sdkInt = await _getAndroidSdkInt();
    
    // Request notifications always as a courtesy prompt
    await Permission.notification.request();

    if (sdkInt >= 33) {
      // Prompt for photos/videos and audio exactly like the user's screenshots
      await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();
    } else if (sdkInt >= 30) {
      // Trigger manageExternalStorage request
      await Permission.manageExternalStorage.request();
    } else {
      await Permission.storage.request();
    }
  }

  /// Ensure storage permissions are granted before file operations
  /// Returns true if permission is granted, false otherwise
  static Future<bool> ensureStoragePermission(BuildContext? context) async {
    if (!Platform.isAndroid) return true;
    
    debugPrint('FileService: Checking storage permissions...');
    
    try {
      final status = await getStoragePermissionStatus();
      debugPrint('FileService: Overall storage status: $status');
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        if (context != null) {
          await _showPermissionDeniedDialog(context);
        }
        return false;
      }
      
      // Request active permissions depending on OS
      final sdkInt = await _getAndroidSdkInt();
      bool granted = false;
      
      if (sdkInt >= 33) {
        final result = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
        
        granted = result.values.every((status) => status.isGranted);
      } else if (sdkInt >= 30) {
        final res = await Permission.manageExternalStorage.request();
        granted = res.isGranted;
      } else {
        final res = await Permission.storage.request();
        granted = res.isGranted;
      }
      
      if (granted) return true;
      
      if (context != null) {
        await _showPermissionDeniedDialog(context);
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('FileService: Permission check error: $e');
      return false;
    }
  }
  
  /// Show permission denied dialog with settings shortcut
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    // Import here to avoid circular dependency
    final showSettingsDialog = (BuildContext ctx) async {
      return showDialog<bool>(
        context: ctx,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Text('Permission Required'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Storage permission was denied. The app cannot save files without this permission.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'To enable it manually:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildPermissionStep('1', 'Open Settings → Apps → Formatica'),
                _buildPermissionStep('2', 'Tap "Permissions"'),
                _buildPermissionStep('3', 'Enable "Files and media"'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'For Android 11+, select "Allow management of all files"',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
    };
    
    final shouldOpenSettings = await showSettingsDialog(context);
    if (shouldOpenSettings == true) {
      await AppSettings.openAppSettings();
    }
  }
  
  static Widget _buildPermissionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  static Future<Directory> getBaseDirectory() async {
    if (Platform.isAndroid) {
      // CRITICAL FIX: Use PUBLIC Downloads directory, not app-specific directory
      // getExternalStorageDirectories() returns app-specific paths on Android 10+
      // We need to manually construct the public Downloads path
      
      try {
        // Primary method: Manually construct /storage/emulated/0/Download/Formatica
        // This is the standard public Downloads location on Android
        final publicDownloads = Directory('/storage/emulated/0/Download');
        
        if (await publicDownloads.exists()) {
          final dir = Directory(path.join(publicDownloads.path, _appFolderName));
          debugPrint('FileService: Using public Downloads: ${dir.path}');
          
          if (!await dir.exists()) {
            await dir.create(recursive: true);
            debugPrint('FileService: Created directory ${dir.path}');
          }
          return dir;
        }
      } catch (e) {
        debugPrint('FileService: Failed to access public Downloads: $e');
      }
      
      // Fallback 1: Try alternative public storage path
      try {
        final altDownloads = Directory('/sdcard/Download');
        if (await altDownloads.exists()) {
          final dir = Directory(path.join(altDownloads.path, _appFolderName));
          debugPrint('FileService: Using alternative path: ${dir.path}');
          
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir;
        }
      } catch (e) {
        debugPrint('FileService: Failed to access alternative Downloads: $e');
      }
      
      // Fallback 2: Try external storage (may still be app-specific on Android 10+)
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final dir = Directory(path.join(externalDir.path, _appFolderName));
          debugPrint('FileService: Using external storage fallback: ${dir.path}');
          
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir;
        }
      } catch (e) {
        debugPrint('FileService: Failed to access external storage: $e');
      }
      
      // Final fallback: Application documents directory (last resort)
      final fallbackDir = await getApplicationDocumentsDirectory();
      final dir = Directory(path.join(fallbackDir.path, _appFolderName));
      debugPrint('FileService: Using app documents fallback: ${dir.path}');
      
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      // iOS/non-Android implementation
      final dir = await getApplicationDocumentsDirectory();
      final formaticaDir = Directory(path.join(dir.path, _appFolderName));
      if (!await formaticaDir.exists()) {
        await formaticaDir.create(recursive: true);
      }
      return formaticaDir;
    }
  }

  static Future<String> _getBaseDir() async => (await getBaseDirectory()).path;

  /// Get the subfolder name for a category
  static String _subfolderName(OutputCategory category) {
    switch (category) {
      case OutputCategory.documents: return 'Documents';
      case OutputCategory.pdfs:     return 'PDFs';
      case OutputCategory.audio:    return 'Audio';
      case OutputCategory.video:    return 'Videos';
      case OutputCategory.images:   return 'Images';
    }
  }

  /// Get directory path for a specific category
  static Future<String> getOutputDirectoryForCategory(OutputCategory category) async {
    final base = await _getBaseDir();
    final subfolder = _subfolderName(category);
    final dir = Directory(path.join(base, subfolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Map feature type string to output category
  static OutputCategory categoryFromFeatureType(String featureType) {
    switch (featureType) {
      case 'convert':      return OutputCategory.documents;
      case 'imagesToPdf':  return OutputCategory.pdfs;
      case 'extractAudio': return OutputCategory.audio;
      case 'convertVideo': return OutputCategory.video;
      case 'compressVideo':return OutputCategory.video;
      case 'convertImage': return OutputCategory.images;
      case 'mergePdf':     return OutputCategory.pdfs;
      case 'splitPdf':     return OutputCategory.pdfs;
      case 'greyscalePdf': return OutputCategory.pdfs;
      default:             return OutputCategory.documents;
    }
  }

  /// Save bytes to the correct category subfolder and scan for gallery
  /// Pass BuildContext for permission dialogs, or null for silent mode
  static Future<String> saveToCategory(
    Uint8List bytes,
    String filename,
    OutputCategory category, {
    BuildContext? context,
  }) async {
    // Request storage permission before writing
    final hasPermission = await ensureStoragePermission(context);
    if (!hasPermission) {
      throw Exception(
        'Storage permission denied. Please grant storage access in Settings > Apps > Formatica > Permissions.'
      );
    }
    
    final dir = await getOutputDirectoryForCategory(category);
    final outPath = '$dir/$filename';
    await File(outPath).writeAsBytes(bytes);
    
    // Notify Android MediaStore so file appears in gallery/file manager
    await scanMediaFile(outPath);
    
    return outPath;
  }

  /// Legacy method — routes to documents category
  static Future<String> saveToDownloads(
    Uint8List bytes,
    String filename, {
    BuildContext? context,
  }) async {
    return saveToCategory(bytes, filename, OutputCategory.documents, context: context);
  }

  /// Save raw bytes to output directory (for on-device operations like Images to PDF)
  static Future<String> saveOutput(
    Uint8List bytes,
    String filename, {
    BuildContext? context,
  }) async {
    // Request storage permission before writing
    final hasPermission = await ensureStoragePermission(context);
    if (!hasPermission) {
      throw Exception(
        'Storage permission denied. Please grant storage access in Settings > Apps > Formatica > Permissions.'
      );
    }
    
    return saveToCategory(bytes, filename, OutputCategory.pdfs, context: context);
  }

  /// Notify Android MediaStore about a new file
  static Future<void> scanMediaFile(String filePath) async {
    try {
      if (Platform.isAndroid) {
        await _platform.invokeMethod('scanMediaFile', {'path': filePath});
        debugPrint('FileService: Scanned $filePath for gallery');
      }
    } catch (e) {
      debugPrint('FileService: MediaScanner error: $e');
    }
  }

  /// Opens the file with the system default app
  static Future<void> openFile(String filePath) async {
    final result = await OpenFilex.open(filePath);
    debugPrint('OpenFilex result: ${result.type} — ${result.message}');
  }

  /// Opens the containing folder in Android's file manager
  /// PASSES THE FILE PATH (not folder) so Android can highlight/select the specific file
  static Future<void> showInFolder(String filePath) async {
    if (Platform.isAndroid) {
      // IMPORTANT: Always pass the FILE path, not the folder path
      // Android will open the containing folder with the file highlighted
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('FileService: showInFolder called');
      debugPrint('FileService: File path to highlight: $filePath');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Verify the file actually exists
      final fileExists = await File(filePath).exists();
      debugPrint('FileService: File exists? $fileExists');
      
      if (!fileExists) {
        debugPrint('FileService: ERROR - File does not exist!');
        // Try to open the parent folder as fallback
        final parentDir = path.dirname(filePath);
        debugPrint('FileService: Falling back to parent folder: $parentDir');
        
        try {
          await _platform.invokeMethod('openFolder', {'path': parentDir});
        } catch (e) {
          debugPrint('FileService: Error: $e');
        }
        return;
      }
      
      try {
        debugPrint('FileService: Invoking openFolder with FILE path...');
        final result = await _platform.invokeMethod('openFolder', {'path': filePath});
        debugPrint('FileService: openFolder result: $result');
      } catch (e) {
        debugPrint('FileService: openFolder error: $e');
      }
    } else {
      await openFile(filePath);
    }
  }

  static String getFileName(String filePath) => path.basename(filePath);

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// Get the display-friendly output path for UI
  static String getDisplayPath(String fullPath) {
    final idx = fullPath.indexOf(_appFolderName);
    if (idx != -1) return fullPath.substring(idx);
    return path.basename(fullPath);
  }

  /// Get total storage stats (used bytes and total file count) for all Formatica output folders
  static Future<Map<String, int>> getStorageStats() async {
    int totalSize = 0;
    int fileCount = 0;
    try {
      final base = await _getBaseDir();
      final dir = Directory(base);
      if (!await dir.exists()) return {'size': 0, 'count': 0};
      
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
          fileCount++;
        }
      }
    } catch (e) {
      debugPrint('FileService: Failed to get storage stats: $e');
    }
    return {'size': totalSize, 'count': fileCount};
  }
}








