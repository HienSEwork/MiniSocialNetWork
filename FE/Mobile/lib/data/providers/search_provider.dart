import 'package:flutter/foundation.dart';

import '../models/search_models.dart';
import '../services/api_service.dart';

class SearchProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  GlobalSearchResult? _result;
  String _query = '';
  String? _error;
  bool _isLoading = false;
  int _requestId = 0;

  GlobalSearchResult? get result => _result;
  String get query => _query;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get hasQuery => _query.trim().length >= 2;

  Future<void> search(String value) async {
    final query = value.trim();
    _query = query;
    final requestId = ++_requestId;

    if (query.length < 2) {
      _result = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await _api.get(
        '/search',
        queryParameters: {'q': query, 'limit': 12},
      );
      if (requestId != _requestId) return;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      _result = GlobalSearchResult.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    } on ApiFailure catch (error) {
      if (requestId != _requestId) return;
      _error = error.message;
      _result = null;
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    _requestId++;
    _query = '';
    _result = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
