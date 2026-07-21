import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../core/constants.dart';
import '../models/chat_models.dart';
import '../models/session.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  HubConnection? _chatHub;
  HubConnection? _notificationHub;
  UserSession? _session;
  bool _disposed = false;
  bool _connecting = false;
  bool _english = false;
  String? _configuredToken;

  List<ChatUser> _users = const [];
  List<ChatMessage> _messages = const [];
  final List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<ChatUser> get users => _users;
  List<ChatMessage> get messages => _messages;
  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isRealtimeConnected =>
      _chatHub?.state == HubConnectionState.Connected;
  String? get error => _error;

  void updateSession(UserSession? session) {
    _session = session;
    if (session?.token != _configuredToken) _configureRealtime();
  }

  void setLanguage(String languageCode) {
    _english = languageCode == 'en';
    _api.setLanguage(languageCode);
  }

  Future<void> _configureRealtime() async {
    if (_connecting) return;
    _connecting = true;
    try {
      await _chatHub?.stop();
      await _notificationHub?.stop();
      _configuredToken = _session?.token;
      if (_configuredToken == null ||
          _configuredToken!.isEmpty ||
          _session!.isGuest) {
        _chatHub = null;
        _notificationHub = null;
        return;
      }
      final options = HttpConnectionOptions(
        accessTokenFactory: () async => _configuredToken!,
      );
      _chatHub = HubConnectionBuilder()
          .withUrl('${AppConstants.signalRBaseUrl}/chat', options: options)
          .withAutomaticReconnect()
          .build();
      _notificationHub = HubConnectionBuilder()
          .withUrl(
            '${AppConstants.signalRBaseUrl}/notifications',
            options: options,
          )
          .withAutomaticReconnect()
          .build();
      _chatHub!.on('ReceiveMessage', _receiveMessage);
      _notificationHub!.on('ReceiveNotification', _receiveNotification);
      _notificationHub!.on('ReactionChanged', _receiveReaction);
      await Future.wait([_chatHub!.start()!, _notificationHub!.start()!]);
    } catch (_) {
      _error = _t(
        'Could not connect to the realtime channel.',
        'Chưa thể kết nối kênh thời gian thực.',
      );
    } finally {
      _connecting = false;
      _safeNotify();
    }
  }

  Future<void> loadUsers({String? keyword}) async {
    _setLoading(true);
    try {
      final raw = await _api.get(
        '/chat/users',
        queryParameters: {
          if (keyword?.trim().isNotEmpty == true) 'keyword': keyword!.trim(),
        },
      );
      _users = _list(raw).map(ChatUser.fromJson).toList();
      _error = null;
    } on ApiFailure catch (error) {
      _error = error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> openPrivateChat(String otherUserId) async {
    _setLoading(true);
    try {
      final raw = await _api.get('/chat/private/$otherUserId');
      _messages = _list(raw).map(ChatMessage.fromJson).toList();
      _error = null;
    } on ApiFailure catch (error) {
      _error = error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> openGroupChat(String groupId) async {
    _setLoading(true);
    try {
      final raw = await _api.get('/chat/groups/$groupId');
      _messages = _list(raw).map(ChatMessage.fromJson).toList();
      if (isRealtimeConnected) {
        await _chatHub!.invoke('JoinGroup', args: [groupId]);
      }
      _error = null;
    } on ApiFailure catch (error) {
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
      if (isRealtimeConnected) {
        await _chatHub!.invoke('SendMessage', args: [request]);
      } else {
        final raw = await _api.post('/chat/messages', data: request);
        if (raw is Map) {
          _appendMessage(ChatMessage.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
      return null;
    } on ApiFailure catch (error) {
      return error.message;
    } catch (_) {
      return _t(
        'Could not send the message through the realtime channel.',
        'Không gửi được tin nhắn qua kênh thời gian thực.',
      );
    }
  }

  void _receiveMessage(List<Object?>? arguments) {
    final value = arguments?.firstOrNull;
    if (value is Map) {
      _appendMessage(ChatMessage.fromJson(Map<String, dynamic>.from(value)));
    }
  }

  void _receiveNotification(List<Object?>? arguments) {
    final value = arguments?.firstOrNull;
    if (value is Map) {
      _notifications.insert(0, Map<String, dynamic>.from(value));
      _safeNotify();
    }
  }

  void _receiveReaction(List<Object?>? arguments) {
    _notifications.insert(0, {
      'type': 'reaction-update',
      'receivedAt': DateTime.now().toIso8601String(),
    });
    _safeNotify();
  }

  void _appendMessage(ChatMessage message) {
    if (_messages.any((item) => item.id == message.id)) return;
    _messages = [..._messages, message]
      ..sort((a, b) => a.createdDate.compareTo(b.createdDate));
    _safeNotify();
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
    _chatHub?.stop();
    _notificationHub?.stop();
    super.dispose();
  }
}
