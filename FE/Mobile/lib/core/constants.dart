import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const String _definedApiUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_definedApiUrl.isNotEmpty) return _definedApiUrl;
    if (kIsWeb) return 'http://localhost:5046/api';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5046/api'
        : 'http://localhost:5046/api';
  }

  static String get signalRBaseUrl =>
      apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '/hubs');

  static const String appName = 'TechNet';
  static const String guestUserId = 'demo-user';
  static const double compactBreakpoint = 760;
  static const double contentMaxWidth = 760;
}
