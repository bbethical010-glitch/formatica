import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../core/constants.dart';
import 'api_client.dart';
import 'file_service.dart';

class ConvertService {
  static Future<String> convertDocument({
    required String inputFilePath,
    required String outputFormat,
    required void Function(double) onProgress,
    void Function(Future<void> Function())? onCancelSetup,
    BuildContext? context,
  }) async {
    // Ensure we have a real file path not a content URI
    String resolvedPath = inputFilePath;
    if (inputFilePath.startsWith('content://')) {
      throw Exception(
        'Cannot read this file directly. '
        'Please copy it to Downloads folder first.'
      );
    }

    // Validate file exists
    final file = File(resolvedPath);
    if (!await file.exists()) {
      throw Exception('File not found: $resolvedPath');
    }

    // Check file size
    final fileSize = await file.length();
    if (fileSize > AppConstants.maxFileSizeBytes) {
      throw Exception('File too large. Maximum size is 50 MB.');
    }

    debugPrint('ConvertService: starting conversion');
    debugPrint('ConvertService: input=$resolvedPath');
    debugPrint('ConvertService: format=$outputFormat');
    debugPrint('ConvertService: size=${fileSize ~/ 1024}KB');

    // Wake up backend (HF free tier may be sleeping)
    onProgress(0.02);
    debugPrint('ConvertService: waking backend...');
    bool backendReady = false;
    for (int i = 0; i < 3; i++) {
      final h = await ApiClient.getHealth();
      debugPrint('ConvertService: health check ${i+1}: $h');
      if (h['status'] == 'ok') {
        backendReady = true;
        break;
      }
      if (i < 2) await Future.delayed(const Duration(seconds: 15));
    }

    if (!backendReady) {
      throw Exception(
        'Server is starting up. Please wait 30 seconds and try again.');
    }
    onProgress(0.1);

    // Create and expose the cancel token
    final cancelToken = CancelToken();
    onCancelSetup?.call(() async {
      cancelToken.cancel('User cancelled');
    });

    // Send to LibreOffice backend
    debugPrint('ConvertService: sending to backend...');
    final bytes = await ApiClient.postMultipart(
      endpoint: AppConstants.convertEndpoint,
      filePath: resolvedPath,
      fields: {'output_format': outputFormat},
      cancelToken: cancelToken,
      onProgress: (p) {
        onProgress(0.1 + p * 0.85);
        debugPrint('ConvertService: progress=${(p*100).toInt()}%');
      },
    );

    debugPrint('ConvertService: received ${bytes.length} bytes');
    onProgress(0.97);

    // Save to Downloads
    final inputBasename = path.basenameWithoutExtension(resolvedPath);
    final outputFilename = '${inputBasename}_converted.$outputFormat';
    final savedPath = await FileService.saveToDownloads(
      bytes,
      outputFilename,
      context: context,
    );
    
    debugPrint('ConvertService: saved to $savedPath');
    onProgress(1.0);
    return savedPath;
  }
}








