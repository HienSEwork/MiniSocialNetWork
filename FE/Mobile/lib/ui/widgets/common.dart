import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_copy.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/settings_provider.dart';

class TechNetLogo extends StatelessWidget {
  const TechNetLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
          decoration: BoxDecoration(
            color: AppColors.indigo,
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo.withValues(alpha: .28),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(
            Icons.hub_rounded,
            color: Colors.white,
            size: compact ? 23 : 28,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Text(
            AppConstants.appName,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ],
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.radius = 22,
    this.accent = AppColors.indigo,
  });

  final String label;
  final String? imageUrl;
  final double radius;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? 'T' : label.trim()[0].toUpperCase();
    final url = imageUrl?.trim();
    final image = url?.isNotEmpty == true
        ? url!.startsWith('assets/')
              ? AssetImage(url) as ImageProvider
              : NetworkImage(url)
        : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: accent.withValues(alpha: .14),
      foregroundImage: image,
      onForegroundImageError: image == null ? null : (_, __) {},
      child: Text(
        initial,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w900,
          fontSize: radius * .72,
        ),
      ),
    );
  }
}

/// Owns [TextEditingController]s for a subtree (e.g. a modal bottom sheet) and
/// disposes them when the subtree is unmounted. This avoids disposing a
/// controller while the sheet is still animating out and being rebuilt, which
/// otherwise throws "A TextEditingController was used after being disposed".
class DisposeScope extends StatefulWidget {
  const DisposeScope({
    super.key,
    required this.controllers,
    required this.child,
  });

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<DisposeScope> createState() => _DisposeScopeState();
}

class _DisposeScopeState extends State<DisposeScope> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.child,
    this.maxWidth = AppConstants.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class TechNetGradientHeader extends StatelessWidget {
  const TechNetGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.violet, AppColors.grape, AppColors.electric],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsivePage(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      if (subtitle?.isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FriendlyState extends StatelessWidget {
  const FriendlyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 54),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 34, color: AppColors.indigo),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class TechNetSideDrawer extends StatelessWidget {
  const TechNetSideDrawer({super.key, required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final copy = AppCopy.of(context);
    final name = auth.displayName;
    final email = auth.session?.email ?? copy.member;
    final items = [
      _DrawerItem(Icons.home_outlined, copy.feed, 0),
      _DrawerItem(Icons.diversity_3_outlined, copy.groups, 1),
      _DrawerItem(Icons.forum_outlined, copy.chat, 2),
      _DrawerItem(Icons.notifications_none_rounded, copy.activity, 3),
      _DrawerItem(Icons.person_outline_rounded, copy.profile, 4),
    ];

    return Drawer(
      width: 292,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7A68FF), Color(0xFF5436E8), Color(0xFF35106F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  label: name,
                  imageUrl: auth.session?.avatarUrl,
                  radius: 34,
                  accent: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: .68)),
                ),
                const SizedBox(height: 26),
                for (final item in items)
                  _DrawerTile(
                    icon: item.icon,
                    label: item.label,
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(item.index);
                    },
                  ),
                _DrawerTile(
                  icon: Icons.qr_code_2_rounded,
                  label: 'QR Code',
                  onTap: () => showUnavailable(context, 'QR Code'),
                ),
                _DrawerTile(
                  icon: Icons.search_rounded,
                  label: copy.search,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/search');
                  },
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      settings.themeMode == ThemeMode.dark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        copy.darkMode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch(
                      value: settings.themeMode == ThemeMode.dark,
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.white24,
                      onChanged: settings.toggleTheme,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: .34),
                    ),
                  ),
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(copy.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.icon, this.label, this.index);

  final IconData icon;
  final String label;
  final int index;
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minLeadingWidth: 28,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white.withValues(alpha: .76)),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

void showUnavailable(BuildContext context, String feature) {
  final copy = AppCopy.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(copy.unavailable(feature)),
      action: SnackBarAction(label: copy.understood, onPressed: () {}),
    ),
  );
}

void showResultMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: error
          ? Theme.of(context).colorScheme.error
          : AppColors.ink,
      content: Text(message),
    ),
  );
}
