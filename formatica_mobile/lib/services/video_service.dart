import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:ffmpeg_kit_flutter_new/stream_information.dart';
import 'file_service.dart';

class VideoService {
  static Future<_VideoProbeData> _probeVideo(String filePath) async {
    int durationMs = 60000;
    int? bitrate;
    int? width;
    int? height;

    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final info = session.getMediaInformation();
      if (info != null) {
        final durationStr = info.getDuration();
        if (durationStr != null) {
          durationMs = (double.parse(durationStr) * 1000).toInt();
        }

        bitrate = _parseInt(info.getBitrate());

        StreamInformation? videoStream;
        for (final stream in info.getStreams()) {
          if (stream.getType() == 'video') {
            videoStream = stream;
            break;
          }
        }

        if (videoStream != null) {
          bitrate = _parseInt(videoStream.getBitrate()) ?? bitrate;
          width = videoStream.getWidth();
          height = videoStream.getHeight();
        }
      }
    } catch (e) {
      debugPrint('VideoService: Could not probe media info: $e');
    }

    bitrate ??= await _estimateSourceBitrate(filePath, durationMs);

    return _VideoProbeData(
      durationMs: durationMs,
      bitrate: bitrate,
      width: width,
      height: height,
    );
  }

  static int? _parseInt(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return int.tryParse(value);
  }

  static Future<int?> _estimateSourceBitrate(
      String filePath, int durationMs) async {
    if (durationMs <= 0) {
      return null;
    }
    try {
      final fileLength = await File(filePath).length();
      return ((fileLength * 8) / (durationMs / 1000)).round();
    } catch (_) {
      return null;
    }
  }

  static String _scaleFilter(String resolution) {
    if (resolution.isEmpty || resolution == 'original') {
      return '';
    }
    return '-vf "scale=$resolution:flags=fast_bilinear"';
  }

  static String _x264PresetForRequestedPreset(String preset) {
    switch (preset) {
      case 'fast':
        return 'ultrafast';  // Maximum speed for fast mode
      case 'slow':
        return 'superfast';  // Still very fast, slightly better quality
      default:
        return 'ultrafast';  // Default to maximum speed
    }
  }

  static Future<dynamic> _runCommandWithProgress({
    required String command,
    required int durationMs,
    required void Function(double) onProgress,
    void Function(Future<void> Function())? onCancelSetup,
  }) async {
    final completer = Completer<dynamic>();

    final session = await FFmpegKit.executeAsync(
      command,
      (session) async {
        completer.complete(session);
      },
      (log) {},
      (Statistics stats) {
        final time = stats.getTime();
        if (durationMs > 0 && time > 0) {
          // Use 0.98 as a max internal cap during runtime
          final progress = (time / durationMs).clamp(0.0, 0.98);
          onProgress(0.02 + progress * 0.97);
        }
      },
    );

    onCancelSetup?.call(() async {
      await FFmpegKit.cancel(session.getSessionId());
    });

    return await completer.future;
  }

  static Future<String> convertVideo({
    required String inputFilePath,
    required String outputFormat,
    required void Function(double) onProgress,
    void Function(Future<void> Function())? onCancelSetup,
  }) async {
    debugPrint('VideoService: Starting conversion');
    debugPrint('VideoService: Input=$inputFilePath');
    debugPrint('VideoService: Format=$outputFormat');
    
    onProgress(0.01);
    final probe = await _probeVideo(inputFilePath);
    debugPrint('VideoService: Probed - Duration=${probe.durationMs}ms, Bitrate=${probe.bitrate}, Size=${probe.width}x${probe.height}');
    onProgress(0.05);

    final base = p.basenameWithoutExtension(inputFilePath);
    final outDir =
        await FileService.getOutputDirectoryForCategory(OutputCategory.videos);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '$outDir/${base}_converted_$ts.$outputFormat';

    String cmd;
    if (outputFormat == 'gif') {
      final palette = '$outDir/_palette_$ts.png';
      await FFmpegKit.execute(
        '-i "$inputFilePath" -vf "fps=12,scale=480:-1:flags=lanczos,palettegen=stats_mode=diff" -y "$palette"',
      );
      cmd = '-i "$inputFilePath" -i "$palette" '
          '-lavfi "fps=12,scale=480:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" '
          '-y "$outPath"';
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      try {
        await File(palette).delete();
      } catch (_) {}
      if (!ReturnCode.isSuccess(rc)) {
        final logs = await session.getOutput();
        final details = logs ?? 'unknown error';
        final end = details.length > 200 ? 200 : details.length;
        throw Exception('GIF conversion failed: ${details.substring(0, end)}');
      }
    } else if (outputFormat == 'webm') {
      cmd =
          '-i "$inputFilePath" -c:v libvpx-vp9 -b:v 0 -crf 30 -c:a libopus -y "$outPath"';
      final session = await _runCommandWithProgress(
        command: cmd,
        durationMs: probe.durationMs,
        onProgress: onProgress,
        onCancelSetup: onCancelSetup,
      );
      final rc = await session.getReturnCode();
      if (!ReturnCode.isSuccess(rc)) {
        throw Exception('Video conversion failed');
      }
    } else {
      // Optimized for speed: ultrafast preset + medium CRF for quality balance
      // Removed -movflags +faststart (adds overhead, not needed for local files)
      // Removed audio codec specification (let FFmpeg auto-copy or select best)
      cmd =
          '-i "$inputFilePath" -c:v libx264 -preset ultrafast -crf 23 -c:a copy -y "$outPath"';
      debugPrint('VideoService: Converting with ultrafast preset');
      final session = await _runCommandWithProgress(
        command: cmd,
        durationMs: probe.durationMs,
        onProgress: onProgress,
        onCancelSetup: onCancelSetup,
      );
      final rc = await session.getReturnCode();
      if (!ReturnCode.isSuccess(rc)) {
        throw Exception('Video conversion failed');
      }
    }

    await FileService.scanMediaFile(outPath);
    debugPrint('VideoService: Conversion complete - $outPath');
    onProgress(1.0);
    return outPath;
  }

  static Future<String> compressVideo({
    required String inputFilePath,
    required int crf,
    required String preset,
    required String resolution,
    required void Function(double) onProgress,
    void Function(Future<void> Function())? onCancelSetup,
  }) async {
    onProgress(0.01);
    final probe = await _probeVideo(inputFilePath);
    onProgress(0.05);

    final base = p.basenameWithoutExtension(inputFilePath);
    final outDir =
        await FileService.getOutputDirectoryForCategory(OutputCategory.videos);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '$outDir/${base}_compressed_$ts.mp4';

    final vf = _scaleFilter(resolution);
    final encoderPreset = _x264PresetForRequestedPreset(preset);
    
    // Optimized for maximum speed
    // -preset ultrafast: Fastest encoding
    // -crf: Quality control (lower=better quality, higher=faster)
    // -threads 0: Auto-detect optimal thread count
    // -c:a copy: Copy audio without re-encoding (saves time)
    final softwareCmd = '-i "$inputFilePath" $vf '
        '-c:v libx264 -crf $crf -preset $encoderPreset -threads 0 '
        '-pix_fmt yuv420p '
        '-c:a copy '
        '-y "$outPath"';

    final session = await _runCommandWithProgress(
      command: softwareCmd,
      durationMs: probe.durationMs,
      onProgress: onProgress,
      onCancelSetup: onCancelSetup,
    );
    final rc = await session.getReturnCode();
    if (!ReturnCode.isSuccess(rc)) {
      final logs = await session.getOutput();
      final details = logs ?? 'unknown';
      final end = details.length > 240 ? 240 : details.length;
      throw Exception('Compression failed: ${details.substring(0, end)}');
    }

    await FileService.scanMediaFile(outPath);
    onProgress(1.0);
    return outPath;
  }
}

class _VideoProbeData {
  const _VideoProbeData({
    required this.durationMs,
    required this.bitrate,
    required this.width,
    required this.height,
  });

  final int durationMs;
  final int? bitrate;
  final int? width;
  final int? height;
}








