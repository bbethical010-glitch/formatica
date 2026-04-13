import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'file_service.dart';

class AudioService {
  /// Extract audio from video — fully on-device
  static Future<String> extractAudio({
    required String inputFilePath,
    required String outputFormat,
    required String bitrate,
    required void Function(double) onProgress,
    void Function(Future<void> Function())? onCancelSetup,
  }) async {
    onProgress(0.01);

    // Ensure we have a real file path not a content URI
    String resolvedPath = inputFilePath;
    if (inputFilePath.startsWith('content://')) {
      throw Exception(
        'Cannot read this file directly. '
        'Please copy it to Downloads folder first.'
      );
    }

    // Validate file exists
    final inputFile = File(resolvedPath);
    if (!await inputFile.exists()) {
      throw Exception('File not found: $resolvedPath');
    }

    debugPrint('AudioService: Extracting audio from $resolvedPath');
    debugPrint('AudioService: Format=$outputFormat, Bitrate=$bitrate');

    // Get duration for progress tracking
    int durationMs = 60000; // Default 60 seconds
    try {
      debugPrint('AudioService: Probing media duration...');
      final session = await FFprobeKit.getMediaInformation(resolvedPath);
      final info = session.getMediaInformation();
      if (info != null) {
        final d = info.getDuration();
        if (d != null) {
          durationMs = (double.parse(d) * 1000).toInt();
          debugPrint('AudioService: Duration=${durationMs}ms');
        }
      }
    } catch (e) {
      debugPrint('AudioService: Failed to get duration, using default: $e');
    }
    onProgress(0.05);

    // Setup output path
    final base = p.basenameWithoutExtension(resolvedPath);
    final outDir = await FileService.getOutputDirectoryForCategory(OutputCategory.audio);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '$outDir/${base}_audio_$ts.$outputFormat';
    debugPrint('AudioService: Output path=$outPath');

    // Map output format to FFmpeg codec
    String codec;
    switch (outputFormat) {
      case 'mp3':
        codec = 'libmp3lame';
        break;
      case 'aac':
        codec = 'aac';
        break;
      case 'wav':
        codec = 'pcm_s16le';
        break;
      case 'flac':
        codec = 'flac';
        break;
      case 'ogg':
        codec = 'libvorbis';
        break;
      default:
        codec = 'libmp3lame';
    }

    final cmd = '-i "$resolvedPath" -vn -c:a $codec -b:a $bitrate -y "$outPath"';
    debugPrint('AudioService: FFmpeg command: $cmd');

    // Use Completer to wait for completion
    final completer = Completer<dynamic>();

    final ffSession = await FFmpegKit.executeAsync(
      cmd,
      (session) async {
        debugPrint('AudioService: FFmpeg callback triggered');
        completer.complete(session);
      },
      (log) {
        // Log FFmpeg output for debugging
        debugPrint('AudioService: FFmpeg log: ${log.getMessage()}');
      },
      (Statistics stats) {
        final time = stats.getTime();
        if (durationMs > 0 && time > 0) {
          final progress = (time / durationMs).clamp(0.0, 0.95);
          final overallProgress = 0.05 + progress * 0.90;
          debugPrint('AudioService: Progress=${(overallProgress * 100).toInt()}% (time=$time, duration=$durationMs)');
          onProgress(overallProgress);
        }
      },
    );

    onCancelSetup?.call(() async {
      await FFmpegKit.cancel(ffSession.getSessionId());
    });
    debugPrint('AudioService: Waiting for FFmpeg to complete...');
    try {
      final session = await completer.future.timeout(
        const Duration(minutes: 10), // 10 minute timeout
        onTimeout: () {
          debugPrint('AudioService: FFmpeg timed out after 10 minutes');
          throw Exception('Audio extraction timed out. The video may be too large or corrupted.');
        },
      );

      // Check return code
      final rc = await session.getReturnCode();
      debugPrint('AudioService: Return code=$rc');
      
      if (!ReturnCode.isSuccess(rc)) {
        if (ReturnCode.isCancel(rc)) {
          throw Exception('Operation cancelled by user.');
        }
        final output = await session.getOutput();
        final failStackTrace = await session.getFailStackTrace();
        debugPrint('AudioService: FFmpeg failed');
        debugPrint('AudioService: Output: ${output?.substring(0, 500)}');
        debugPrint('AudioService: Fail stack trace: $failStackTrace');
        throw Exception('Audio extraction failed: ${output?.substring(0, 200) ?? "unknown error"}');
      }

      // Verify output file exists
      final outputFile = File(outPath);
      if (!await outputFile.exists()) {
        throw Exception('Audio extraction failed to create file.');
      }

      final outputSize = await outputFile.length();
      debugPrint('AudioService: Output file created: ${outputSize ~/ 1024}KB');

      // Notify Android MediaStore
      await FileService.scanMediaFile(outPath);
      
      onProgress(1.0);
      debugPrint('AudioService: Extraction complete!');
      return outPath;
    } catch (e) {
      debugPrint('AudioService: Error: $e');
      rethrow;
    }
  }
}








