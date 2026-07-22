import 'package:sqflite/sqflite.dart';

import '../local/local_database.dart';
import '../models/gear_price_models.dart';
import '../providers/module_state.dart';

class GearPriceRepository {
  GearPriceRepository({LocalDatabase? database})
    : _store = database ?? LocalDatabase.instance;

  final LocalDatabase _store;

  Future<List<GearProduct>> listProducts({bool activeOnly = true}) async {
    try {
      final db = await _store.database;
      final rows = await db.query(
        'gear_products',
        where: activeOnly ? 'is_active = 1' : null,
        orderBy: 'category ASC, brand ASC, model ASC',
      );
      return rows.map(GearProduct.fromMap).toList();
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể tải bảng giá thiết bị.', error);
    } catch (error) {
      throw ModuleDataException('Dữ liệu thiết bị không hợp lệ.', error);
    }
  }

  Future<List<GearClosetItem>> listCloset(String userId) async {
    try {
      final db = await _store.database;
      final rows = await db.query(
        'gear_closet',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'updated_at DESC',
      );
      final result = <GearClosetItem>[];
      for (final row in rows) {
        final item = GearClosetItem.fromMap(row);
        final productRows = await db.query(
          'gear_products',
          where: 'id = ?',
          whereArgs: [item.productId],
          limit: 1,
        );
        result.add(
          item.copyWith(
            product: productRows.isEmpty
                ? null
                : GearProduct.fromMap(productRows.first),
          ),
        );
      }
      return result;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể tải tủ thiết bị cá nhân.', error);
    } catch (error) {
      throw ModuleDataException('Dữ liệu tủ thiết bị không hợp lệ.', error);
    }
  }

  Future<GearClosetItem> saveClosetItem(GearClosetItem item) async {
    try {
      final db = await _store.database;
      await db.insert(
        'gear_closet',
        item.databaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return item;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể lưu thiết bị vào tủ đồ.', error);
    }
  }

  Future<void> deleteClosetItem(String userId, String id) async {
    try {
      final db = await _store.database;
      final changed = await db.delete(
        'gear_closet',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
      if (changed == 0) {
        throw const ModuleDataException('Không tìm thấy thiết bị cần xóa.');
      }
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể xóa thiết bị khỏi tủ đồ.', error);
    }
  }

  Future<void> createProduct(String adminUserId, GearProduct product) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      await db.insert('gear_products', product.toMap());
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể thêm thiết bị vào bảng giá.', error);
    }
  }

  Future<void> updateProduct(String adminUserId, GearProduct product) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      final changed = await db.update(
        'gear_products',
        product.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
      if (changed == 0) {
        throw const ModuleDataException('Không tìm thấy thiết bị.');
      }
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể cập nhật bảng giá.', error);
    }
  }

  Future<void> deleteProduct(String adminUserId, String id) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      final used =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM gear_closet WHERE product_id = ?',
              [id],
            ),
          ) ??
          0;
      if (used > 0) {
        await db.update(
          'gear_products',
          {
            'is_active': 0,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.delete('gear_products', where: 'id = ?', whereArgs: [id]);
      }
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể xóa thiết bị khỏi bảng giá.', error);
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
