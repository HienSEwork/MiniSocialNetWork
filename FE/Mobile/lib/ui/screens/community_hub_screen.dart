import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/common.dart';
import 'groups_screen.dart';
import 'marketplace_screen.dart';

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 104;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TechNetGradientHeader(
              title: 'Cong dong',
              subtitle: 'Marketplace, nhom va cac khong gian TechNet',
              trailing: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.grape,
                ),
                tooltip: 'Mo chat',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
                ),
                icon: const Icon(Icons.storefront_rounded),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, bottom),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                ResponsivePage(
                  child: _CommunityFeatureCard(
                    title: 'Marketplace',
                    subtitle:
                        'Dang ban do tech, xem san ca nhan va thong ke da ban.',
                    icon: Icons.storefront_rounded,
                    colors: const [AppColors.coral, AppColors.lavender],
                    primaryLabel: 'Mo san',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MarketplaceScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ResponsivePage(
                  child: _CommunityFeatureCard(
                    title: 'Nhom',
                    subtitle:
                        'Quan ly nhom da tham gia, tao nhom va vao bai viet nhom.',
                    icon: Icons.diversity_3_rounded,
                    colors: const [AppColors.violet, AppColors.electric],
                    primaryLabel: 'Mo nhom',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GroupsScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ResponsivePage(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.mint.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.tips_and_updates_rounded,
                              color: AppColors.mint,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sap co module moi',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Event, Q&A va vote se nam trong khu Cong dong.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityFeatureCard extends StatelessWidget {
  const _CommunityFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.primaryLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final String primaryLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: .20),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.grape,
                      ),
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(primaryLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
