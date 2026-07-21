import 'package:flutter/foundation.dart';

import 'auth_provider.dart';
import '../models/friend_models.dart';
import '../services/api_service.dart';

class FriendsProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  AuthProvider? _auth;

  List<FriendSummary> _friends = [];
  List<FriendRequestSummary> _incomingRequests = [];
  List<FriendSearchResult> _recommendations = [];
  List<FriendSearchResult> _searchResults = [];
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;
  bool _isLoadingRecommendations = false;
  bool _isSearching = false;
  String? _error;

  List<FriendSummary> get friends => _friends;
  List<FriendRequestSummary> get incomingRequests => _incomingRequests;
  List<FriendSearchResult> get recommendations => _recommendations;
  List<FriendSearchResult> get searchResults => _searchResults;
  bool get isLoadingFriends => _isLoadingFriends;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  bool get isSearching => _isSearching;
  String? get error => _error;

  void bindAuth(AuthProvider auth) {
    _auth = auth;
    if (auth.isInitialized && auth.isAuthenticated) {
      refresh();
    }
  }

  Future<void> refresh() async {
    if (_auth?.isAuthenticated != true) return;
    await Future.wait([
      loadFriends(),
      loadIncomingRequests(),
      loadRecommendations(),
    ]);
  }

  Future<void> loadFriends() async {
    if (_auth?.isAuthenticated != true) return;
    _isLoadingFriends = true;
    notifyListeners();
    try {
      final raw = await _api.get('/friends');
      final data = raw is List ? raw : const [];
      _friends = data
          .whereType<Map>()
          .map((item) => FriendSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _error = null;
    } on ApiFailure catch (error) {
      _error = error.message;
    } finally {
      _isLoadingFriends = false;
      notifyListeners();
    }
  }

  Future<void> loadIncomingRequests() async {
    if (_auth?.isAuthenticated != true) return;
    _isLoadingRequests = true;
    notifyListeners();
    try {
      final raw = await _api.get('/friends/requests');
      final data = raw is List ? raw : const [];
      _incomingRequests = data
          .whereType<Map>()
          .map((item) => FriendRequestSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _error = null;
    } on ApiFailure catch (error) {
      _error = error.message;
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendations({int take = 20}) async {
    if (_auth?.isAuthenticated != true) return;
    _isLoadingRecommendations = true;
    notifyListeners();
    try {
      final raw = await _api.get('/friends/recommendations', queryParameters: {'take': take});
      final data = raw is List ? raw : const [];
      _recommendations = data
          .whereType<Map>()
          .map((item) => FriendSearchResult.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _error = null;
    } on ApiFailure catch (error) {
      _error = error.message;
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String keyword) async {
    final query = keyword.trim();
    _isSearching = true;
    notifyListeners();
    try {
      if (query.isEmpty) {
        _searchResults = [];
        _error = null;
        _isSearching = false;
        notifyListeners();
        return;
      }
      final raw = await _api.get('/friends/search', queryParameters: {'keyword': query});
      final data = raw is List ? raw : const [];
      _searchResults = data
          .whereType<Map>()
          .map((item) => FriendSearchResult.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _error = null;
    } on ApiFailure catch (error) {
      _error = error.message;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    try {
      await _api.post('/friends/requests/$userId');
      await loadRecommendations();
      await searchUsers('');
      _error = null;
    } on ApiFailure catch (error) {
      _error = error.message;
      notifyListeners();
    }
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    try {
      await _api.post('/friends/requests/$requestId/respond', data: {'accept': accept});
      await loadIncomingRequests();
      await loadFriends();
      _error = null;
    } on ApiFailure catch (error) {
      _error = error.message;
      notifyListeners();
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await _api.delete('/friends/$friendId');
      _friends.removeWhere((item) => item.id == friendId);
      _error = null;
      notifyListeners();
    } on ApiFailure catch (error) {
      _error = error.message;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _error = null;
    notifyListeners();
  }
}
