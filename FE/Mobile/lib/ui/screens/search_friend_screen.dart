import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/friend_models.dart';
import '../../data/providers/friends_provider.dart';
import '../widgets/common.dart';

class SearchFriendScreen extends StatefulWidget {
  const SearchFriendScreen({super.key});

  @override
  State<SearchFriendScreen> createState() => _SearchFriendScreenState();
}

class _SearchFriendScreenState extends State<SearchFriendScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FriendsProvider>().loadRecommendations();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      context.read<FriendsProvider>().clearSearch();
      context.read<FriendsProvider>().loadRecommendations();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<FriendsProvider>().searchUsers(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendsProvider>();
    final items = _controller.text.trim().isEmpty
        ? provider.recommendations
        : provider.searchResults;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TechNetGradientHeader(
              title: 'Tìm bạn bè',
              subtitle: 'Khám phá các kết nối mới',
              leading: HeaderBackButton(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: TextField(
                controller: _controller,
                onChanged: (value) {
                  setState(() {});
                  _onChanged(value);
                },
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc ID người dùng',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                            context.read<FriendsProvider>().clearSearch();
                            context.read<FriendsProvider>().loadRecommendations();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: provider.isSearching || provider.isLoadingRecommendations
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? FriendlyState(
                            icon: Icons.explore_rounded,
                            title: 'Chưa có gợi ý nào',
                            message: 'Hãy thử từ khóa khác hoặc quay lại sau.',
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = items[index];
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(999),
                                        onTap: () => context.push(
                                          '/friends/profile',
                                          extra: FriendProfileArgs(
                                            id: user.id,
                                            displayName: user.displayName,
                                            avatarUrl: user.avatarUrl,
                                            subtitle: 'Gợi ý kết bạn',
                                          ),
                                        ),
                                        child: UserAvatar(
                                          label: user.displayName,
                                          imageUrl: user.avatarUrl,
                                          radius: 26,
                                          accent: AppColors.mint,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.displayName,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${user.mutualFriends} bạn chung • ${user.sharedGroups} nhóm chung',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () async {
                                          await provider.sendFriendRequest(user.id);
                                        },
                                        icon: const Icon(Icons.person_add_alt_1_rounded),
                                        label: const Text('Kết bạn'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
