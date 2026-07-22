import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../models/group_model.dart';
import '../models/post_model.dart';
import '../models/session.dart';
import '../models/story_model.dart';
import '../services/local_data_service.dart';

class UploadedMedia {
  const UploadedMedia({required this.url, required this.mediaType});

  final String url;
  final int mediaType;
}

class CommunityProvider extends ChangeNotifier {
  final LocalDataService _api = LocalDataService.instance;

  List<SocialGroup> _groups = const [];
  List<SocialGroup> _joinedGroups = const [];
  List<SocialPost> _posts = const [];
  List<SocialStory> _stories = const [];
  UserSession? _session;
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _english = false;
  String? _error;

  List<SocialGroup> get groups => _groups;
  List<SocialGroup> get joinedGroups => _joinedGroups;
  List<SocialPost> get posts => _posts;
  List<SocialStory> get stories => _stories;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isConnected => _hasLoaded && _error == null;
  String? get error => _error;

  void updateSession(UserSession? session) {
    _session = session;
    _api.setSession(token: session?.token, userId: session?.userId);
  }

  void setLanguage(String languageCode) {
    _english = languageCode == 'en';
    _api.setLanguage(languageCode);
  }

  Future<void> loadDashboard({bool force = false}) async {
    if (_isLoading || (_hasLoaded && !force)) return;
    _setLoading(true);
    _error = null;
    try {
      _groups = await _fetchGroups();
      _joinedGroups = await fetchJoinedGroups();
      _stories = await fetchStories();
      final rawFeed = await _api.get(
        '/posts',
        queryParameters: {'page': 1, 'pageSize': 30},
      );
      _posts = _sortNewestFirst(
        _extractList(rawFeed).map(SocialPost.fromJson).toList(),
      );
      _hasLoaded = true;
    } on LocalDataFailure catch (error) {
      _error = error.message;
      _hasLoaded = true;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchGroups(String keyword) async {
    _setLoading(true);
    _error = null;
    try {
      _groups = await _fetchGroups(keyword: keyword);
    } on LocalDataFailure catch (error) {
      _error = error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<SocialPost>> fetchGroupPosts(
    SocialGroup group, {
    int pageSize = 20,
  }) async {
    final raw = await _api.get(
      '/groups/${group.id}/posts',
      queryParameters: {'page': 1, 'pageSize': pageSize},
    );
    return _extractList(
      raw,
    ).map((item) => SocialPost.fromJson(item, groupName: group.name)).toList();
  }

  Future<String?> createGroup(
    String name,
    String description, {
    String? avatarUrl,
  }) async {
    if (name.trim().length < 3) {
      return _t(
        'Group name needs at least 3 characters.',
        'Tên nhóm cần ít nhất 3 ký tự.',
      );
    }
    try {
      await _api.post(
        '/groups',
        data: {
          'name': name.trim(),
          'description': description.trim(),
          'avatarUrl': _emptyToNull(avatarUrl),
        },
      );
      _hasLoaded = false;
      await loadDashboard(force: true);
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> updateGroup(
    SocialGroup group,
    String name,
    String description, {
    String? avatarUrl,
  }) async {
    if (name.trim().length < 3) {
      return _t(
        'Group name needs at least 3 characters.',
        'Tên nhóm cần ít nhất 3 ký tự.',
      );
    }
    try {
      await _api.put(
        '/groups/${group.id}',
        data: {
          'name': name.trim(),
          'description': description.trim(),
          'avatarUrl': _emptyToNull(avatarUrl),
        },
      );
      _hasLoaded = false;
      await loadDashboard(force: true);
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> createPost(
    SocialGroup group,
    String content, {
    String? mediaUrl,
    int mediaType = 0,
  }) async {
    if (content.trim().isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) {
      return _t(
        'Write something or add an image.',
        'Hãy viết nội dung hoặc thêm ảnh.',
      );
    }
    try {
      await _api.post(
        '/groups/${group.id}/posts',
        data: {
          'content': content.trim(),
          'mediaUrl': mediaUrl?.trim().isEmpty == true
              ? null
              : mediaUrl?.trim(),
          'mediaType': mediaUrl?.trim().isNotEmpty == true ? mediaType : 0,
        },
      );
      await loadDashboard(force: true);
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> updatePost(
    SocialPost post,
    String content, {
    String? mediaUrl,
    int mediaType = 0,
  }) async {
    if (content.trim().isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) {
      return _t(
        'Write something or add an image.',
        'Hãy viết nội dung hoặc thêm ảnh.',
      );
    }
    try {
      await _api.put(
        '/posts/${post.id}',
        data: {
          'groupId': post.groupId,
          'content': content.trim(),
          'mediaUrl': mediaUrl?.trim().isEmpty == true
              ? null
              : mediaUrl?.trim(),
          'mediaType': mediaUrl?.trim().isNotEmpty == true ? mediaType : 0,
        },
      );
      await loadDashboard(force: true);
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> deletePost(SocialPost post) async {
    try {
      await _api.delete('/posts/${post.id}');
      await loadDashboard(force: true);
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<List<SocialStory>> fetchStories() async {
    if (_session?.token?.isNotEmpty != true) {
      _stories = const [];
      notifyListeners();
      return const [];
    }
    try {
      final raw = await _api.get('/stories');
      final stories = _extractList(raw).map(SocialStory.fromJson).where((
        story,
      ) {
        return story.expiresAt.isAfter(DateTime.now());
      }).toList()..sort((a, b) => b.createdDate.compareTo(a.createdDate));
      _stories = stories;
      notifyListeners();
      return stories;
    } on LocalDataFailure {
      _stories = const [];
      notifyListeners();
      return const [];
    }
  }

  Future<String?> createStory({
    required String content,
    String? mediaUrl,
    int mediaType = 0,
  }) async {
    if (content.trim().isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) {
      return _t(
        'Write something or add an image.',
        'Hãy thêm nội dung hoặc ảnh.',
      );
    }
    try {
      await _api.post(
        '/stories',
        data: {
          'content': content.trim(),
          'mediaUrl': mediaUrl?.trim().isEmpty == true
              ? null
              : mediaUrl?.trim(),
          'mediaType': mediaUrl?.trim().isNotEmpty == true ? mediaType : 0,
        },
      );
      await fetchStories();
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> updateStory(
    SocialStory story, {
    required String content,
    String? mediaUrl,
    int mediaType = 0,
  }) async {
    if (content.trim().isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) {
      return _t(
        'Write something or add an image.',
        'Hãy thêm nội dung hoặc ảnh.',
      );
    }
    try {
      await _api.put(
        '/stories/${story.id}',
        data: {
          'content': content.trim(),
          'mediaUrl': mediaUrl?.trim().isEmpty == true
              ? null
              : mediaUrl?.trim(),
          'mediaType': mediaUrl?.trim().isNotEmpty == true ? mediaType : 0,
        },
      );
      await fetchStories();
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> deleteStory(SocialStory story) async {
    try {
      await _api.delete('/stories/${story.id}');
      await fetchStories();
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> reactStory(SocialStory story, int type) async {
    try {
      await _api.post('/stories/${story.id}/reactions', data: {'type': type});
      await fetchStories();
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> replyStory(SocialStory story, String content) async {
    if (content.trim().isEmpty) {
      return _t('Message is empty.', 'Tin nhắn đang trống.');
    }
    try {
      await _api.post(
        '/stories/${story.id}/reply',
        data: {'content': content.trim()},
      );
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<UploadedMedia> uploadMedia({
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    final raw = await _api.uploadFile(
      '/media/upload',
      fileName: fileName,
      filePath: filePath,
      bytes: bytes,
    );
    final map = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    return UploadedMedia(
      url: _absoluteMediaUrl('${map['url'] ?? ''}') ?? '',
      mediaType: _asInt(map['mediaType']),
    );
  }

  Future<List<SocialComment>> getComments(String postId) async {
    final raw = await _api.get('/posts/$postId/comments');
    return _extractList(raw).map(SocialComment.fromJson).toList();
  }

  Future<String?> addComment(String postId, String content) async {
    if (content.trim().isEmpty) {
      return _t('Please enter a comment.', 'Hãy nhập nội dung bình luận.');
    }
    try {
      await _api.post(
        '/posts/$postId/comments',
        data: {'content': content.trim()},
      );
      await loadDashboard(force: true);
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> updateComment(
    String postId,
    String commentId,
    String content,
  ) async {
    if (content.trim().isEmpty) {
      return _t('Please enter a comment.', 'Hãy nhập nội dung bình luận.');
    }
    try {
      await _api.put(
        '/posts/$postId/comments/$commentId',
        data: {'content': content.trim()},
      );
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> deleteComment(String postId, String commentId) async {
    try {
      await _api.delete('/posts/$postId/comments/$commentId');
      await loadDashboard(force: true);
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> toggleReaction(String postId, int type) async {
    try {
      await _api.post('/posts/$postId/reactions', data: {'type': type});
      await loadDashboard(force: true);
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> joinGroup(SocialGroup group) =>
      _membershipAction(group, 'join');
  Future<String?> leaveGroup(SocialGroup group) =>
      _membershipAction(group, 'leave');

  Future<String?> _membershipAction(SocialGroup group, String action) async {
    try {
      await _api.post('/groups/${group.id}/$action');
      _hasLoaded = false;
      await loadDashboard(force: true);
      return null;
    } on LocalDataFailure catch (error) {
      return error.message;
    }
  }

  Future<List<SocialGroup>> _fetchGroups({String keyword = ''}) async {
    final raw = keyword.trim().isEmpty
        ? await _api.get('/groups')
        : await _api.get(
            '/groups/search',
            queryParameters: {
              'keyword': keyword.trim(),
              'page': 1,
              'pageSize': 50,
            },
          );
    return _extractList(raw).map(SocialGroup.fromJson).toList();
  }

  Future<List<SocialGroup>> fetchJoinedGroups() async {
    if (_session?.token?.isNotEmpty != true) {
      _joinedGroups = const [];
      notifyListeners();
      return const [];
    }
    try {
      final raw = await _api.get('/groups/mine');
      final groups = _extractList(raw).map(SocialGroup.fromJson).toList();
      _joinedGroups = groups;
      notifyListeners();
      return groups;
    } on LocalDataFailure {
      _joinedGroups = const [];
      notifyListeners();
      return const [];
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    dynamic value = raw;
    if (value is Map && value['data'] != null) value = value['data'];
    if (value is Map && value['items'] != null) value = value['items'];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text?.isNotEmpty == true ? text : null;
  }

  String? _absoluteMediaUrl(String? value) {
    final url = value?.trim();
    return url == null || url.isEmpty ? null : url;
  }

  List<SocialPost> _sortNewestFirst(List<SocialPost> posts) {
    return posts..sort((a, b) => b.createdDate.compareTo(a.createdDate));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _t(String en, String vi) => _english ? en : vi;
}
