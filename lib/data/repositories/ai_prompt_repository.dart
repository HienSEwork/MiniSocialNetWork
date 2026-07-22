import 'package:sqflite/sqflite.dart';

import '../local/local_database.dart';
import '../models/ai_prompt_models.dart';
import '../providers/module_state.dart';

class AiPromptRepository {
  AiPromptRepository({LocalDatabase? database})
    : _store = database ?? LocalDatabase.instance;

  final LocalDatabase _store;

  Future<List<AiPromptTemplate>> listTemplates(
    String userId, {
    bool activeOnly = true,
  }) async {
    try {
      final db = await _store.database;
      final rows = await db.rawQuery(
        '''
          SELECT p.*,
                 CASE WHEN b.prompt_id IS NULL THEN 0 ELSE 1 END AS is_bookmarked
          FROM ai_prompt_templates p
          LEFT JOIN prompt_bookmarks b
            ON b.prompt_id = p.id AND b.user_id = ?
          ${activeOnly ? 'WHERE p.is_active = 1' : ''}
          ORDER BY p.platform ASC, p.title ASC
        ''',
        [userId],
      );
      return rows.map(AiPromptTemplate.fromMap).toList();
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể tải thư viện AI prompt.', error);
    } catch (error) {
      throw ModuleDataException('Dữ liệu prompt không hợp lệ.', error);
    }
  }

  Future<bool> toggleBookmark(String userId, String promptId) async {
    try {
      final db = await _store.database;
      final existing = await db.query(
        'prompt_bookmarks',
        where: 'user_id = ? AND prompt_id = ?',
        whereArgs: [userId, promptId],
        limit: 1,
      );
      if (existing.isEmpty) {
        await db.insert(
          'prompt_bookmarks',
          PromptBookmark(
            userId: userId,
            promptId: promptId,
            createdAt: DateTime.now(),
          ).toMap(),
        );
        return true;
      }
      await db.delete(
        'prompt_bookmarks',
        where: 'user_id = ? AND prompt_id = ?',
        whereArgs: [userId, promptId],
      );
      return false;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể cập nhật prompt đã lưu.', error);
    }
  }

  Future<void> createTemplate(
    String adminUserId,
    AiPromptTemplate template,
  ) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      await db.insert('ai_prompt_templates', template.databaseMap());
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể thêm prompt.', error);
    }
  }

  Future<void> updateTemplate(
    String adminUserId,
    AiPromptTemplate template,
  ) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      final changed = await db.update(
        'ai_prompt_templates',
        template.copyWith(updatedAt: DateTime.now()).databaseMap(),
        where: 'id = ?',
        whereArgs: [template.id],
      );
      if (changed == 0) {
        throw const ModuleDataException('Không tìm thấy prompt.');
      }
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể cập nhật prompt.', error);
    }
  }

  Future<void> deleteTemplate(String adminUserId, String id) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      await db.delete('ai_prompt_templates', where: 'id = ?', whereArgs: [id]);
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể xóa prompt.', error);
    }
  }

  Future<void> _requireAdmin(DatabaseExecutor db, String userId) async {
    final rows = await db.query(
      'users',
      columns: ['role'],
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['role'] != 'Admin') {
      throw const ModuleDataException(
        'Bạn không có quyền quản trị module này.',
      );
    }
  }
}
