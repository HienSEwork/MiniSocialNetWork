import 'package:sqflite/sqflite.dart';

import '../local/local_database.dart';
import '../models/hardware_models.dart';
import '../providers/module_state.dart';

class HardwareRepository {
  HardwareRepository({LocalDatabase? database})
    : _store = database ?? LocalDatabase.instance;

  final LocalDatabase _store;

  Future<List<HardwareComponent>> listComponents({
    bool activeOnly = true,
  }) async {
    try {
      final db = await _store.database;
      final rows = await db.query(
        'hardware_components',
        where: activeOnly ? 'is_active = 1' : null,
        orderBy: 'component_type ASC, price ASC',
      );
      return rows.map(HardwareComponent.fromMap).toList();
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể tải linh kiện PC.', error);
    } catch (error) {
      throw ModuleDataException('Dữ liệu linh kiện không hợp lệ.', error);
    }
  }

  Future<List<PcBuild>> listBuilds(String userId) async {
    try {
      final db = await _store.database;
      final rows = await db.query(
        'pc_builds',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'updated_at DESC',
      );
      final builds = <PcBuild>[];
      for (final row in rows) {
        final build = PcBuild.fromMap(row);
        final componentRows = await db.rawQuery(
          '''
            SELECT i.slot, h.*
            FROM pc_build_items i
            JOIN hardware_components h ON h.id = i.component_id
            WHERE i.build_id = ?
            ORDER BY i.slot ASC
          ''',
          [build.id],
        );
        final components = <String, HardwareComponent>{};
        for (final componentRow in componentRows) {
          components['${componentRow['slot']}'] = HardwareComponent.fromMap(
            componentRow,
          );
        }
        builds.add(build.copyWith(components: components));
      }
      return builds;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể tải cấu hình đã lưu.', error);
    } catch (error) {
      throw ModuleDataException('Dữ liệu cấu hình không hợp lệ.', error);
    }
  }

  Future<PcBuild> saveBuild({
    required String userId,
    required String name,
    required Map<String, HardwareComponent> components,
    String? buildId,
  }) async {
    try {
      final result = PcCompatibilityEngine.evaluate(components);
      if (!result.isComplete) {
        throw const ModuleDataException(
          'Hãy chọn đủ 6 linh kiện trước khi lưu.',
        );
      }
      final db = await _store.database;
      final now = DateTime.now().toUtc();
      final id = buildId ?? LocalDatabase.newId('pc-build');
      final existing = await db.query(
        'pc_builds',
        columns: ['created_at'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
        limit: 1,
      );
      final build = PcBuild(
        id: id,
        userId: userId,
        name: name.trim().isEmpty ? 'Cấu hình của tôi' : name.trim(),
        totalCost: result.totalCost,
        totalWatt: result.totalWatt,
        isCompatible: result.isCompatible,
        createdAt: existing.isEmpty
            ? now
            : DateTime.tryParse('${existing.first['created_at']}') ?? now,
        updatedAt: now,
        components: Map.unmodifiable(components),
      );
      await db.transaction((txn) async {
        await txn.insert(
          'pc_builds',
          build.databaseMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.delete(
          'pc_build_items',
          where: 'build_id = ?',
          whereArgs: [id],
        );
        for (final entry in components.entries) {
          await txn.insert('pc_build_items', {
            'build_id': id,
            'slot': entry.key,
            'component_id': entry.value.id,
          });
        }
      });
      return build;
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể lưu cấu hình PC.', error);
    } catch (error) {
      throw ModuleDataException('Không thể xử lý cấu hình PC.', error);
    }
  }

  Future<void> deleteBuild(String userId, String buildId) async {
    try {
      final db = await _store.database;
      final changed = await db.delete(
        'pc_builds',
        where: 'id = ? AND user_id = ?',
        whereArgs: [buildId, userId],
      );
      if (changed == 0) {
        throw const ModuleDataException('Không tìm thấy cấu hình cần xóa.');
      }
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể xóa cấu hình PC.', error);
    }
  }

  Future<void> createComponent(
    String adminUserId,
    HardwareComponent component,
  ) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      await db.insert('hardware_components', component.toMap());
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể thêm linh kiện.', error);
    }
  }

  Future<void> updateComponent(
    String adminUserId,
    HardwareComponent component,
  ) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      final changed = await db.update(
        'hardware_components',
        component.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [component.id],
      );
      if (changed == 0) {
        throw const ModuleDataException('Không tìm thấy linh kiện.');
      }
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể cập nhật linh kiện.', error);
    }
  }

  Future<void> deleteComponent(String adminUserId, String id) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      final used =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM pc_build_items WHERE component_id = ?',
              [id],
            ),
          ) ??
          0;
      if (used > 0) {
        await db.update(
          'hardware_components',
          {
            'is_active': 0,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.delete(
          'hardware_components',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể xóa linh kiện.', error);
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
