import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ai_prompt_models.dart';
import '../models/session.dart';
import '../repositories/ai_prompt_repository.dart';
import 'module_state.dart';

class AiLibraryProvider extends ChangeNotifier {
  AiLibraryProvider({AiPromptRepository? repository})
    : _repository = repository ?? AiPromptRepository();

  final AiPromptRepository _repository;
  String? _userId;
  ModuleStatus _status = ModuleStatus.initial;
  String? _error;
  List<AiPromptTemplate> _templates = const [];
  List<AiPromptTemplate> _adminTemplates = const [];
  String _query = '';
  String _platform = 'Tất cả';
  bool _bookmarksOnly = false;

  ModuleStatus get status => _status;
  String? get error => _error;
  List<AiPromptTemplate> get templates => _templates;
  List<AiPromptTemplate> get adminTemplates => _adminTemplates;
  String get query => _query;
  String get platform => _platform;
  bool get bookmarksOnly => _bookmarksOnly;
  List<String> get platforms => [
    'Tất cả',
    ..._templates.map((item) => item.platform).toSet(),
  ];
  List<AiPromptTemplate> get visibleTemplates {
    final normalized = _query.trim().toLowerCase();
    return _templates.where((item) {
      final platformMatches =
          _platform == 'Tất cả' || item.platform == _platform;
      final bookmarkMatches = !_bookmarksOnly || item.isBookmarked;
      final queryMatches =
          normalized.isEmpty ||
          item.title.toLowerCase().contains(normalized) ||
          item.description.toLowerCase().contains(normalized) ||
          item.category.toLowerCase().contains(normalized);
      return platformMatches && bookmarkMatches && queryMatches;
    }).toList();
  }

  void updateSession(UserSession? session) {
    final next = session?.userId;
    if (_userId == next) return;
    _userId = next;
    _templates = const [];
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
      _templates = await _repository.listTemplates(userId);
      _status = ModuleStatus.success;
    } on ModuleDataException catch (error) {
      _status = ModuleStatus.error;
      _error = error.message;
    } catch (_) {
      _status = ModuleStatus.error;
      _error = 'Không thể tải thư viện AI prompt. Hãy thử lại.';
    } finally {
      notifyListeners();
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setPlatform(String value) {
    _platform = value;
    notifyListeners();
  }

  void setBookmarksOnly(bool value) {
    _bookmarksOnly = value;
    notifyListeners();
  }

  Future<String?> toggleBookmark(AiPromptTemplate template) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      final selected = await _repository.toggleBookmark(userId, template.id);
      _templates = _templates
          .map(
            (item) => item.id == template.id
                ? item.copyWith(isBookmarked: selected)
                : item,
          )
          .toList();
      notifyListeners();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể cập nhật prompt đã lưu.';
    }
  }

  String buildPrompt(AiPromptTemplate template, Map<String, String> values) =>
      PromptTemplateEngine.build(template.template, values);

  Future<void> loadAdminTemplates() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      _adminTemplates = await _repository.listTemplates(
        userId,
        activeOnly: false,
      );
      _error = null;
    } on ModuleDataException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Không thể tải danh mục prompt.';
    } finally {
      notifyListeners();
    }
  }

  Future<String?> saveTemplate(
    AiPromptTemplate item, {
    required bool create,
  }) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      if (create) {
        await _repository.createTemplate(userId, item);
      } else {
        await _repository.updateTemplate(userId, item);
      }
      await loadAdminTemplates();
      await load();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể lưu prompt.';
    }
  }

  Future<String?> deleteTemplate(String id) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      await _repository.deleteTemplate(userId, id);
      await loadAdminTemplates();
      await load();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể xóa prompt.';
    }
  }
}
