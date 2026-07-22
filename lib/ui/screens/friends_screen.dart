import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/local_data_service.dart';
import '../widgets/common.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _friends = const [];
  List<Map<String, dynamic>> _requests = const [];
  List<Map<String, dynamic>> _people = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        LocalDataService.instance.get('/friends'),
        LocalDataService.instance.get('/friends/requests'),
        LocalDataService.instance.get(
          '/chat/users',
          queryParameters: {'keyword': _search.text.trim()},
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _friends = _list(results[0]);
        _requests = _list(results[1]);
        _people = _list(results[2]);
      });
    } on LocalDataFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _list(dynamic raw) => raw is List
      ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Kết nối'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Bạn bè · ${_friends.length}'),
            Tab(text: 'Lời mời · ${_requests.length}'),
            const Tab(text: 'Khám phá'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Tìm người trong cộng đồng',
                prefixIcon: const Icon(Icons.person_search_rounded),
                suffixIcon: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _error != null
                ? FriendlyState(
                    icon: Icons.people_outline_rounded,
                    title: 'Chưa tải được kết nối',
                    message: _error!,
                    actionLabel: 'Thử lại',
                    onAction: _load,
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _PeopleList(
                        people: _friends,
                        emptyTitle: 'Danh sách bạn bè đang trống',
                        action: (person) => OutlinedButton(
                          onPressed: () => _removeFriend(person),
                          child: const Text('Xóa'),
                        ),
                      ),
                      _PeopleList(
                        people: _requests,
                        emptyTitle: 'Không có lời mời mới',
                        action: (person) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Từ chối',
                              onPressed: () => _answer(person, false),
                              icon: const Icon(Icons.close_rounded),
                            ),
                            const SizedBox(width: 6),
                            IconButton.filled(
                              tooltip: 'Đồng ý',
                              onPressed: () => _answer(person, true),
                              icon: const Icon(Icons.check_rounded),
                            ),
                          ],
                        ),
                      ),
                      _PeopleList(
                        people: _discoverable,
                        emptyTitle: 'Không còn gợi ý phù hợp',
                        action: (person) => FilledButton.tonalIcon(
                          onPressed: () => _request(person),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Kết nối'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _discoverable {
    final friendIds = _friends.map((e) => '${e['id']}').toSet();
    return _people
        .where((person) => !friendIds.contains('${person['id']}'))
        .toList();
  }

  Future<void> _removeFriend(Map<String, dynamic> person) async {
    await _act(
      () => LocalDataService.instance.delete('/friends/${person['id']}'),
    );
  }

  Future<void> _request(Map<String, dynamic> person) async {
    await _act(
      () => LocalDataService.instance.post('/friends/${person['id']}/request'),
      message: 'Đã gửi lời mời kết nối.',
    );
  }

  Future<void> _answer(Map<String, dynamic> person, bool accept) async {
    await _act(
      () => LocalDataService.instance.post(
        '/friends/requests/${person['requestId']}/${accept ? 'accept' : 'decline'}',
      ),
      message: accept ? 'Đã thêm vào danh sách bạn bè.' : 'Đã từ chối lời mời.',
    );
  }

  Future<void> _act(
    Future<dynamic> Function() action, {
    String? message,
  }) async {
    try {
      await action();
      if (mounted && message != null) showResultMessage(context, message);
      await _load();
    } on LocalDataFailure catch (error) {
      if (mounted) showResultMessage(context, error.message, error: true);
    }
  }
}

class _PeopleList extends StatelessWidget {
  const _PeopleList({
    required this.people,
    required this.emptyTitle,
    required this.action,
  });
  final List<Map<String, dynamic>> people;
  final String emptyTitle;
  final Widget Function(Map<String, dynamic>) action;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return FriendlyState(
        icon: Icons.waving_hand_outlined,
        title: emptyTitle,
        message: 'TechNet sẽ gợi ý thêm khi cộng đồng có hoạt động mới.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(height: 9),
        itemBuilder: (context, index) {
          final person = people[index];
          final name = '${person['displayName'] ?? 'Thành viên TechNet'}';
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              leading: UserAvatar(
                label: name,
                imageUrl: person['avatarUrl']?.toString(),
                accent: index.isEven ? AppColors.mint : AppColors.coral,
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${person['bio'] ?? 'Đang khám phá cộng đồng TechNet'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: action(person),
            ),
          );
        },
      ),
    );
  }
}
