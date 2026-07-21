import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );

    if (!kIsWeb && kDebugMode) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (_, __, ___) => true;
          return client;
        },
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token?.isNotEmpty == true) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          if (_userId?.isNotEmpty == true) {
            options.headers['X-User-Id'] = _userId;
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiService instance = ApiService._();

  late final Dio _dio;
  String? _token;
  String? _userId;
  bool _english = false;

  String get baseUrl => _dio.options.baseUrl;

  void setSession({String? token, String? userId}) {
    _token = token;
    _userId = userId;
  }

  void setLanguage(String languageCode) {
    _english = languageCode == 'en';
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return (await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      )).data;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> post(String path, {Object? data}) async {
    try {
      return (await _dio.post<dynamic>(path, data: data)).data;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> put(String path, {Object? data}) async {
    try {
      return (await _dio.put<dynamic>(path, data: data)).data;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> uploadFile(
    String path, {
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    try {
      final file = bytes != null
          ? MultipartFile.fromBytes(bytes, filename: fileName)
          : await MultipartFile.fromFile(filePath!, filename: fileName);
      return (await _dio.post<dynamic>(
        path,
        data: FormData.fromMap({'file': file}),
      )).data;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      return (await _dio.delete<dynamic>(path)).data;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiFailure _mapError(DioException error) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    if (status == 404) {
      return ApiFailure(
        _t('This feature is coming soon.', 'Tính năng sắp ra mắt.'),
        statusCode: 404,
      );
    }
    if (status == 401 || status == 403) {
      return ApiFailure(
        _t(
          'Your session is not allowed to perform this action.',
          'Phiên đăng nhập không có quyền thực hiện thao tác này.',
        ),
        statusCode: status,
      );
    }
    if (status != null) {
      String? detail;
      if (body is Map) {
        detail =
            body['message']?.toString() ??
            body['detail']?.toString() ??
            body['title']?.toString();
      }
      return ApiFailure(
        detail?.isNotEmpty == true
            ? detail!
            : _t(
                'Backend responded with error $status.',
                'Backend phản hồi lỗi $status.',
              ),
        statusCode: status,
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiFailure(
        _t(
          'The backend connection timed out. Please check that the API is running.',
          'Kết nối backend quá thời gian. Hãy kiểm tra API đang chạy.',
        ),
      );
    }
    return ApiFailure(
      _t(
        'Could not connect to the backend at ${AppConstants.apiBaseUrl}.',
        'Không thể kết nối backend tại ${AppConstants.apiBaseUrl}.',
      ),
    );
  }

  String _t(String en, String vi) => _english ? en : vi;
}
