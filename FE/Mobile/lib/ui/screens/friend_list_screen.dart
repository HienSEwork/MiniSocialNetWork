import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/friend_models.dart';
import '../../data/providers/friends_provider.dart';
import '../widgets/common.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FriendsProvider>().loadFriends();
      context.read<FriendsProvider>().loadIncomingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendsProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TechNetGradientHeader(
              title: 'Bạn bè',
              subtitle: 'Giữ kết nối với cộng đồng của bạn',
              leading: HeaderBackButton(),
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .16),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onPressed: () => context.push('/friends/requests'),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Lời mời kết bạn'),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .16),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                    ),
                    onPressed: () => context.push('/friends/search'),
                    icon: const Icon(Icons.person_add_alt_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: provider.friends.isEmpty
                    ? FriendlyState(
                        icon: Icons.people_alt_rounded,
                        title: 'Chưa có bạn bè',
                        message: 'Khám phá mọi người và mở rộng vòng kết nối của bạn.',
                        actionLabel: 'Tìm bạn bè',
                        onAction: () => context.push('/friends/search'),
                      )
                    : ListView.separated(
                        itemCount: provider.friends.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final friend = provider.friends[index];
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.push(
                                '/friends/profile',
                                extra: FriendProfileArgs(
                                  id: friend.id,
                                  displayName: friend.displayName,
                                  avatarUrl: friend.avatarUrl,
                                  subtitle: 'Bạn bè',
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    UserAvatar(
                                      label: friend.displayName,
                                      imageUrl: friend.avatarUrl,
                                      radius: 26,
                                      accent: AppColors.indigo,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            friend.displayName,
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Đã kết nối với bạn',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: () async {
                                        await provider.removeFriend(friend.id);
                                      },
                                      icon: const Icon(Icons.person_remove_alt_1_rounded),
                                      label: const Text('Xóa'),
                                    ),
                                  ],
                                ),
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
