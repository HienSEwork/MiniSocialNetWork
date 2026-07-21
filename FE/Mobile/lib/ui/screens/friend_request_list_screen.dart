import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/friend_models.dart';
import '../../data/providers/friends_provider.dart';
import '../widgets/common.dart';

class FriendRequestListScreen extends StatefulWidget {
  const FriendRequestListScreen({super.key});

  @override
  State<FriendRequestListScreen> createState() => _FriendRequestListScreenState();
}

class _FriendRequestListScreenState extends State<FriendRequestListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
              title: 'Lời mời kết bạn',
              subtitle: 'Chấp nhận hoặc từ chối lời mời đến',
              leading: HeaderBackButton(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: provider.incomingRequests.isEmpty
                    ? FriendlyState(
                        icon: Icons.mark_email_unread_rounded,
                        title: 'Chưa có lời mời nào',
                        message: 'Các lời mời kết bạn mới sẽ xuất hiện ở đây.',
                      )
                    : ListView.separated(
                        itemCount: provider.incomingRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final request = provider.incomingRequests[index];
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
                                        id: request.requesterId,
                                        displayName: request.requesterName,
                                        avatarUrl: request.requesterAvatarUrl,
                                        subtitle: 'Đã gửi lời mời kết bạn',
                                      ),
                                    ),
                                    child: UserAvatar(
                                      label: request.requesterName,
                                      imageUrl: request.requesterAvatarUrl,
                                      radius: 26,
                                      accent: AppColors.coral,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.requesterName,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Đã gửi cho bạn một lời mời kết bạn',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      FilledButton.icon(
                                        onPressed: () async {
                                          await provider.respondToRequest(request.id, true);
                                        },
                                        icon: const Icon(Icons.check_rounded),
                                        label: const Text('Chấp nhận'),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          await provider.respondToRequest(request.id, false);
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                        label: const Text('Từ chối'),
                                      ),
                                    ],
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
