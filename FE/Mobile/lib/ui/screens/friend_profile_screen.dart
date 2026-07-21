import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/friend_models.dart';
import '../widgets/common.dart';

class FriendProfileScreen extends StatelessWidget {
  const FriendProfileScreen({super.key, required this.args});

  final FriendProfileArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TechNetGradientHeader(
              title: args.displayName,
              subtitle: args.subtitle ?? 'Hồ sơ',
              leading: HeaderBackButton(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    UserAvatar(
                      label: args.displayName,
                      imageUrl: args.avatarUrl,
                      radius: 44,
                      accent: AppColors.indigo,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      args.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Xem trước hồ sơ của ${args.displayName}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Quay lại bạn bè'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
