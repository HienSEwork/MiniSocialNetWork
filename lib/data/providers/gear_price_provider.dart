import 'dart:async';

import 'package:flutter/foundation.dart';

import '../local/local_database.dart';
import '../models/gear_price_models.dart';
import '../models/session.dart';
import '../repositories/gear_price_repository.dart';
import 'module_state.dart';

class GearPriceProvider extends ChangeNotifier {
  GearPriceProvider({GearPriceRepository? repository})
    : _repository = repository ?? GearPriceRepository();

  final GearPriceRepository _repository;
  String? _userId;
  ModuleStatus _status = ModuleStatus.initial;
  String? _error;
  List<GearProduct> _products = const [];
  List<GearProduct> _adminProducts = const [];
  List<GearClosetItem> _closet = const [];
  String _query = '';
  String _category = 'Tất cả';
  GearProduct? _selectedProduct;
  double _conditionPercent = 99;
  DateTime _purchaseDate = DateTime.now().subtract(const Duration(days: 365));

  ModuleStatus get status => _status;
  String? get error => _error;
  List<GearProduct> get products => _products;
  List<GearProduct> get adminProducts => _adminProducts;
  List<GearClosetItem> get closet => _closet;
  String get query => _query;
  String get category => _category;
  GearProduct? get selectedProduct => _selectedProduct;
  double get conditionPercent => _conditionPercent;
  DateTime get purchaseDate => _purchaseDate;
  List<String> get categories => [
    'Tất cả',
    ..._products.map((item) => item.category).toSet(),
  ];
  List<GearProduct> get visibleProducts {
    final normalized = _query.trim().toLowerCase();
    return _products.where((item) {
      final categoryMatches =
          _category == 'Tất cả' || item.category == _category;
      final queryMatches =
          normalized.isEmpty ||
          item.displayName.toLowerCase().contains(normalized) ||
          item.category.toLowerCase().contains(normalized);
      return categoryMatches && queryMatches;
    }).toList();
  }

  GearEstimate? get estimate => _selectedProduct == null
      ? null
      : GearDepreciationEngine.estimate(
          msrp: _selectedProduct!.msrp,
          annualDepreciation: _selectedProduct!.annualDepreciation,
          releaseDate: _purchaseDate,
          conditionPercent: _conditionPercent,
        );

  void updateSession(UserSession? session) {
    final next = session?.userId;
    if (_userId == next) return;
    _userId = next;
    _products = const [];
    _closet = const [];
    _selectedProduct = null;
    _status = ModuleStatus.initial;
    notifyListeners();
    if (next != null) unawaited(load());
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    _status = ModuleStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.listProducts(),
        _repository.listCloset(userId),
      ]);
      if (_userId != userId) return;
      _products = results[0] as List<GearProduct>;
      _closet = results[1] as List<GearClosetItem>;
      _selectedProduct ??= _products.isEmpty ? null : _products.first;
      _status = ModuleStatus.success;
    } on ModuleDataException catch (error) {
      _status = ModuleStatus.error;
      _error = error.message;
    } catch (_) {
      _status = ModuleStatus.error;
      _error = 'Không thể tải Gear Price Checker. Hãy thử lại.';
    } finally {
      notifyListeners();
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void selectProduct(GearProduct item) {
    _selectedProduct = item;
    notifyListeners();
  }

  void setCondition(double value) {
    _conditionPercent = value.clamp(20, 100);
    notifyListeners();
  }

  void setPurchaseDate(DateTime value) {
    _purchaseDate = value;
    notifyListeners();
  }

  Future<String?> addToCloset({
    required double purchasePrice,
    String notes = '',
  }) async {
    final userId = _userId;
    final product = _selectedProduct;
    if (userId == null || product == null) return 'Hãy chọn thiết bị cần lưu.';
    final now = DateTime.now();
    final item = GearClosetItem(
      id: LocalDatabase.newId('gear'),
      userId: userId,
      productId: product.id,
      purchasePrice: purchasePrice,
      purchaseDate: _purchaseDate,
      conditionPercent: _conditionPercent,
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
      product: product,
    );
    try {
      await _repository.saveClosetItem(item);
      _closet = await _repository.listCloset(userId);
      notifyListeners();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể lưu thiết bị vào tủ đồ.';
    }
  }

  Future<String?> deleteClosetItem(String id) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      await _repository.deleteClosetItem(userId, id);
      _closet = await _repository.listCloset(userId);
      notifyListeners();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể xóa thiết bị khỏi tủ đồ.';
    }
  }

  Future<void> loadAdminProducts() async {
    try {
      _adminProducts = await _repository.listProducts(activeOnly: false);
      _error = null;
    } on ModuleDataException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Không thể tải bảng giá quản trị.';
    } finally {
      notifyListeners();
    }
  }

  Future<String?> saveProduct(GearProduct item, {required bool create}) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      if (create) {
        await _repository.createProduct(userId, item);
      } else {
        await _repository.updateProduct(userId, item);
      }
      await loadAdminProducts();
      await load();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể lưu thiết bị.';
    }
  }

  Future<String?> deleteProduct(String id) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      await _repository.deleteProduct(userId, id);
      await loadAdminProducts();
      await load();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể xóa thiết bị.';
    }
  }
}
