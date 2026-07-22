import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/session.dart';
import '../models/trivia_models.dart';
import '../repositories/trivia_repository.dart';
import 'module_state.dart';

class TriviaProvider extends ChangeNotifier {
  TriviaProvider({TriviaRepository? repository})
    : _repository = repository ?? TriviaRepository();

  final TriviaRepository _repository;
  String? _userId;
  ModuleStatus _status = ModuleStatus.initial;
  String? _error;
  List<TriviaQuestion> _questions = const [];
  TriviaDailySession? _session;
  QuestProfile? _profile;
  List<QuestBadge> _badges = const [];
  Set<String> _answeredQuestionIds = const {};
  TriviaAnswerResult? _lastResult;
  bool _isAnswering = false;
  List<TriviaQuestion> _adminQuestions = const [];

  ModuleStatus get status => _status;
  String? get error => _error;
  List<TriviaQuestion> get questions => _questions;
  TriviaDailySession? get session => _session;
  QuestProfile? get profile => _profile;
  List<QuestBadge> get badges => _badges;
  Set<String> get answeredQuestionIds => _answeredQuestionIds;
  TriviaAnswerResult? get lastResult => _lastResult;
  bool get isAnswering => _isAnswering;
  List<TriviaQuestion> get adminQuestions => _adminQuestions;
  TriviaQuestion? get currentQuestion {
    for (final question in _questions) {
      if (!_answeredQuestionIds.contains(question.id)) return question;
    }
    return null;
  }

  void updateSession(UserSession? session) {
    final nextId = session?.userId;
    if (_userId == nextId) return;
    _userId = nextId;
    _reset();
    if (nextId != null) unawaited(loadDaily());
  }

  Future<void> loadDaily() async {
    final userId = _userId;
    if (userId == null) return;
    _status = ModuleStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final data = await _repository.loadDaily(userId);
      if (_userId != userId) return;
      _questions = data.questions;
      _session = data.session;
      _profile = data.profile;
      _badges = data.badges;
      _answeredQuestionIds = data.answeredQuestionIds;
      _status = ModuleStatus.success;
    } on ModuleDataException catch (error) {
      _status = ModuleStatus.error;
      _error = error.message;
    } catch (_) {
      _status = ModuleStatus.error;
      _error = 'Không thể tải Daily Quest. Hãy thử lại.';
    } finally {
      notifyListeners();
    }
  }

  Future<TriviaAnswerResult?> answer(
    TriviaQuestion question,
    int selectedIndex,
  ) async {
    final userId = _userId;
    if (userId == null || _isAnswering) return null;
    _isAnswering = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.answer(
        userId: userId,
        questionId: question.id,
        selectedIndex: selectedIndex,
      );
      _lastResult = result;
      _session = result.session;
      _profile = result.profile;
      _answeredQuestionIds = {..._answeredQuestionIds, question.id};
      _badges = [...result.newBadges, ..._badges];
      _status = ModuleStatus.success;
      return result;
    } on ModuleDataException catch (error) {
      _error = error.message;
      return null;
    } catch (_) {
      _error = 'Không thể lưu câu trả lời. Hãy thử lại.';
      return null;
    } finally {
      _isAnswering = false;
      notifyListeners();
    }
  }

  void clearLastResult() {
    _lastResult = null;
    notifyListeners();
  }

  Future<void> loadAdminQuestions() async {
    try {
      _adminQuestions = await _repository.listAllQuestions();
      _error = null;
    } on ModuleDataException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Không thể tải ngân hàng câu hỏi.';
    } finally {
      notifyListeners();
    }
  }

  Future<String?> saveQuestion(
    TriviaQuestion question, {
    required bool create,
  }) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      if (create) {
        await _repository.createQuestion(userId, question);
      } else {
        await _repository.updateQuestion(userId, question);
      }
      await loadAdminQuestions();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể lưu câu hỏi.';
    }
  }

  Future<String?> deleteQuestion(String id) async {
    final userId = _userId;
    if (userId == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      await _repository.deleteQuestion(userId, id);
      await loadAdminQuestions();
      return null;
    } on ModuleDataException catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể xóa câu hỏi.';
    }
  }

  void _reset() {
    _status = ModuleStatus.initial;
    _error = null;
    _questions = const [];
    _session = null;
    _profile = null;
    _badges = const [];
    _answeredQuestionIds = const {};
    _lastResult = null;
    _adminQuestions = const [];
    notifyListeners();
  }
}
