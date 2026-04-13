import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// API client for communicating with the LibreOffice backend server.
class ApiClient {
  static Dio? _dioInstance;

  static Dio get _dio {
    _dioInstance ??= Dio(
      BaseOptions(
        baseUrl: AppConstants.backendBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 300),
        sendTimeout: const Duration(seconds: 120),
        headers: {
          'Accept': 'application/octet-stream, application/json',
          'Connection': 'keep-alive',
        },
        // Don't follow redirects automatically - we want to see what's happening
        followRedirects: false,
      ),
    )..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('→ ${options.method} ${options.baseUrl}${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final dataLength = switch (response.data) {
            List list => list.length,
            _ => 0,
          };
          debugPrint('← ${response.statusCode} ($dataLength bytes)');
          return handler.next(response);
        },
        onError: (e, handler) {
          debugPrint('✗ ${e.type}: ${e.message}');
          debugPrint('✗ status: ${e.response?.statusCode}');
          debugPrint('✗ data: ${e.response?.data}');
          return handler.next(e);
        },
      ));
    return _dioInstance!;
  }

  static Future<Uint8List> postMultipart({
    required String endpoint,
    required String filePath,
    required Map<String, String> fields,
    void Function(double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
        ...fields,
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.bytes),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total * 0.3);
        },
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(0.3 + received / total * 0.7);
          }
        },
      );

      if (response.data == null) {
        throw Exception('Server returned empty response.');
      }
      return Uint8List.fromList(response.data as List<int>);

    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Operation cancelled by user.');
      }
      debugPrint('DioException: ${e.type} - ${e.message}');
      String msg;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          msg = 'Connection timed out. Server may be starting up. '
              'Wait 30 seconds and try again.';
          break;
        case DioExceptionType.receiveTimeout:
          msg = 'Server took too long. Try a smaller file.';
          break;
        case DioExceptionType.connectionError:
          msg = 'Cannot reach server. Check your internet connection.';
          break;
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          if (status == 400) {
            msg = 'Unsupported format or conversion path.';
          } else if (status == 504) {
            msg = 'Conversion timed out on server. Try a smaller file.';
          } else {
            msg = 'Server error ($status). Please try again.';
          }
          break;
        default:
          msg = 'Connection failed: ${e.message}';
      }
      throw Exception(msg);
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Check backend health status
  static Future<Map<String, dynamic>> getHealth() async {
    try {
      debugPrint('HealthCheck: Requesting ${AppConstants.backendBaseUrl}${AppConstants.healthEndpoint}');
      final response = await _dio.get(
        AppConstants.healthEndpoint,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      debugPrint('HealthCheck: Response status=${response.statusCode}');
      debugPrint('HealthCheck: Response data=${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('HealthCheck: DioException type=${e.type}');
      debugPrint('HealthCheck: DioException message=${e.message}');
      debugPrint('HealthCheck: DioException response status=${e.response?.statusCode}');
      debugPrint('HealthCheck: DioException response data=${e.response?.data}');
      return {'status': 'error', 'message': e.toString()};
    } catch (e, stackTrace) {
      debugPrint('HealthCheck: Unexpected error: $e');
      debugPrint('HealthCheck: Stack trace: $stackTrace');
      return {'status': 'error', 'message': e.toString()};
    }
  }
}








