import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'common.dart';

class TechModuleScaffold extends StatelessWidget {
  const TechModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(title),
      actions: actions,
    ),
    body: ResponsivePage(maxWidth: 980, child: body),
    floatingActionButton: floatingActionButton,
  );
}

class ModuleHero extends StatelessWidget {
  const ModuleHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: colors.first.withValues(alpha: .22),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .82),
                height: 1.4,
              ),
            ),
          ],
        );
        final mark = Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 38),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  mark,
                  if (trailing != null) ...[const Spacer(), trailing!],
                ],
              ),
              const SizedBox(height: 18),
              copy,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: copy),
            const SizedBox(width: 24),
            trailing ?? mark,
          ],
        );
      },
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

String formatVnd(num value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${buffer.toString()} ₫';
}

Color moduleSurface(BuildContext context, Color accent) =>
    Theme.of(context).brightness == Brightness.dark
    ? accent.withValues(alpha: .12)
    : accent.withValues(alpha: .07);

class TechLabLauncher extends StatelessWidget {
  const TechLabLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    const modules = [
      _ModuleLink(
        'PC Builder',
        'Socket + PSU',
        Icons.memory_rounded,
        Color(0xFFFF6B6B),
        '/pc-builder',
      ),
      _ModuleLink(
        'AI Prompt Lab',
        'Biến → prompt',
        Icons.auto_awesome_rounded,
        Color(0xFF8A3FFC),
        '/ai-library',
      ),
      _ModuleLink(
        'Gear Price',
        'Giá mua / bán',
        Icons.price_check_rounded,
        Color(0xFFFF8A5B),
        '/gear-price',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TECH LAB',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.coral,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modules.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final module = modules[index];
              return SizedBox(
                width: 168,
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push(module.route),
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: moduleSurface(context, module.color),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(module.icon, color: module.color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  module.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModuleLink {
  const _ModuleLink(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.route,
  );
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}
