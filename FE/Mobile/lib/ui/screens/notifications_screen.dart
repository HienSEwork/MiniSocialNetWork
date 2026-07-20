import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_copy.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/chat_provider.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<ChatProvider>();
    final copy = AppCopy.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TechNetGradientHeader(
              title: copy.activity,
              subtitle: realtime.isRealtimeConnected
                  ? copy.realtimeActive
                  : copy.realtimeWaiting,
              trailing: Icon(
                realtime.isRealtimeConnected
                    ? Icons.wifi_tethering_rounded
                    : Icons.sync_problem_rounded,
                color: Colors.white,
              ),
            ),
          ),
          if (realtime.notifications.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: FriendlyState(
                icon: Icons.mark_email_read_outlined,
                title: copy.activityEmptyTitle,
                message: copy.activityEmptyHint,
              ),
            )
          else
            SliverList.separated(
              itemCount: realtime.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 78),
              itemBuilder: (context, index) {
                final item = realtime.notifications[index];
                final type = '${item['type'] ?? 'activity'}';
                final reaction = type.contains('reaction');
                return ResponsivePage(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 7,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          (reaction ? AppColors.coral : AppColors.indigo)
                              .withValues(alpha: .12),
                      child: Icon(
                        reaction
                            ? Icons.favorite_rounded
                            : Icons.mode_comment_rounded,
                        color: reaction ? AppColors.coral : AppColors.indigo,
                      ),
                    ),
                    title: Text(
                      reaction ? copy.newReaction : copy.newComment,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(copy.justReceived),
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}
