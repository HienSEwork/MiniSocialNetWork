import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/hardware_models.dart';
import '../models/session.dart';
import '../repositories/hardware_repository.dart';
import 'module_state.dart';

class PcBuilderProvider extends ChangeNotifier {
  PcBuilderProvider({HardwareRepository? repository})
    : _repository = repository ?? HardwareRepository();

  final HardwareRepository _repository;
  String? _userId;
  ModuleStatus _status = ModuleStatus.initial;
  String? _error;
  List<HardwareComponent> _components = const [];
  List<HardwareComponent> _adminComponents = const [];
  List<PcBuild> _savedBuilds = const [];
  final Map<String, HardwareComponent> _selected = {};
  bool _isSaving = false;

  ModuleStatus get status => _status;
  String? get error => _error;
  List<HardwareComponent> get components => _components;
  List<HardwareComponent> get adminComponents => _adminComponents;
  List<PcBuild> get savedBuilds => _savedBuilds;
  Map<String, HardwareComponent> get selected => Map.unmodifiable(_selected);
  bool get isSaving => _isSaving;
  PcCompatibilityResult get compatibility =>
      PcCompatibilityEngine.evaluate(_selected);

  void updateSession(UserSession? session) {
    final next = session?.userId;
    if (_userId == next) return;
    _userId = next;
    _selected.clear();
    _components = const [];
    _savedBuilds = const [];
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
        _repository.listComponents(),
        _repository.listBuilds(userId),
      ]);
      if (_userId != userId) return;
      _components = results[0] as List<HardwareComponent>;
      _savedBuilds = results[1] as List<PcBuild>;
      _status = ModuleStatus.success;
    } on ModuleDataException catch (error) {
      _status = ModuleStatus.error;
      _error = error.message;
    } catch (_) {
      _status = ModuleStatus.error;
      _error = 'Không thể tải PC Builder. Hãy thử lại.';
    } finally {
      notifyListeners();
    }
  }

  List<HardwareComponent> componentsFor(String slot) => _components
      .where((component) => component.type == slot && component.isActive)
      .toList();

  void select(String slot, HardwareComponent component) {
    if (component.type != slot) return;
    _selected[slot] = component;
    notifyListeners();
  }

  void remove(String slot) {
    _selected.remove(slot);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  void editBuild(PcBuild build) {
    _selected
      ..clear()
      ..addAll(build.components);
    notifyListeners();
  }

  Future<String?> saveBuild(String name, {String? buildId}) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.saveBuild(
        userId: userId,
        name: name,
        components: _selected,
        buildId: buildId,
      );
      _savedBuilds = await _repository.listBuilds(userId);
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể lưu cấu hình PC.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteBuild(String id) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      await _repository.deleteBuild(userId, id);
      _savedBuilds = await _repository.listBuilds(userId);
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể xóa cấu hình PC.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadAdminComponents() async {
    try {
      _adminComponents = await _repository.listComponents(activeOnly: false);
      _error = null;
    } on ModuleDataException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Không thể tải danh mục linh kiện.';
    } finally {
      notifyListeners();
    }
  }

  Future<String?> saveComponent(
    HardwareComponent item, {
    required bool create,
  }) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      if (create) {
        await _repository.createComponent(userId, item);
      } else {
        await _repository.updateComponent(userId, item);
      }
      await loadAdminComponents();
      await load();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể lưu linh kiện.';
    }
  }

  Future<String?> deleteComponent(String id) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      await _repository.deleteComponent(userId, id);
      await loadAdminComponents();
      await load();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể xóa linh kiện.';
    }
  }
}
