import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/app_copy.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/marketplace_model.dart';
import '../../data/models/portfolio_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/community_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/services/local_data_service.dart';
import '../widgets/common.dart';
import 'marketplace_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final session = auth.session;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final copy = AppCopy.of(context);
    final achievementKey = GlobalKey();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TechNetGradientHeader(
              title: copy.profile,
              subtitle: session?.email ?? copy.member,
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        UserAvatar(
                          label: auth.displayName,
                          imageUrl: session?.avatarUrl,
                          radius: 34,
                          accent: AppColors.coral,
                        ),
                        const SizedBox(width: 17),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                session?.isGuest == true
                                    ? copy.exploreMode
                                    : session?.bio?.isNotEmpty == true
                                    ? session!.bio!
                                    : session?.email ?? copy.member,
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
                        IconButton.filledTonal(
                          tooltip: copy.editProfile,
                          onPressed: () => editProfileSheet(context),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: KeyedSubtree(
                  key: achievementKey,
                  child: _AchievementSection(
                    userId: session?.userId,
                    isGuest: session?.isGuest == true,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: _PortfolioSection(
                  userId: session?.userId,
                  editable: session?.isGuest != true,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: _MarketplaceSection(
                  userId: session?.userId,
                  editable: session?.isGuest != true,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: Text(
                  copy.app,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: dark,
                        onChanged: settings.toggleTheme,
                        secondary: Icon(
                          dark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                        ),
                        title: Text(copy.darkMode),
                        subtitle: Text(copy.darkModeHint),
                      ),
                      const Divider(height: 1, indent: 64),
                      ListTile(
                        leading: const Icon(Icons.emoji_events_outlined),
                        title: const Text('Achievement'),
                        subtitle: const Text('Badges va tien do ca nhan'),
                        trailing: const Icon(Icons.keyboard_arrow_up_rounded),
                        onTap: () {
                          final target = achievementKey.currentContext;
                          if (target == null) return;
                          Scrollable.ensureVisible(
                            target,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      ListTile(
                        leading: const Icon(Icons.lock_reset_rounded),
                        title: const Text('Change password'),
                        subtitle: const Text('Doi mat khau tai khoan'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        enabled: session?.isGuest != true,
                        onTap: () => showChangePasswordSheet(context),
                      ),
                      const Divider(height: 1, indent: 64),
                      ListTile(
                        leading: const Icon(Icons.storefront_outlined),
                        title: const Text('Marketplace'),
                        subtitle: const Text('San mua ban do tech'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/marketplace'),
                      ),
                      if (session?.email == 'admin@minisocial.local') ...[
                        const Divider(height: 1, indent: 64),
                        ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings_outlined,
                          ),
                          title: const Text('Quản trị cộng đồng'),
                          subtitle: const Text(
                            'Thống kê và quản lý thành viên',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/admin'),
                        ),
                      ],
                      const Divider(height: 1, indent: 64),
                      ListTile(
                        leading: const Icon(Icons.translate_rounded),
                        title: Text(copy.language),
                        subtitle: Text(
                          settings.isEnglish ? 'English' : 'Tiếng Việt',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => chooseLanguageSheet(context, settings),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  22,
                  22,
                  MediaQuery.paddingOf(context).bottom + 110,
                ),
                child: OutlinedButton.icon(
                  onPressed: auth.logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text(copy.signOut),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceSection extends StatefulWidget {
  const _MarketplaceSection({required this.userId, required this.editable});

  final String? userId;
  final bool editable;

  @override
  State<_MarketplaceSection> createState() => _MarketplaceSectionState();
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({
    required this.icon,
    required this.message,
    required this.comingSoon,
  });

  final IconData icon;
  final String message;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final color = comingSoon
        ? AppColors.indigo
        : Theme.of(context).colorScheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: comingSoon ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MarketplaceSectionState extends State<_MarketplaceSection> {
  List<MarketplaceItem> _items = const [];
  MarketplaceStats? _stats;
  bool _loading = false;
  String? _error;
  bool _comingSoon = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final itemsRaw = widget.editable
          ? await LocalDataService.instance.get('/marketplace/mine')
          : await LocalDataService.instance.get('/marketplace/seller/$userId');
      final statsRaw = widget.editable
          ? await LocalDataService.instance.get('/marketplace/mine/stats')
          : await LocalDataService.instance.get(
              '/marketplace/seller/$userId/stats',
            );
      _items = _list(itemsRaw).map(MarketplaceItem.fromJson).toList();
      _stats = MarketplaceStats.fromJson(Map<String, dynamic>.from(statsRaw));
      _error = null;
      _comingSoon = false;
    } on LocalDataFailure catch (error) {
      _comingSoon = error.statusCode == 404;
      _error = _comingSoon ? 'Tính năng sắp ra mắt.' : error.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront_outlined, color: AppColors.grape),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sàn cá nhân',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (stats != null)
                  Text(
                    '${stats.activeCount}/${stats.limit} • Đã bán ${stats.soldCount}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              _SectionMessage(
                icon: Icons.upcoming_outlined,
                message: _error!,
                comingSoon: _comingSoon,
              )
            else if (_items.isEmpty)
              Text(
                'Chưa có sản phẩm trên sàn cá nhân.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Column(
                children: [
                  for (final item in _items.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MarketplaceItemCard(item: item, onChanged: _load),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _comingSoon
                        ? () => showUnavailable(context, 'Sàn cá nhân')
                        : () => context.push('/marketplace'),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Mở sàn'),
                  ),
                ),
                if (widget.editable) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _comingSoon
                          ? () => showUnavailable(context, 'Đăng bán')
                          : stats != null && stats.activeCount >= stats.limit
                          ? null
                          : () async {
                              await showMarketplaceItemSheet(context);
                              await _load();
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Đăng bán'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

class _AchievementSection extends StatefulWidget {
  const _AchievementSection({required this.userId, required this.isGuest});

  final String? userId;
  final bool isGuest;

  @override
  State<_AchievementSection> createState() => _AchievementSectionState();
}

class _AchievementSectionState extends State<_AchievementSection> {
  List<UserAchievement> _achievements = const [];
  bool _loading = false;
  String? _error;
  bool _comingSoon = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final raw = widget.isGuest
          ? await LocalDataService.instance.get(
              '/profiles/$userId/achievements',
            )
          : await LocalDataService.instance.get('/achievements/me');
      _achievements = _list(raw).map(UserAchievement.fromJson).toList();
      _error = null;
      _comingSoon = false;
    } on LocalDataFailure catch (error) {
      _comingSoon = error.statusCode == 404;
      _error = _comingSoon ? 'Tính năng sắp ra mắt.' : error.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _achievements.where((item) => item.unlocked).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: AppColors.coral),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thành tích',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_achievements.isNotEmpty)
                  Text(
                    '$unlocked/${_achievements.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              _SectionMessage(
                icon: Icons.upcoming_outlined,
                message: _error!,
                comingSoon: _comingSoon,
              )
            else if (_achievements.isEmpty)
              Text(
                'Chưa có dữ liệu thành tích.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final achievement in _achievements)
                    _AchievementBadge(achievement: achievement),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement});

  final UserAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final active = achievement.unlocked;
    final color = active ? AppColors.coral : Colors.grey;
    return Tooltip(
      message: achievement.description,
      child: AnimatedOpacity(
        opacity: active ? 1 : .42,
        duration: const Duration(milliseconds: 180),
        child: Container(
          width: 104,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? .12 : .08),
            border: Border.all(color: color.withValues(alpha: .28)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_achievementIcon(achievement.icon), color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                achievement.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: active
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _achievementIcon(String name) => switch (name) {
    'edit_note' => Icons.edit_note_rounded,
    'auto_awesome' => Icons.auto_awesome_rounded,
    'groups' => Icons.groups_rounded,
    'workspaces' => Icons.workspaces_rounded,
    'favorite' => Icons.favorite_rounded,
    _ => Icons.emoji_events_rounded,
  };
}

class _PortfolioSection extends StatefulWidget {
  const _PortfolioSection({required this.userId, required this.editable});

  final String? userId;
  final bool editable;

  @override
  State<_PortfolioSection> createState() => _PortfolioSectionState();
}

class _PortfolioSectionState extends State<_PortfolioSection> {
  UserPortfolio? _portfolio;
  bool _loading = false;
  String? _error;
  bool _comingSoon = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final raw = await LocalDataService.instance.get(
        '/profiles/$userId/portfolio',
      );
      _portfolio = UserPortfolio.fromJson(Map<String, dynamic>.from(raw));
      _error = null;
      _comingSoon = false;
    } on LocalDataFailure catch (error) {
      _comingSoon = error.statusCode == 404;
      _error = _comingSoon ? 'Tính năng sắp ra mắt.' : error.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = _portfolio;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspaces_outline, color: AppColors.indigo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Portfolio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.editable)
                  IconButton.filledTonal(
                    onPressed: _comingSoon
                        ? () => showUnavailable(context, 'Portfolio')
                        : portfolio == null
                        ? null
                        : () async {
                            await _editPortfolio(context, portfolio);
                            await _load();
                          },
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              _SectionMessage(
                icon: Icons.upcoming_outlined,
                message: _error!,
                comingSoon: _comingSoon,
              )
            else if (portfolio == null || portfolio.isEmpty)
              Text(
                'Chưa có portfolio. Thêm vai trò, kỹ năng và project nổi bật.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                portfolio.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (portfolio.location?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(portfolio.location!),
              ],
              if (portfolio.bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(portfolio.bio),
              ],
              if (portfolio.skillList.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in portfolio.skillList)
                      Chip(label: Text(skill)),
                  ],
                ),
              ],
              if (portfolio.featuredProjectName?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_special_outlined),
                  title: Text(portfolio.featuredProjectName!),
                  subtitle: Text(portfolio.featuredProjectUrl ?? ''),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editPortfolio(
    BuildContext context,
    UserPortfolio portfolio,
  ) async {
    final title = TextEditingController(text: portfolio.title);
    final bio = TextEditingController(text: portfolio.bio);
    final skills = TextEditingController(text: portfolio.skills);
    final location = TextEditingController(text: portfolio.location);
    final github = TextEditingController(text: portfolio.githubUrl);
    final website = TextEditingController(text: portfolio.websiteUrl);
    final project = TextEditingController(text: portfolio.featuredProjectName);
    final projectUrl = TextEditingController(
      text: portfolio.featuredProjectUrl,
    );
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chỉnh portfolio',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bio,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Giới thiệu'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: skills,
                  decoration: const InputDecoration(
                    labelText: 'Kỹ năng, cách nhau bằng dấu phẩy',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(labelText: 'Địa điểm'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: github,
                  decoration: const InputDecoration(labelText: 'GitHub'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: website,
                  decoration: const InputDecoration(labelText: 'Website'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: project,
                  decoration: const InputDecoration(
                    labelText: 'Project nổi bật',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: projectUrl,
                  decoration: const InputDecoration(labelText: 'Link project'),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          setSheetState(() => saving = true);
                          try {
                            await LocalDataService.instance.put(
                              '/profiles/me/portfolio',
                              data: {
                                'title': title.text,
                                'bio': bio.text,
                                'skills': skills.text,
                                'location': location.text,
                                'githubUrl': github.text,
                                'websiteUrl': website.text,
                                'featuredProjectName': project.text,
                                'featuredProjectUrl': projectUrl.text,
                              },
                            );
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            showResultMessage(context, 'Đã lưu portfolio.');
                          } on LocalDataFailure catch (error) {
                            if (!sheetContext.mounted) return;
                            setSheetState(() => saving = false);
                            showResultMessage(
                              sheetContext,
                              error.message,
                              error: true,
                            );
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text('Lưu portfolio'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> editProfileSheet(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final copy = AppCopy.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final community = context.read<CommunityProvider>();
  if (auth.session?.isGuest == true) {
    showResultMessage(context, copy.loginToEdit, error: true);
    return;
  }

  final name = TextEditingController(text: auth.displayName);
  final bio = TextEditingController(text: auth.session?.bio);
  var avatarUrl = auth.session?.avatarUrl ?? '';
  var avatarName = '';
  var uploading = false;
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          22,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.editProfile,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Center(
                child: UserAvatar(
                  label: name.text,
                  imageUrl: avatarUrl,
                  radius: 46,
                  accent: AppColors.coral,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: uploading || saving
                    ? null
                    : () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 88,
                          maxWidth: 1200,
                        );
                        if (image == null) return;
                        setSheetState(() => uploading = true);
                        String? result;
                        try {
                          result = await auth.uploadAvatar(
                            fileName: image.name,
                            filePath: image.path,
                            bytes: await image.readAsBytes(),
                          );
                        } catch (error) {
                          result = '$error';
                        }
                        if (!sheetContext.mounted) return;
                        setSheetState(() => uploading = false);
                        final uploadedUrl = result;
                        if (uploadedUrl == null || uploadedUrl.isEmpty) {
                          showResultMessage(
                            sheetContext,
                            copy.uploadFailed,
                            error: true,
                          );
                        } else {
                          setSheetState(() {
                            avatarUrl = uploadedUrl;
                            avatarName = image.name;
                          });
                        }
                      },
                icon: uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(avatarName.isEmpty ? copy.chooseImage : avatarName),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                enabled: !saving,
                decoration: InputDecoration(labelText: copy.displayName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bio,
                enabled: !saving,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: copy.bio),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: saving || uploading
                    ? null
                    : () async {
                        final navigator = Navigator.of(sheetContext);
                        setSheetState(() => saving = true);
                        final error = await auth.updateProfile(
                          displayName: name.text,
                          bio: bio.text,
                          avatarUrl: avatarUrl,
                        );
                        if (!sheetContext.mounted) return;
                        if (error == null) {
                          await community.loadDashboard(force: true);
                          if (!sheetContext.mounted) return;
                          navigator.pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            auth.notifyProfileChanged();
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.ink,
                                content: Text(copy.profileUpdated),
                              ),
                            );
                          });
                        } else {
                          setSheetState(() => saving = false);
                          showResultMessage(sheetContext, error, error: true);
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text(copy.saveChanges),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> chooseLanguageSheet(
  BuildContext context,
  SettingsProvider settings,
) async {
  final code = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: RadioGroup<String>(
        groupValue: settings.locale.languageCode,
        onChanged: (value) => Navigator.pop(sheetContext, value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            RadioListTile<String>(value: 'vi', title: Text('Tiếng Việt')),
            RadioListTile<String>(value: 'en', title: Text('English')),
          ],
        ),
      ),
    ),
  );
  if (code != null) await settings.setLanguage(code);
}

Future<void> showChangePasswordSheet(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  var saving = false;
  var obscureCurrent = true;
  var obscureNext = true;
  var obscureConfirm = true;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          18,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Change password',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: current,
                label: 'Current password',
                obscure: obscureCurrent,
                onToggle: () =>
                    setSheetState(() => obscureCurrent = !obscureCurrent),
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: next,
                label: 'New password',
                obscure: obscureNext,
                onToggle: () => setSheetState(() => obscureNext = !obscureNext),
              ),
              const SizedBox(height: 10),
              _PasswordField(
                controller: confirm,
                label: 'Confirm new password',
                obscure: obscureConfirm,
                onToggle: () =>
                    setSheetState(() => obscureConfirm = !obscureConfirm),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        if (next.text != confirm.text) {
                          showResultMessage(
                            sheetContext,
                            'Mat khau xac nhan khong khop.',
                            error: true,
                          );
                          return;
                        }
                        setSheetState(() => saving = true);
                        final error = await auth.changePassword(
                          currentPassword: current.text,
                          newPassword: next.text,
                        );
                        if (!sheetContext.mounted) return;
                        setSheetState(() => saving = false);
                        if (error == null) {
                          Navigator.pop(sheetContext);
                          showResultMessage(context, 'Da doi mat khau.');
                        } else {
                          showResultMessage(sheetContext, error, error: true);
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Save password'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: obscure ? 'Show password' : 'Hide password',
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}
