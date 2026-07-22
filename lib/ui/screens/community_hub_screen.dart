import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';
import 'friends_screen.dart';
import 'groups_screen.dart';
import 'marketplace_screen.dart';

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 104;
    final spaces = [
      _Space(
        title: 'Kết nối',
        eyebrow: 'PEOPLE',
        description: 'Bạn bè, lời mời mới và thành viên cùng mối quan tâm.',
        icon: Icons.handshake_rounded,
        color: AppColors.mint,
        builder: (_) => const FriendsScreen(),
      ),
      _Space(
        title: 'Tin nhắn',
        eyebrow: 'INBOX',
        description: 'Tiếp tục cuộc trò chuyện riêng hoặc chat trong nhóm.',
        icon: Icons.chat_bubble_rounded,
        color: AppColors.coral,
        builder: (_) => const ChatScreen(),
      ),
      _Space(
        title: 'Nhóm chuyên môn',
        eyebrow: 'CIRCLES',
        description: 'Tham gia, tạo nhóm và chia sẻ bài viết theo chủ đề.',
        icon: Icons.diversity_3_rounded,
        color: AppColors.indigo,
        builder: (_) => const GroupsScreen(),
      ),
      _Space(
        title: 'Marketplace',
        eyebrow: 'TECH GEAR',
        description: 'Đăng bán đồ công nghệ và quản lý gian cá nhân.',
        icon: Icons.storefront_rounded,
        color: AppColors.grape,
        builder: (_) => const MarketplaceScreen(),
      ),
    ];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: TechNetGradientHeader(
              title: 'Cộng đồng',
              subtitle: 'Bốn không gian, một nhịp trò chuyện',
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, bottom),
            sliver: SliverList.separated(
              itemCount: spaces.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => ResponsivePage(
                child: _SpaceCard(
                  space: spaces[index],
                  index: index,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: spaces[index].builder)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Space {
  const _Space({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.icon,
    required this.color,
    required this.builder,
  });
  final String title;
  final String eyebrow;
  final String description;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.space,
    required this.index,
    required this.onTap,
  });
  final _Space space;
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 7, color: space.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: space.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(space.icon, color: space.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(index + 1).toString().padLeft(2, '0')} / ${space.eyebrow}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: space.color,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            space.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            space.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
