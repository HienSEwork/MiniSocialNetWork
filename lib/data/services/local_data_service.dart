import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../local/local_database.dart';
import '../local/local_content_filter.dart';

class LocalDataFailure implements Exception {
  const LocalDataFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Single entry point for all persistent app data.
///
/// The public methods intentionally mirror the old provider contract so the UI
/// stays focused on presentation, while every operation is now executed against
/// the on-device SQLite database.
class LocalDataService {
  LocalDataService._();

  static final LocalDataService instance = LocalDataService._();

  final LocalDatabase _store = LocalDatabase.instance;
  final LocalContentFilter _contentFilter = const LocalContentFilter();
  String? _userId;
  bool _english = false;

  String get baseUrl => 'local://technet';
  String? get currentUserId => _userId;

  void setSession({String? token, String? userId}) => _userId = userId;

  void setLanguage(String languageCode) => _english = languageCode == 'en';

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final db = await _store.database;
    final query = queryParameters ?? const <String, dynamic>{};

    if (path == '/groups') return _groups(db);
    if (path == '/groups/search') {
      return _groups(db, keyword: '${query['keyword'] ?? ''}');
    }
    if (path == '/groups/mine') {
      _requireUser();
      return _groups(db, memberId: _userId);
    }
    if (RegExp(r'^/groups/[^/]+/members$').hasMatch(path)) {
      final groupId = _segment(path, 1);
      final rows = await db.rawQuery(
        '''
        SELECT u.id, u.display_name, u.avatar_url, u.bio, m.role, m.joined_date
        FROM group_members m JOIN users u ON u.id = m.user_id
        WHERE m.group_id = ? AND u.is_deleted = 0
        ORDER BY m.role, m.joined_date
      ''',
        [groupId],
      );
      return rows
          .map(
            (row) => {
              'id': row['id'],
              'displayName': row['display_name'],
              'avatarUrl': row['avatar_url'],
              'bio': row['bio'],
              'role': row['role'],
              'joinedDate': row['joined_date'],
            },
          )
          .toList();
    }
    if (RegExp(r'^/groups/[^/]+/posts$').hasMatch(path)) {
      return _posts(db, groupId: _segment(path, 1));
    }
    if (path == '/posts') return {'items': await _posts(db)};
    if (RegExp(r'^/posts/[^/]+/comments$').hasMatch(path)) {
      return _comments(db, _segment(path, 1));
    }
    if (path == '/stories') return _stories(db);
    if (path == '/chat/users') {
      return _chatUsers(db, keyword: '${query['keyword'] ?? ''}');
    }
    if (RegExp(r'^/chat/private/[^/]+$').hasMatch(path)) {
      _requireUser();
      return _privateMessages(db, _segment(path, 2));
    }
    if (RegExp(r'^/chat/groups/[^/]+$').hasMatch(path)) {
      return _groupMessages(db, _segment(path, 2));
    }
    if (path == '/search') {
      return _search(db, '${query['q'] ?? ''}', _asInt(query['limit'], 12));
    }
    if (path == '/marketplace') {
      return _marketplace(
        db,
        category: query['category']?.toString(),
        keyword: query['keyword']?.toString(),
      );
    }
    if (path == '/marketplace/mine') {
      _requireUser();
      return _marketplace(db, sellerId: _userId, includeSold: true);
    }
    if (path == '/marketplace/mine/stats') {
      _requireUser();
      return _marketplaceStats(db, _userId!);
    }
    if (RegExp(r'^/marketplace/seller/[^/]+/stats$').hasMatch(path)) {
      return _marketplaceStats(db, _segment(path, 2));
    }
    if (RegExp(r'^/marketplace/seller/[^/]+$').hasMatch(path)) {
      return _marketplace(db, sellerId: _segment(path, 2), includeSold: true);
    }
    if (path == '/achievements/me') {
      _requireUser();
      return _achievements(db, _userId!);
    }
    if (RegExp(r'^/profiles/[^/]+/achievements$').hasMatch(path)) {
      return _achievements(db, _segment(path, 1));
    }
    if (RegExp(r'^/profiles/[^/]+/portfolio$').hasMatch(path)) {
      return _portfolio(db, _segment(path, 1));
    }
    if (path == '/notifications') {
      _requireUser();
      return _notifications(db, _userId!);
    }
    if (path == '/friends') {
      _requireUser();
      return _friends(db, _userId!);
    }
    if (path == '/friends/requests') {
      _requireUser();
      return _friendRequests(db, _userId!);
    }
    if (path == '/jobs') {
      return jobs(
        keyword: query['keyword']?.toString(),
        location: query['location']?.toString(),
        workType: query['workType']?.toString(),
        stack: query['stack']?.toString(),
        savedOnly: query['savedOnly'] == true,
      );
    }
    if (path == '/admin/stats') return adminStats();
    if (path == '/admin/posts-per-day') return postsPerDay();
    if (path == '/admin/users') return adminUsers();

    throw LocalDataFailure(
      _t('Feature not found.', 'Không tìm thấy chức năng.'),
      statusCode: 404,
    );
  }

  Future<dynamic> post(String path, {Object? data}) async {
    final db = await _store.database;
    final body = _body(data);

    if (path == '/auth/login') return _login(db, body);
    if (path == '/auth/register') return _register(db, body);
    if (path == '/auth/forgot-password') return _forgotPassword(db, body);
    if (path == '/auth/reset-password') return _resetPassword(db, body);
    if (path == '/auth/change-password') return _changePassword(db, body);
    if (path == '/groups') return _createGroup(db, body);
    if (RegExp(r'^/groups/[^/]+/posts$').hasMatch(path)) {
      return _createPost(db, _segment(path, 1), body);
    }
    if (RegExp(r'^/groups/[^/]+/(join|leave)$').hasMatch(path)) {
      return _groupMembership(db, _segment(path, 1), _segment(path, 2));
    }
    if (RegExp(r'^/posts/[^/]+/comments$').hasMatch(path)) {
      return _createComment(db, _segment(path, 1), body);
    }
    if (RegExp(r'^/posts/[^/]+/reactions$').hasMatch(path)) {
      return _toggleReaction(db, _segment(path, 1), _asInt(body['type']));
    }
    if (path == '/stories') return _createStory(db, body);
    if (RegExp(r'^/stories/[^/]+/reactions$').hasMatch(path)) {
      return _toggleStoryReaction(db, _segment(path, 1), _asInt(body['type']));
    }
    if (RegExp(r'^/stories/[^/]+/reply$').hasMatch(path)) {
      return _replyStory(db, _segment(path, 1), '${body['content'] ?? ''}');
    }
    if (path == '/chat/messages') return _sendMessage(db, body);
    if (path == '/marketplace') return _createMarketplaceItem(db, body);
    if (RegExp(r'^/marketplace/[^/]+/(mark-sold|relist)$').hasMatch(path)) {
      return _setMarketplaceStatus(
        db,
        _segment(path, 1),
        _segment(path, 2) == 'mark-sold' ? 1 : 0,
      );
    }
    if (RegExp(r'^/friends/[^/]+/request$').hasMatch(path)) {
      return _sendFriendRequest(db, _segment(path, 1));
    }
    if (RegExp(r'^/friends/requests/[^/]+/(accept|decline)$').hasMatch(path)) {
      return _answerFriendRequest(db, _segment(path, 2), _segment(path, 3));
    }
    if (RegExp(r'^/jobs/[^/]+/(save|interest)$').hasMatch(path)) {
      return _jobAction(db, _segment(path, 1), _segment(path, 2), body);
    }

    throw LocalDataFailure(
      _t('Feature not found.', 'Không tìm thấy chức năng.'),
      statusCode: 404,
    );
  }

  Future<dynamic> put(String path, {Object? data}) async {
    final db = await _store.database;
    final body = _body(data);
    if (path == '/profiles/me') return _updateProfile(db, body);
    if (path == '/profiles/me/portfolio') return _updatePortfolio(db, body);
    if (RegExp(r'^/groups/[^/]+/members/[^/]+/role$').hasMatch(path)) {
      _requireUser();
      final groupId = _segment(path, 1);
      await _requireGroupOwner(db, groupId);
      await db.update(
        'group_members',
        {'role': _asInt(body['role'], 2)},
        where: 'group_id = ? AND user_id = ?',
        whereArgs: [groupId, _segment(path, 3)],
      );
      return const {'ok': true};
    }
    if (RegExp(r'^/posts/[^/]+/comments/[^/]+$').hasMatch(path)) {
      _requireUser();
      _validateContent('${body['content'] ?? ''}');
      final updated = await db.update(
        'comments',
        {
          'content': '${body['content'] ?? ''}'.trim(),
          'updated_date': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ? AND post_id = ? AND user_id = ?',
        whereArgs: [_segment(path, 3), _segment(path, 1), _userId],
      );
      if (updated == 0) {
        throw LocalDataFailure(
          _t(
            'You can only edit your own comment.',
            'Bạn chỉ có thể sửa bình luận của mình.',
          ),
          statusCode: 403,
        );
      }
      return const {'ok': true};
    }
    if (RegExp(r'^/groups/[^/]+$').hasMatch(path)) {
      return _updateGroup(db, _segment(path, 1), body);
    }
    if (RegExp(r'^/posts/[^/]+$').hasMatch(path)) {
      return _updatePost(db, _segment(path, 1), body);
    }
    if (RegExp(r'^/posts/[^/]+/comments/[^/]+$').hasMatch(path)) {
      _requireUser();
      final updated = await db.update(
        'comments',
        {'is_deleted': 1},
        where: 'id = ? AND post_id = ? AND user_id = ?',
        whereArgs: [_segment(path, 3), _segment(path, 1), _userId],
      );
      if (updated == 0) {
        throw LocalDataFailure(
          _t(
            'You can only delete your own comment.',
            'Bạn chỉ có thể xóa bình luận của mình.',
          ),
          statusCode: 403,
        );
      }
      return const {'ok': true};
    }
    if (RegExp(r'^/stories/[^/]+$').hasMatch(path)) {
      return _updateStory(db, _segment(path, 1), body);
    }
    if (RegExp(r'^/marketplace/[^/]+$').hasMatch(path)) {
      return _updateMarketplaceItem(db, _segment(path, 1), body);
    }
    throw LocalDataFailure(
      _t('Feature not found.', 'Không tìm thấy chức năng.'),
      statusCode: 404,
    );
  }

  Future<dynamic> delete(String path) async {
    final db = await _store.database;
    if (RegExp(r'^/posts/[^/]+$').hasMatch(path)) {
      return _softDeleteOwned(db, 'posts', _segment(path, 1), 'user_id');
    }
    if (RegExp(r'^/stories/[^/]+$').hasMatch(path)) {
      return _deleteOwned(db, 'stories', _segment(path, 1), 'user_id');
    }
    if (RegExp(r'^/marketplace/[^/]+$').hasMatch(path)) {
      return _softDeleteOwned(
        db,
        'marketplace_items',
        _segment(path, 1),
        'seller_id',
      );
    }
    if (RegExp(r'^/friends/[^/]+$').hasMatch(path)) {
      _requireUser();
      final other = _segment(path, 1);
      await db.delete(
        'friendships',
        where:
            '(requester_id = ? AND addressee_id = ?) OR (requester_id = ? AND addressee_id = ?)',
        whereArgs: [_userId, other, other, _userId],
      );
      return const {'ok': true};
    }
    if (RegExp(r'^/groups/[^/]+/members/[^/]+$').hasMatch(path)) {
      _requireUser();
      final groupId = _segment(path, 1);
      await _requireGroupOwner(db, groupId);
      final memberId = _segment(path, 3);
      if (memberId == _userId) {
        throw LocalDataFailure(
          _t('The owner cannot be removed.', 'Không thể xóa chủ nhóm.'),
        );
      }
      await db.delete(
        'group_members',
        where: 'group_id = ? AND user_id = ?',
        whereArgs: [groupId, memberId],
      );
      return const {'ok': true};
    }
    if (RegExp(r'^/admin/users/[^/]+$').hasMatch(path)) {
      await _requireAdmin(db);
      final id = _segment(path, 2);
      if (id == _userId) {
        throw LocalDataFailure(
          _t(
            'You cannot delete your own account.',
            'Không thể xóa chính tài khoản đang dùng.',
          ),
        );
      }
      await db.update(
        'users',
        {'is_deleted': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const {'ok': true};
    }
    throw LocalDataFailure(
      _t('Feature not found.', 'Không tìm thấy chức năng.'),
      statusCode: 404,
    );
  }

  Future<dynamic> uploadFile(
    String path, {
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    if (path != '/media/upload' || (bytes == null && filePath == null)) {
      throw LocalDataFailure(_t('No file was selected.', 'Chưa chọn tệp.'));
    }
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'technet_media'));
    await directory.create(recursive: true);
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final target = File(
      p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}_$safeName',
      ),
    );
    if (bytes != null) {
      await target.writeAsBytes(bytes, flush: true);
    } else {
      await File(filePath!).copy(target.path);
    }
    final extension = p.extension(fileName).toLowerCase();
    final video = const {
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.webm',
    }.contains(extension);
    return {'url': target.path, 'mediaType': video ? 2 : 1};
  }

  Future<List<Map<String, dynamic>>> jobs({
    String? keyword,
    String? location,
    String? workType,
    String? stack,
    bool savedOnly = false,
  }) async {
    final db = await _store.database;
    final clauses = <String>['j.is_active = 1'];
    final args = <Object?>[];
    final term = keyword?.trim();
    if (term?.isNotEmpty == true) {
      clauses.add('(j.title LIKE ? OR j.company LIKE ? OR j.stack LIKE ?)');
      args.addAll(['%$term%', '%$term%', '%$term%']);
    }
    if (location?.trim().isNotEmpty == true) {
      clauses.add('j.location = ?');
      args.add(location!.trim());
    }
    if (workType?.trim().isNotEmpty == true) {
      clauses.add('j.work_type = ?');
      args.add(workType!.trim());
    }
    if (stack?.trim().isNotEmpty == true) {
      clauses.add('j.stack LIKE ?');
      args.add('%${stack!.trim()}%');
    }
    if (savedOnly) {
      _requireUser();
      clauses.add(
        'EXISTS (SELECT 1 FROM saved_jobs s WHERE s.job_id = j.id AND s.user_id = ?)',
      );
      args.add(_userId);
    }
    final rows = await db.rawQuery(
      '''
      SELECT j.*,
        EXISTS(SELECT 1 FROM saved_jobs s WHERE s.job_id = j.id AND s.user_id = ?) AS is_saved,
        EXISTS(SELECT 1 FROM job_interests i WHERE i.job_id = j.id AND i.user_id = ?) AS has_interest
      FROM jobs j
      WHERE ${clauses.join(' AND ')}
      ORDER BY j.posted_date DESC
    ''',
      [_userId ?? '', _userId ?? '', ...args],
    );
    return rows.map(_camelJob).toList();
  }

  Future<Map<String, dynamic>> adminStats() async {
    final db = await _store.database;
    await _requireAdmin(db);
    Future<int> count(String table, [String? where]) async =>
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $table${where == null ? '' : ' WHERE $where'}',
          ),
        ) ??
        0;
    return {
      'totalUsers': await count('users', 'is_deleted = 0'),
      'totalPosts': await count('posts', 'is_deleted = 0'),
      'totalComments': await count('comments', 'is_deleted = 0'),
      'totalGroups': await count('groups', 'is_deleted = 0'),
    };
  }

  Future<List<Map<String, dynamic>>> postsPerDay() async {
    final db = await _store.database;
    await _requireAdmin(db);
    return db.rawQuery('''
      SELECT substr(created_date, 1, 10) AS day, COUNT(*) AS count
      FROM posts WHERE is_deleted = 0
      GROUP BY substr(created_date, 1, 10)
      ORDER BY day DESC LIMIT 7
    ''');
  }

  Future<List<Map<String, dynamic>>> adminUsers() async {
    final db = await _store.database;
    await _requireAdmin(db);
    final rows = await db.query(
      'users',
      where: 'is_deleted = 0',
      orderBy: 'created_date DESC',
    );
    return rows.map(_userMap).toList();
  }

  Future<Map<String, dynamic>> _login(
    Database db,
    Map<String, dynamic> body,
  ) async {
    final email = '${body['email'] ?? ''}'.trim().toLowerCase();
    final password = '${body['password'] ?? ''}';
    final rows = await db.query(
      'users',
      where: 'email = ? COLLATE NOCASE AND is_deleted = 0',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty ||
        rows.first['password_hash'] !=
            LocalDatabase.passwordHash(email, password)) {
      throw LocalDataFailure(
        _t(
          'Email or password is incorrect.',
          'Email hoặc mật khẩu không đúng.',
        ),
        statusCode: 401,
      );
    }
    final user = _userMap(rows.first);
    return {'token': 'local-session:${user['id']}', 'user': user};
  }

  Future<Map<String, dynamic>> _register(
    Database db,
    Map<String, dynamic> body,
  ) async {
    final email = '${body['email'] ?? ''}'.trim().toLowerCase();
    final password = '${body['password'] ?? ''}';
    final displayName = '${body['displayName'] ?? ''}'.trim();
    if (email.isEmpty || password.length < 6 || displayName.length < 2) {
      throw LocalDataFailure(
        _t(
          'Registration information is not valid.',
          'Thông tin đăng ký chưa hợp lệ.',
        ),
      );
    }
    final id = LocalDatabase.newId('user');
    try {
      await db.insert('users', {
        'id': id,
        'email': email,
        'password_hash': LocalDatabase.passwordHash(email, password),
        'display_name': displayName,
        'bio': '',
        'role': 'User',
        'created_date': DateTime.now().toUtc().toIso8601String(),
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw LocalDataFailure(
          _t('This email is already registered.', 'Email này đã được đăng ký.'),
          statusCode: 409,
        );
      }
      rethrow;
    }
    return {'id': id};
  }

  Future<Map<String, dynamic>> _forgotPassword(
    Database db,
    Map<String, dynamic> body,
  ) async {
    final email = '${body['email'] ?? ''}'.trim().toLowerCase();
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ? COLLATE NOCASE AND is_deleted = 0',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw LocalDataFailure(
        _t('No account uses this email.', 'Không có tài khoản dùng email này.'),
        statusCode: 404,
      );
    }
    final token = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    await db.update(
      'users',
      {'reset_token': token},
      where: 'id = ?',
      whereArgs: [rows.first['id']],
    );
    return {
      'resetToken': token,
      'message': _t('Local reset code: $token', 'Mã đặt lại cục bộ: $token'),
    };
  }

  Future<Map<String, dynamic>> _resetPassword(
    Database db,
    Map<String, dynamic> body,
  ) async {
    final email = '${body['email'] ?? ''}'.trim().toLowerCase();
    final token = '${body['token'] ?? ''}'.trim();
    final password = '${body['newPassword'] ?? ''}';
    final updated = await db.update(
      'users',
      {
        'password_hash': LocalDatabase.passwordHash(email, password),
        'reset_token': null,
      },
      where: 'email = ? COLLATE NOCASE AND reset_token = ?',
      whereArgs: [email, token],
    );
    if (updated == 0) {
      throw LocalDataFailure(
        _t('The reset code is not valid.', 'Mã đặt lại không hợp lệ.'),
      );
    }
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _changePassword(
    Database db,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [_userId],
      limit: 1,
    );
    if (rows.isEmpty) throw const LocalDataFailure('User not found.');
    final email = '${rows.first['email']}';
    if (rows.first['password_hash'] !=
        LocalDatabase.passwordHash(email, '${body['currentPassword'] ?? ''}')) {
      throw LocalDataFailure(
        _t('Current password is incorrect.', 'Mật khẩu hiện tại không đúng.'),
      );
    }
    await db.update(
      'users',
      {
        'password_hash': LocalDatabase.passwordHash(
          email,
          '${body['newPassword'] ?? ''}',
        ),
      },
      where: 'id = ?',
      whereArgs: [_userId],
    );
    return const {'ok': true};
  }

  Future<List<Map<String, dynamic>>> _groups(
    Database db, {
    String? keyword,
    String? memberId,
  }) async {
    final clauses = ['g.is_deleted = 0'];
    final args = <Object?>[];
    var join = '';
    if (memberId != null) {
      join =
          'JOIN group_members mine ON mine.group_id = g.id AND mine.user_id = ?';
      args.add(memberId);
    }
    if (keyword?.trim().isNotEmpty == true) {
      clauses.add('(g.name LIKE ? OR g.description LIKE ?)');
      args.addAll(['%${keyword!.trim()}%', '%${keyword.trim()}%']);
    }
    final rows = await db.rawQuery('''
      SELECT g.*, COUNT(m.user_id) AS member_count
      FROM groups g $join LEFT JOIN group_members m ON m.group_id = g.id
      WHERE ${clauses.join(' AND ')} GROUP BY g.id ORDER BY g.created_date DESC
    ''', args);
    return rows.map(_groupMap).toList();
  }

  Future<List<Map<String, dynamic>>> _posts(
    Database db, {
    String? groupId,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT p.*, u.display_name AS author_name, u.avatar_url AS author_avatar_url,
             g.name AS group_name,
             (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id AND c.is_deleted = 0) AS comment_count,
             (SELECT COUNT(*) FROM reactions r WHERE r.post_id = p.id) AS reaction_count,
             (SELECT type FROM reactions r WHERE r.post_id = p.id AND r.user_id = ?) AS current_user_reaction
      FROM posts p JOIN users u ON u.id = p.user_id
      LEFT JOIN groups g ON g.id = p.group_id
      WHERE p.is_deleted = 0 ${groupId == null ? '' : 'AND p.group_id = ?'}
      ORDER BY p.created_date DESC
    ''',
      [_userId ?? '', if (groupId != null) groupId],
    );
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final counts = await db.rawQuery(
        'SELECT type, COUNT(*) AS count FROM reactions WHERE post_id = ? GROUP BY type',
        [row['id']],
      );
      result.add({
        ..._postMap(row),
        'reactionCounts': {
          for (final count in counts) '${count['type']}': count['count'],
        },
      });
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _comments(
    Database db,
    String postId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT c.*, u.display_name AS author_name, u.avatar_url AS author_avatar_url
      FROM comments c JOIN users u ON u.id = c.user_id
      WHERE c.post_id = ? AND c.is_deleted = 0 ORDER BY c.created_date
    ''',
      [postId],
    );
    return rows
        .map(
          (row) => {
            'id': row['id'],
            'postId': row['post_id'],
            'userId': row['user_id'],
            'authorName': row['author_name'],
            'authorAvatarUrl': row['author_avatar_url'],
            'content': row['content'],
            'createdDate': row['created_date'],
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _stories(Database db) async {
    final rows = await db.rawQuery(
      '''
      SELECT s.*, u.display_name AS author_name, u.avatar_url AS author_avatar_url,
        (SELECT COUNT(*) FROM story_reactions r WHERE r.story_id = s.id) AS reaction_count,
        (SELECT type FROM story_reactions r WHERE r.story_id = s.id AND r.user_id = ?) AS current_user_reaction
      FROM stories s JOIN users u ON u.id = s.user_id
      WHERE s.expires_at > ? ORDER BY s.created_date DESC
    ''',
      [_userId ?? '', DateTime.now().toUtc().toIso8601String()],
    );
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final counts = await db.rawQuery(
        'SELECT type, COUNT(*) AS count FROM story_reactions WHERE story_id = ? GROUP BY type',
        [row['id']],
      );
      result.add({
        'id': row['id'],
        'userId': row['user_id'],
        'authorName': row['author_name'],
        'authorAvatarUrl': row['author_avatar_url'],
        'content': row['content'],
        'mediaUrl': row['media_url'],
        'mediaType': row['media_type'],
        'createdDate': row['created_date'],
        'updatedDate': row['updated_date'],
        'expiresAt': row['expires_at'],
        'reactionCount': row['reaction_count'],
        'currentUserReaction': row['current_user_reaction'],
        'reactionCounts': {
          for (final count in counts) '${count['type']}': count['count'],
        },
      });
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _chatUsers(
    Database db, {
    String keyword = '',
  }) async {
    _requireUser();
    final rows = await db.query(
      'users',
      where:
          'id != ? AND is_deleted = 0 ${keyword.trim().isEmpty ? '' : 'AND (display_name LIKE ? OR email LIKE ?)'}',
      whereArgs: [
        _userId,
        if (keyword.trim().isNotEmpty) '%${keyword.trim()}%',
        if (keyword.trim().isNotEmpty) '%${keyword.trim()}%',
      ],
      orderBy: 'display_name',
    );
    return rows
        .map(
          (row) => {
            'id': row['id'],
            'displayName': row['display_name'],
            'avatarUrl': row['avatar_url'],
            'bio': row['bio'],
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _privateMessages(
    Database db,
    String otherId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT m.*, u.display_name AS sender_name FROM messages m JOIN users u ON u.id = m.sender_id
      WHERE m.is_group_message = 0 AND ((m.sender_id = ? AND m.receiver_id = ?) OR (m.sender_id = ? AND m.receiver_id = ?))
      ORDER BY m.created_date
    ''',
      [_userId, otherId, otherId, _userId],
    );
    return rows.map(_messageMap).toList();
  }

  Future<List<Map<String, dynamic>>> _groupMessages(
    Database db,
    String groupId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT m.*, u.display_name AS sender_name FROM messages m JOIN users u ON u.id = m.sender_id
      WHERE m.is_group_message = 1 AND m.group_id = ? ORDER BY m.created_date
    ''',
      [groupId],
    );
    return rows.map(_messageMap).toList();
  }

  Future<Map<String, dynamic>> _search(
    Database db,
    String query,
    int limit,
  ) async {
    final pattern = '%${query.trim()}%';
    final users = await db.query(
      'users',
      where: 'is_deleted = 0 AND (display_name LIKE ? OR bio LIKE ?)',
      whereArgs: [pattern, pattern],
      limit: limit,
    );
    final groups = await _groups(db, keyword: query);
    final postRows = await db.rawQuery(
      'SELECT id FROM posts WHERE is_deleted = 0 AND content LIKE ? ORDER BY created_date DESC LIMIT ?',
      [pattern, limit],
    );
    final allPosts = await _posts(db);
    final postIds = postRows.map((row) => row['id']).toSet();
    return {
      'query': query,
      'userTotal': users.length,
      'groupTotal': groups.length,
      'postTotal': postIds.length,
      'users': users.map(_userMap).toList(),
      'groups': groups.take(limit).toList(),
      'posts': allPosts
          .where((post) => postIds.contains(post['id']))
          .take(limit)
          .toList(),
    };
  }

  Future<List<Map<String, dynamic>>> _marketplace(
    Database db, {
    String? sellerId,
    String? category,
    String? keyword,
    bool includeSold = false,
  }) async {
    final clauses = ['m.is_deleted = 0', if (!includeSold) 'm.status = 0'];
    final args = <Object?>[];
    if (sellerId != null) {
      clauses.add('m.seller_id = ?');
      args.add(sellerId);
    }
    if (category?.trim().isNotEmpty == true) {
      clauses.add('m.category = ?');
      args.add(category!.trim());
    }
    if (keyword?.trim().isNotEmpty == true) {
      clauses.add('(m.title LIKE ? OR m.description LIKE ?)');
      args.addAll(['%${keyword!.trim()}%', '%${keyword.trim()}%']);
    }
    final rows = await db.rawQuery('''
      SELECT m.*, u.display_name AS seller_name, u.avatar_url AS seller_avatar_url
      FROM marketplace_items m JOIN users u ON u.id = m.seller_id
      WHERE ${clauses.join(' AND ')} ORDER BY m.created_date DESC
    ''', args);
    return rows.map(_marketMap).toList();
  }

  Future<Map<String, dynamic>> _marketplaceStats(
    Database db,
    String sellerId,
  ) async {
    final rows = await db.rawQuery(
      'SELECT status, COUNT(*) AS count FROM marketplace_items WHERE seller_id = ? AND is_deleted = 0 GROUP BY status',
      [sellerId],
    );
    var active = 0;
    var sold = 0;
    for (final row in rows) {
      if (row['status'] == 0) {
        active = _asInt(row['count']);
      } else if (row['status'] == 1) {
        sold = _asInt(row['count']);
      }
    }
    return {
      'sellerId': sellerId,
      'activeCount': active,
      'soldCount': sold,
      'limit': 5,
    };
  }

  Future<List<Map<String, dynamic>>> _achievements(
    Database db,
    String userId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT d.*, u.unlocked_at FROM achievement_definitions d
      LEFT JOIN user_achievements u ON u.code = d.code AND u.user_id = ? ORDER BY d.sort_order
    ''',
      [userId],
    );
    return rows
        .map(
          (row) => {
            'code': row['code'],
            'name': row['name'],
            'description': row['description'],
            'icon': row['icon'],
            'unlocked': row['unlocked_at'] != null,
            'unlockedAt': row['unlocked_at'],
          },
        )
        .toList();
  }

  Future<Map<String, dynamic>> _portfolio(Database db, String userId) async {
    final rows = await db.query(
      'portfolios',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return {'userId': userId};
    final row = rows.first;
    return {
      'userId': row['user_id'],
      'title': row['title'],
      'bio': row['bio'],
      'skills': row['skills'],
      'githubUrl': row['github_url'],
      'websiteUrl': row['website_url'],
      'location': row['location'],
      'featuredProjectName': row['featured_project_name'],
      'featuredProjectUrl': row['featured_project_url'],
    };
  }

  Future<List<Map<String, dynamic>>> _notifications(
    Database db,
    String userId,
  ) async {
    final rows = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_date DESC',
    );
    return rows
        .map(
          (row) => {
            'id': row['id'],
            'type': row['type'],
            'title': row['title'],
            'message': row['message'],
            'link': row['link'],
            'isRead': row['is_read'] == 1,
            'createdDate': row['created_date'],
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _friends(
    Database db,
    String userId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT u.* FROM friendships f JOIN users u ON u.id = CASE WHEN f.requester_id = ? THEN f.addressee_id ELSE f.requester_id END
      WHERE f.status = 'accepted' AND (f.requester_id = ? OR f.addressee_id = ?) AND u.is_deleted = 0
      ORDER BY u.display_name
    ''',
      [userId, userId, userId],
    );
    return rows.map(_userMap).toList();
  }

  Future<List<Map<String, dynamic>>> _friendRequests(
    Database db,
    String userId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT f.id AS request_id, f.created_date AS request_date, u.* FROM friendships f
      JOIN users u ON u.id = f.requester_id WHERE f.addressee_id = ? AND f.status = 'pending'
      ORDER BY f.created_date DESC
    ''',
      [userId],
    );
    return rows
        .map(
          (row) => {
            ..._userMap(row),
            'requestId': row['request_id'],
            'requestDate': row['request_date'],
          },
        )
        .toList();
  }

  Future<Map<String, dynamic>> _createGroup(
    Database db,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    final id = LocalDatabase.newId('group');
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert('groups', {
        'id': id,
        'name': '${body['name'] ?? ''}'.trim(),
        'description': '${body['description'] ?? ''}'.trim(),
        'avatar_url': body['avatarUrl'],
        'owner_id': _userId,
        'created_date': now,
      });
      await txn.insert('group_members', {
        'group_id': id,
        'user_id': _userId,
        'role': 0,
        'joined_date': now,
      });
    });
    await _unlock(db, _userId!, 'joined-group');
    return {'id': id};
  }

  Future<Map<String, dynamic>> _createPost(
    Database db,
    String groupId,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    _validateContent('${body['content'] ?? ''}');
    final id = LocalDatabase.newId('post');
    await db.insert('posts', {
      'id': id,
      'user_id': _userId,
      'group_id': groupId,
      'content': '${body['content'] ?? ''}',
      'media_url': body['mediaUrl'],
      'media_type': _asInt(body['mediaType']),
      'created_date': DateTime.now().toUtc().toIso8601String(),
    });
    await _unlock(db, _userId!, 'first-post');
    return {'id': id};
  }

  Future<Map<String, dynamic>> _createComment(
    Database db,
    String postId,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    _validateContent('${body['content'] ?? ''}');
    final id = LocalDatabase.newId('comment');
    await db.insert('comments', {
      'id': id,
      'post_id': postId,
      'user_id': _userId,
      'content': '${body['content'] ?? ''}'.trim(),
      'created_date': DateTime.now().toUtc().toIso8601String(),
    });
    await _notifyPostOwner(
      db,
      postId,
      'comment',
      _t('New comment', 'Bình luận mới'),
      _t(
        'Someone commented on your post.',
        'Có người vừa bình luận bài viết của bạn.',
      ),
    );
    return {'id': id};
  }

  Future<Map<String, dynamic>> _toggleReaction(
    Database db,
    String postId,
    int type,
  ) async {
    _requireUser();
    final rows = await db.query(
      'reactions',
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, _userId],
      limit: 1,
    );
    if (rows.isNotEmpty && rows.first['type'] == type) {
      await db.delete(
        'reactions',
        where: 'post_id = ? AND user_id = ?',
        whereArgs: [postId, _userId],
      );
    } else {
      await db.insert('reactions', {
        'id': LocalDatabase.newId('reaction'),
        'post_id': postId,
        'user_id': _userId,
        'type': type,
        'created_date': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await _notifyPostOwner(
      db,
      postId,
      'reaction',
      _t('New reaction', 'Cảm xúc mới'),
      _t(
        'Someone reacted to your post.',
        'Có người vừa thả cảm xúc cho bài viết của bạn.',
      ),
    );
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _createStory(
    Database db,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    _validateContent('${body['content'] ?? ''}');
    final id = LocalDatabase.newId('story');
    final now = DateTime.now().toUtc();
    await db.insert('stories', {
      'id': id,
      'user_id': _userId,
      'content': '${body['content'] ?? ''}',
      'media_url': body['mediaUrl'],
      'media_type': _asInt(body['mediaType']),
      'created_date': now.toIso8601String(),
      'expires_at': now.add(const Duration(hours: 24)).toIso8601String(),
    });
    await _unlock(db, _userId!, 'first-story');
    return {'id': id};
  }

  Future<Map<String, dynamic>> _toggleStoryReaction(
    Database db,
    String storyId,
    int type,
  ) async {
    _requireUser();
    final rows = await db.query(
      'story_reactions',
      where: 'story_id = ? AND user_id = ?',
      whereArgs: [storyId, _userId],
      limit: 1,
    );
    if (rows.isNotEmpty && rows.first['type'] == type) {
      await db.delete(
        'story_reactions',
        where: 'story_id = ? AND user_id = ?',
        whereArgs: [storyId, _userId],
      );
    } else {
      await db.insert('story_reactions', {
        'story_id': storyId,
        'user_id': _userId,
        'type': type,
        'created_date': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _replyStory(
    Database db,
    String storyId,
    String content,
  ) async {
    _requireUser();
    final rows = await db.query(
      'stories',
      columns: ['user_id'],
      where: 'id = ?',
      whereArgs: [storyId],
      limit: 1,
    );
    if (rows.isEmpty) throw const LocalDataFailure('Story not found.');
    return _sendMessage(db, {
      'receiverId': rows.first['user_id'],
      'content': content,
    });
  }

  Future<Map<String, dynamic>> _sendMessage(
    Database db,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    final id = LocalDatabase.newId('message');
    final groupId = body['groupId']?.toString();
    await db.insert('messages', {
      'id': id,
      'sender_id': _userId,
      'receiver_id': body['receiverId'],
      'group_id': groupId,
      'content': '${body['content'] ?? ''}'.trim(),
      'created_date': DateTime.now().toUtc().toIso8601String(),
      'is_group_message': groupId == null ? 0 : 1,
    });
    final sender = await db.query(
      'users',
      columns: ['display_name'],
      where: 'id = ?',
      whereArgs: [_userId],
      limit: 1,
    );
    return {
      'id': id,
      'senderId': _userId,
      'senderName': sender.first['display_name'],
      'receiverId': body['receiverId'],
      'groupId': groupId,
      'content': '${body['content'] ?? ''}'.trim(),
      'createdDate': DateTime.now().toUtc().toIso8601String(),
      'isGroupMessage': groupId != null,
    };
  }

  Future<Map<String, dynamic>> _createMarketplaceItem(
    Database db,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    final stats = await _marketplaceStats(db, _userId!);
    if (_asInt(stats['activeCount']) >= 5) {
      throw LocalDataFailure(
        _t(
          'You can have at most 5 active listings.',
          'Bạn chỉ có thể có tối đa 5 tin đang bán.',
        ),
      );
    }
    final id = LocalDatabase.newId('market');
    await db.insert('marketplace_items', _marketWrite(id, _userId!, body));
    return {'id': id};
  }

  Future<Map<String, dynamic>> _setMarketplaceStatus(
    Database db,
    String id,
    int status,
  ) async {
    _requireUser();
    await db.update(
      'marketplace_items',
      {
        'status': status,
        'updated_date': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND seller_id = ?',
      whereArgs: [id, _userId],
    );
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _groupMembership(
    Database db,
    String groupId,
    String action,
  ) async {
    _requireUser();
    if (action == 'join') {
      await db.insert('group_members', {
        'group_id': groupId,
        'user_id': _userId,
        'role': 2,
        'joined_date': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await _unlock(db, _userId!, 'joined-group');
    } else {
      final group = await db.query(
        'groups',
        columns: ['owner_id'],
        where: 'id = ?',
        whereArgs: [groupId],
        limit: 1,
      );
      if (group.isNotEmpty && group.first['owner_id'] == _userId) {
        throw LocalDataFailure(
          _t(
            'The owner cannot leave the group.',
            'Chủ nhóm không thể rời nhóm.',
          ),
        );
      }
      await db.delete(
        'group_members',
        where: 'group_id = ? AND user_id = ?',
        whereArgs: [groupId, _userId],
      );
    }
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _sendFriendRequest(
    Database db,
    String otherId,
  ) async {
    _requireUser();
    if (otherId == _userId) {
      throw const LocalDataFailure('Invalid friend request.');
    }
    await db.insert('friendships', {
      'id': LocalDatabase.newId('friend'),
      'requester_id': _userId,
      'addressee_id': otherId,
      'status': 'pending',
      'created_date': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _answerFriendRequest(
    Database db,
    String requestId,
    String action,
  ) async {
    _requireUser();
    if (action == 'accept') {
      await db.update(
        'friendships',
        {'status': 'accepted'},
        where: 'id = ? AND addressee_id = ?',
        whereArgs: [requestId, _userId],
      );
    } else {
      await db.delete(
        'friendships',
        where: 'id = ? AND addressee_id = ?',
        whereArgs: [requestId, _userId],
      );
    }
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _jobAction(
    Database db,
    String jobId,
    String action,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    final table = action == 'save' ? 'saved_jobs' : 'job_interests';
    final rows = await db.query(
      table,
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [_userId, jobId],
      limit: 1,
    );
    if (rows.isNotEmpty && action == 'save') {
      await db.delete(
        table,
        where: 'user_id = ? AND job_id = ?',
        whereArgs: [_userId, jobId],
      );
      return {'active': false};
    }
    await db.insert(table, {
      'user_id': _userId,
      'job_id': jobId,
      if (action != 'save') 'note': '${body['note'] ?? ''}',
      'created_date': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return {'active': true};
  }

  Future<Map<String, dynamic>> _updateProfile(
    Database db,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    await db.update(
      'users',
      {
        'display_name': '${body['displayName'] ?? ''}'.trim(),
        'bio': body['bio'],
        'avatar_url': body['avatarUrl'],
      },
      where: 'id = ?',
      whereArgs: [_userId],
    );
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [_userId],
      limit: 1,
    );
    return _userMap(rows.first);
  }

  Future<Map<String, dynamic>> _updatePortfolio(
    Database db,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    await db.insert('portfolios', {
      'user_id': _userId,
      'title': '${body['title'] ?? ''}',
      'bio': '${body['bio'] ?? ''}',
      'skills': '${body['skills'] ?? ''}',
      'location': body['location'],
      'github_url': body['githubUrl'],
      'website_url': body['websiteUrl'],
      'featured_project_name': body['featuredProjectName'],
      'featured_project_url': body['featuredProjectUrl'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _unlock(db, _userId!, 'portfolio-ready');
    return _portfolio(db, _userId!);
  }

  Future<Map<String, dynamic>> _updateGroup(
    Database db,
    String id,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    await db.update(
      'groups',
      {
        'name': '${body['name'] ?? ''}'.trim(),
        'description': '${body['description'] ?? ''}',
        'avatar_url': body['avatarUrl'],
      },
      where: 'id = ? AND owner_id = ?',
      whereArgs: [id, _userId],
    );
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _updatePost(
    Database db,
    String id,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    _validateContent('${body['content'] ?? ''}');
    await db.update(
      'posts',
      {
        'content': '${body['content'] ?? ''}',
        'media_url': body['mediaUrl'],
        'media_type': _asInt(body['mediaType']),
        'updated_date': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _userId],
    );
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _updateStory(
    Database db,
    String id,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    _validateContent('${body['content'] ?? ''}');
    await db.update(
      'stories',
      {
        'content': '${body['content'] ?? ''}',
        'media_url': body['mediaUrl'],
        'media_type': _asInt(body['mediaType']),
        'updated_date': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _userId],
    );
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _updateMarketplaceItem(
    Database db,
    String id,
    Map<String, dynamic> body,
  ) async {
    _requireUser();
    await db.update(
      'marketplace_items',
      {
        ..._marketWrite(id, _userId!, body),
        'updated_date': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND seller_id = ?',
      whereArgs: [id, _userId],
    );
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _softDeleteOwned(
    Database db,
    String table,
    String id,
    String ownerColumn,
  ) async {
    _requireUser();
    await db.update(
      table,
      {'is_deleted': 1},
      where: 'id = ? AND $ownerColumn = ?',
      whereArgs: [id, _userId],
    );
    return const {'ok': true};
  }

  Future<Map<String, dynamic>> _deleteOwned(
    Database db,
    String table,
    String id,
    String ownerColumn,
  ) async {
    _requireUser();
    await db.delete(
      table,
      where: 'id = ? AND $ownerColumn = ?',
      whereArgs: [id, _userId],
    );
    return const {'ok': true};
  }

  Future<void> _unlock(Database db, String userId, String code) =>
      db.insert('user_achievements', {
        'user_id': userId,
        'code': code,
        'unlocked_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
  Future<void> _notifyPostOwner(
    Database db,
    String postId,
    String type,
    String title,
    String message,
  ) async {
    final rows = await db.query(
      'posts',
      columns: ['user_id'],
      where: 'id = ?',
      whereArgs: [postId],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['user_id'] == _userId) return;
    await db.insert('notifications', {
      'id': LocalDatabase.newId('notification'),
      'user_id': rows.first['user_id'],
      'actor_id': _userId,
      'type': type,
      'title': title,
      'message': message,
      'link': '/posts/$postId',
      'created_date': DateTime.now().toUtc().toIso8601String(),
    });
    await _unlock(db, '${rows.first['user_id']}', 'got-reaction');
  }

  Future<void> _requireAdmin(Database db) async {
    _requireUser();
    final rows = await db.query(
      'users',
      columns: ['role'],
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [_userId],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['role'] != 'Admin') {
      throw LocalDataFailure(
        _t(
          'Admin access is required.',
          'Chức năng này chỉ dành cho quản trị viên.',
        ),
        statusCode: 403,
      );
    }
  }

  Future<void> _requireGroupOwner(Database db, String groupId) async {
    final rows = await db.query(
      'groups',
      columns: ['owner_id'],
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [groupId],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['owner_id'] != _userId) {
      throw LocalDataFailure(
        _t(
          'Only the group owner can manage members.',
          'Chỉ chủ nhóm được quản lý thành viên.',
        ),
        statusCode: 403,
      );
    }
  }

  void _requireUser() {
    if (_userId == null || _userId!.isEmpty || _userId == 'demo-user') {
      throw LocalDataFailure(
        _t(
          'Please sign in to use this feature.',
          'Hãy đăng nhập để dùng chức năng này.',
        ),
        statusCode: 401,
      );
    }
  }

  void _validateContent(String content) {
    if (!_contentFilter.isAllowed(content)) {
      throw LocalDataFailure(
        _t(
          'This content does not meet the community guidelines.',
          'Nội dung này chưa phù hợp với quy tắc cộng đồng.',
        ),
        statusCode: 422,
      );
    }
  }

  Map<String, dynamic> _body(Object? data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  String _segment(String path, int index) =>
      path.split('/').where((part) => part.isNotEmpty).elementAt(index);
  int _asInt(dynamic value, [int fallback = 0]) =>
      value is int ? value : int.tryParse('$value') ?? fallback;
  String _t(String en, String vi) => _english ? en : vi;

  Map<String, dynamic> _userMap(Map<String, dynamic> row) => {
    'id': row['id'],
    'userId': row['id'],
    'email': row['email'],
    'displayName': row['display_name'],
    'avatarUrl': row['avatar_url'],
    'bio': row['bio'],
    'role': row['role'],
    'createdDate': row['created_date'],
  };
  Map<String, dynamic> _groupMap(Map<String, dynamic> row) => {
    'id': row['id'],
    'name': row['name'],
    'description': row['description'],
    'avatarUrl': row['avatar_url'],
    'ownerId': row['owner_id'],
    'memberCount': row['member_count'],
    'createdDate': row['created_date'],
  };
  Map<String, dynamic> _postMap(Map<String, dynamic> row) => {
    'id': row['id'],
    'userId': row['user_id'],
    'groupId': row['group_id'],
    'groupName': row['group_name'],
    'authorName': row['author_name'],
    'authorAvatarUrl': row['author_avatar_url'],
    'content': row['content'],
    'mediaUrl': row['media_url'],
    'mediaType': row['media_type'],
    'createdDate': row['created_date'],
    'commentCount': row['comment_count'],
    'reactionCount': row['reaction_count'],
    'currentUserReaction': row['current_user_reaction'],
  };
  Map<String, dynamic> _messageMap(Map<String, dynamic> row) => {
    'id': row['id'],
    'senderId': row['sender_id'],
    'senderName': row['sender_name'],
    'receiverId': row['receiver_id'],
    'groupId': row['group_id'],
    'content': row['content'],
    'createdDate': row['created_date'],
    'isGroupMessage': row['is_group_message'] == 1,
  };
  Map<String, dynamic> _marketMap(Map<String, dynamic> row) => {
    'id': row['id'],
    'sellerId': row['seller_id'],
    'sellerName': row['seller_name'],
    'sellerAvatarUrl': row['seller_avatar_url'],
    'title': row['title'],
    'description': row['description'],
    'price': row['price'],
    'category': row['category'],
    'condition': row['item_condition'],
    'mediaUrl': row['media_url'],
    'status': row['status'],
    'createdDate': row['created_date'],
  };
  Map<String, dynamic> _marketWrite(
    String id,
    String userId,
    Map<String, dynamic> body,
  ) => {
    'id': id,
    'seller_id': userId,
    'title': '${body['title'] ?? ''}'.trim(),
    'description': '${body['description'] ?? ''}'.trim(),
    'price': body['price'] ?? 0,
    'category': '${body['category'] ?? ''}'.trim(),
    'item_condition': '${body['condition'] ?? ''}'.trim(),
    'media_url': body['mediaUrl'],
    'status': 0,
    'created_date': DateTime.now().toUtc().toIso8601String(),
  };
  Map<String, dynamic> _camelJob(Map<String, dynamic> row) => {
    'id': row['id'],
    'company': row['company'],
    'title': row['title'],
    'description': row['description'],
    'location': row['location'],
    'workType': row['work_type'],
    'level': row['level'],
    'stack': row['stack'],
    'salary': row['salary'],
    'accent': row['accent'],
    'postedDate': row['posted_date'],
    'deadline': row['deadline'],
    'isSaved': row['is_saved'] == 1,
    'hasInterest': row['has_interest'] == 1,
  };
}
