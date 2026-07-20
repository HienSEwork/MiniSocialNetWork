import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/app_copy.dart';
import '../../data/providers/community_provider.dart';
import 'community_hub_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'tech_job_screen.dart';
import '../widgets/common.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;
  int _reloadVersion = 0;

  void _selectDestination(int value) {
    if (value == _index) {
      context.read<CommunityProvider>().loadDashboard(force: true);
      setState(() => _reloadVersion++);
      return;
    }
    setState(() => _index = value);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CommunityProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final copy = AppCopy.of(context);
        final destinations = [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: copy.feed,
          ),
          NavigationDestination(
            icon: const Icon(Icons.diversity_3_outlined),
            selectedIcon: const Icon(Icons.diversity_3_rounded),
            label: copy.communityFallback,
          ),
          NavigationDestination(
            icon: const Icon(Icons.work_outline_rounded),
            selectedIcon: const Icon(Icons.work_rounded),
            label: 'Tech Job',
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_none_rounded),
            selectedIcon: const Icon(Icons.notifications_rounded),
            label: copy.activity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: copy.profile,
          ),
        ];
        final wide = constraints.maxWidth >= AppConstants.compactBreakpoint;
        final content = _LazyMainStack(
          index: _index,
          reloadVersion: _reloadVersion,
        );
        if (wide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      width: 94,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D0879), Color(0xFF6C55FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .14),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: TechNetLogo(compact: true),
                          ),
                          Expanded(
                            child: NavigationRail(
                              backgroundColor: Colors.transparent,
                              indicatorColor: Colors.white.withValues(
                                alpha: .18,
                              ),
                              selectedIconTheme: const IconThemeData(
                                color: Colors.white,
                              ),
                              unselectedIconTheme: const IconThemeData(
                                color: Colors.white70,
                              ),
                              selectedLabelTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                              unselectedLabelTextStyle: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              labelType: NavigationRailLabelType.all,
                              selectedIndex: _index,
                              onDestinationSelected: _selectDestination,
                              destinations: destinations
                                  .map(
                                    (item) => NavigationRailDestination(
                                      icon: item.icon,
                                      selectedIcon: item.selectedIcon,
                                      label: Text(item.label),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          extendBody: true,
          body: content,
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D0879).withValues(alpha: .16),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF7A68FF),
                        Color(0xFF5436E8),
                        Color(0xFF35106F),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    selectedIndex: _index,
                    onDestinationSelected: _selectDestination,
                    destinations: destinations,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LazyMainStack extends StatefulWidget {
  const _LazyMainStack({required this.index, required this.reloadVersion});

  final int index;
  final int reloadVersion;

  @override
  State<_LazyMainStack> createState() => _LazyMainStackState();
}

class _LazyMainStackState extends State<_LazyMainStack> {
  final Set<int> _visited = {0};

  @override
  void didUpdateWidget(covariant _LazyMainStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var index = 0; index < 5; index++)
          if (_visited.contains(index))
            Offstage(
              offstage: widget.index != index,
              child: TickerMode(
                enabled: widget.index == index,
                child: _buildPage(index),
              ),
            ),
      ],
    );
  }

  Widget _buildPage(int index) => switch (index) {
    0 => HomeScreen(key: ValueKey('home-${widget.reloadVersion}')),
    1 => CommunityHubScreen(key: ValueKey('community-${widget.reloadVersion}')),
    2 => TechJobScreen(key: ValueKey('tech-job-${widget.reloadVersion}')),
    3 => NotificationsScreen(key: ValueKey('activity-${widget.reloadVersion}')),
    _ => ProfileScreen(key: ValueKey('profile-${widget.reloadVersion}')),
  };
}
