import 'package:flutter/material.dart';

import '../../core/app_copy.dart';
import '../../core/theme/app_theme.dart';
import 'common.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          return Row(
            children: [
              if (wide) const Expanded(flex: 6, child: _BrandPanel()),
              Expanded(
                flex: wide ? 5 : 1,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: wide ? 54 : 24,
                        vertical: 28,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!wide) ...[
                              const TechNetLogo(),
                              const SizedBox(height: 44),
                            ],
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(54),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5148EF), Color(0xFF736BFF), Color(0xFF22B8A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .16),
                  width: 42,
                ),
              ),
            ),
          ),
          Positioned(
            left: -100,
            bottom: -110,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: .2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WhiteLogo(),
              const Spacer(),
              Text(
                copy.isEnglish
                    ? 'Meet the right people.\nSay what matters.'
                    : 'Gặp đúng người.\nNói điều đáng nói.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 46,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                copy.isEnglish
                    ? 'An open space for communities to share, chat, and build meaningful connections.'
                    : 'Một không gian mở để cộng đồng cùng chia sẻ, trò chuyện và tạo ra những kết nối có ý nghĩa.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _BrandTag(
                    icon: Icons.diversity_3_rounded,
                    label: copy.groups,
                  ),
                  _BrandTag(icon: Icons.forum_rounded, label: copy.chat),
                  _BrandTag(
                    icon: Icons.bolt_rounded,
                    label: copy.isEnglish ? 'Realtime' : 'Theo thời gian thực',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhiteLogo extends StatelessWidget {
  const _WhiteLogo();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.graphic_eq_rounded,
          color: AppColors.indigo,
          size: 30,
        ),
      ),
      const SizedBox(width: 13),
      const Text(
        'TechNet',
        style: TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    ],
  );
}

class _BrandTag extends StatelessWidget {
  const _BrandTag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
