import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';
import '../models/session.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _restoreSession();
  }

  static const _storage = FlutterSecureStorage();
  final ApiService _api = ApiService.instance;

  UserSession? _session;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _english = false;

  UserSession? get session => _session;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _session != null;
  bool get isLoading => _isLoading;
  String get displayName =>
      _session?.displayName ?? _t('TechNet member', 'Thành viên TechNet');

  void setLanguage(String languageCode) {
    final next = languageCode == 'en';
    _api.setLanguage(languageCode);
    if (_english == next) return;
    _english = next;
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    final userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      final token = await _storage.read(key: 'jwt_token');
      _session = UserSession(
        userId: userId,
        displayName:
            await _storage.read(key: 'display_name') ??
            _t('TechNet member', 'Thành viên TechNet'),
        email: await _storage.read(key: 'email'),
        token: token,
        isGuest: (await _storage.read(key: 'is_guest')) == 'true',
        avatarUrl: await _storage.read(key: 'avatar_url'),
        bio: await _storage.read(key: 'bio'),
      );
      _api.setSession(token: token, userId: userId);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return _t(
        'Please enter email and password.',
        'Vui lòng nhập email và mật khẩu.',
      );
    }
    _setLoading(true);
    try {
      final raw = await _api.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final data = _unwrapMap(raw);
      final user = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : data;
      final token = '${data['token'] ?? data['accessToken'] ?? ''}';
      final userId = '${user['id'] ?? user['userId'] ?? ''}';
      if (token.isEmpty || userId.isEmpty) {
        return _t(
          'The login response from the backend has an unexpected format.',
          'Phản hồi đăng nhập từ backend chưa đúng định dạng.',
        );
      }
      await _saveSession(
        UserSession(
          userId: userId,
          displayName: '${user['displayName'] ?? user['userName'] ?? email}',
          email: '${user['email'] ?? email}',
          token: token,
          avatarUrl: _absoluteMediaUrl(user['avatarUrl']?.toString()),
          bio: user['bio']?.toString(),
        ),
      );
      return null;
    } on ApiFailure catch (error) {
      return error.statusCode == 404
          ? _t(
              'The backend has not implemented login yet. You can use guest mode.',
              'Backend chưa triển khai API đăng nhập. Bạn có thể vào chế độ khám phá.',
            )
          : error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> register(
    String email,
    String password,
    String displayName,
  ) async {
    if (displayName.trim().length < 2) {
      return _t(
        'Display name needs at least 2 characters.',
        'Tên hiển thị cần ít nhất 2 ký tự.',
      );
    }
    if (!email.contains('@')) {
      return _t('Email is not valid.', 'Email chưa đúng định dạng.');
    }
    if (password.length < 6) {
      return _t(
        'Password needs at least 6 characters.',
        'Mật khẩu cần ít nhất 6 ký tự.',
      );
    }
    _setLoading(true);
    try {
      await _api.post(
        '/auth/register',
        data: {
          'email': email.trim(),
          'password': password,
          'displayName': displayName.trim(),
        },
      );
      return null;
    } on ApiFailure catch (error) {
      return error.statusCode == 404
          ? _t(
              'The backend has not implemented registration yet.',
              'Backend chưa triển khai API đăng ký.',
            )
          : error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> continueAsGuest() async {
    await _saveSession(
      UserSession(
        userId: AppConstants.guestUserId,
        displayName: _t('Guest explorer', 'Khách khám phá'),
        isGuest: true,
      ),
    );
  }

  Future<String?> updateProfile({
    required String displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_session == null || _session!.isGuest) {
      return _t(
        'Please sign in to edit your profile.',
        'Hãy đăng nhập để chỉnh sửa hồ sơ.',
      );
    }
    _setLoading(true);
    try {
      final raw = await _api.put(
        '/profiles/me',
        data: {
          'displayName': displayName.trim(),
          'bio': bio?.trim(),
          'avatarUrl': avatarUrl?.trim(),
        },
      );
      final data = _unwrapMap(raw);
      await _saveSession(
        UserSession(
          userId: _session!.userId,
          displayName: '${data['displayName'] ?? displayName.trim()}',
          email: _session!.email,
          token: _session!.token,
          avatarUrl: _absoluteMediaUrl(data['avatarUrl']?.toString()),
          bio: data['bio']?.toString(),
        ),
      );
      return null;
    } on ApiFailure catch (error) {
      return error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> uploadAvatar({
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    if (_session == null || _session!.isGuest) {
      return _t(
        'Please sign in to update your avatar.',
        'Hãy đăng nhập để cập nhật ảnh đại diện.',
      );
    }
    try {
      final raw = await _api.uploadFile(
        '/media/upload',
        fileName: fileName,
        filePath: filePath,
        bytes: bytes,
      );
      final data = _unwrapMap(raw);
      final url = _absoluteMediaUrl(data['url']?.toString());
      return url?.isNotEmpty == true
          ? url
          : _t('Could not upload the image.', 'Không thể tải ảnh lên.');
    } on ApiFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> requestPasswordReset(String email) async {
    try {
      final raw = await _api.post(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
      final data = _unwrapMap(raw);
      return data['resetToken']?.toString() ?? data['message']?.toString();
    } on ApiFailure catch (error) {
      return error.message;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _session = null;
    _api.setSession();
    notifyListeners();
  }

  Future<void> _saveSession(UserSession value) async {
    final normalized = UserSession(
      userId: value.userId,
      displayName: value.displayName,
      email: value.email,
      token: value.token,
      isGuest: value.isGuest,
      avatarUrl: _absoluteMediaUrl(value.avatarUrl),
      bio: value.bio,
    );
    _session = normalized;
    await _storage.write(key: 'user_id', value: normalized.userId);
    await _storage.write(key: 'display_name', value: normalized.displayName);
    await _storage.write(key: 'email', value: normalized.email);
    await _storage.write(key: 'jwt_token', value: normalized.token);
    await _storage.write(key: 'is_guest', value: '${normalized.isGuest}');
    await _storage.write(key: 'avatar_url', value: normalized.avatarUrl);
    await _storage.write(key: 'bio', value: normalized.bio);
    _api.setSession(token: normalized.token, userId: normalized.userId);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _t(String en, String vi) => _english ? en : vi;

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return const {};
  }

  String? _absoluteMediaUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('assets/')) return url;
    final parsed = Uri.tryParse(url);
    if (parsed?.hasScheme == true) return url;

    final origin = _api.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (url.startsWith('/')) return '$origin$url';
    return '$origin/$url';
  }
}
