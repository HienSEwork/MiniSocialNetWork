import 'package:flutter/foundation.dart';

import '../models/chat_models.dart';
import '../models/session.dart';
import '../services/local_data_service.dart';

class ChatProvider extends ChangeNotifier {
  final LocalDataService _data = LocalDataService.instance;

  UserSession? _session;
  bool _disposed = false;
  bool _english = false;
  List<ChatUser> _users = const [];
  List<ChatMessage> _messages = const [];
  List<Map<String, dynamic>> _notifications = const [];
  bool _isLoading = false;
  String? _error;

  List<ChatUser> get users => _users;
  List<ChatMessage> get messages => _messages;
  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isRealtimeConnected => true;
  String? get error => _error;

  void updateSession(UserSession? session) {
    final changed = session?.userId != _session?.userId;
    _session = session;
    _data.setSession(token: session?.token, userId: session?.userId);
    if (changed && session?.isGuest != true && session != null) {
      loadNotifications();
    }
  }

  void setLanguage(String languageCode) {
    _english = languageCode == 'en';
    _data.setLanguage(languageCode);
  }

  Future<void> loadNotifications() async {
    if (_session == null || _session!.isGuest) {
      _notifications = const [];
      _safeNotify();
      return;
    }
    try {
      final raw = await _data.get('/notifications');
      _notifications = _list(raw);
      _safeNotify();
    } on LocalDataFailure catch (error) {
      _error = error.message;
      _safeNotify();
    }
  }

  Future<void> loadUsers({String? keyword}) async {
    _setLoading(true);
    try {
      final raw = await _data.get(
        '/chat/users',
        queryParameters: {
          if (keyword?.trim().isNotEmpty == true) 'keyword': keyword!.trim(),
        },
      );
      _users = _list(raw).map(ChatUser.fromJson).toList();
      _error = null;
    } on LocalDataFailure catch (error) {
      _error = error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> openPrivateChat(String otherUserId) async {
    _setLoading(true);
    try {
      final raw = await _data.get('/chat/private/$otherUserId');
      _messages = _list(raw).map(ChatMessage.fromJson).toList();
      _error = null;
    } on LocalDataFailure catch (error) {
      _error = error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> openGroupChat(String groupId) async {
    _setLoading(true);
    try {
      final raw = await _data.get('/chat/groups/$groupId');
      _messages = _list(raw).map(ChatMessage.fromJson).toList();
      _error = null;
    } on LocalDataFailure catch (error) {
      _error = error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> sendPrivate(String receiverId, String content) =>
      _send({'receiverId': receiverId, 'content': content.trim()});

  Future<String?> sendGroup(String groupId, String content) =>
      _send({'groupId': groupId, 'content': content.trim()});

  Future<String?> _send(Map<String, dynamic> request) async {
    if ('${request['content']}'.trim().isEmpty) {
      return _t('Message is empty.', 'Tin nhắn đang trống.');
    }
    try {
      final raw = await _data.post('/chat/messages', data: request);
      if (raw is Map) {
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(raw));
        if (!_messages.any((item) => item.id == message.id)) {
          _messages = [..._messages, message]
            ..sort((a, b) => a.createdDate.compareTo(b.createdDate));
          _safeNotify();
        }
      }
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  String _t(String en, String vi) => _english ? en : vi;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
