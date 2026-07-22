import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/trivia_models.dart';
import '../../data/providers/module_state.dart';
import '../../data/providers/trivia_provider.dart';
import '../widgets/module_states.dart';
import '../widgets/tech_lab_widgets.dart';

class DailyQuestScreen extends StatelessWidget {
  const DailyQuestScreen({super.key});

  @override
  Widget build(BuildContext context) => TechModuleScaffold(
    title: 'Daily Quest',
    actions: [
      IconButton(
        tooltip: 'Tải lại',
        onPressed: context.read<TriviaProvider>().loadDaily,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    body: Consumer<TriviaProvider>(
      builder: (context, provider, _) {
        if (provider.status == ModuleStatus.loading &&
            provider.session == null) {
          return const LoadingIndicator(label: 'Đang mở thử thách hôm nay…');
        }
        if (provider.status == ModuleStatus.error && provider.session == null) {
          return ErrorStateWidget(
            message: provider.error ?? 'Không thể tải Daily Quest.',
            onRetry: provider.loadDaily,
          );
        }
        if (provider.questions.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.quiz_outlined,
            title: 'Chưa có câu hỏi',
            message: 'Quản trị viên cần thêm ít nhất 3 câu hỏi đang hoạt động.',
            actionLabel: 'Tải lại',
            onAction: provider.loadDaily,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
          children: [
            ModuleHero(
              eyebrow: '3 câu mỗi ngày',
              title: 'Nạp XP bằng kiến thức công nghệ',
              description:
                  'Trả lời một lượt, giữ streak và mở badge theo tiến độ thật của bạn.',
              icon: Icons.bolt_rounded,
              colors: const [
                Color(0xFF073B4C),
                Color(0xFF118AB2),
                Color(0xFF6C55FF),
              ],
              trailing: _QuestStats(provider: provider),
            ),
            const SizedBox(height: 20),
            _QuestPanel(provider: provider, compact: false),
            const SizedBox(height: 24),
            const SectionTitle(
              title: 'Badge đã mở',
              subtitle: 'Các mốc được ghi trực tiếp trong SQLite.',
            ),
            const SizedBox(height: 12),
            if (provider.badges.isEmpty)
              const EmptyStateWidget(
                icon: Icons.military_tech_outlined,
                title: 'Badge đầu tiên đang chờ',
                message:
                    'Hoàn thành Daily Quest hôm nay để mở badge khởi động.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.badges.length,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: constraints.maxWidth >= 600 ? 260 : 190,
                    mainAxisExtent: 142,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (_, index) =>
                      _BadgeCard(badge: provider.badges[index]),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class DailyQuestBanner extends StatelessWidget {
  const DailyQuestBanner({super.key});

  @override
  Widget build(BuildContext context) => Consumer<TriviaProvider>(
    builder: (context, provider, _) {
      if (provider.status == ModuleStatus.initial ||
          (provider.status == ModuleStatus.loading &&
              provider.session == null)) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 14),
                Expanded(child: Text('Đang chuẩn bị Daily Quest…')),
              ],
            ),
          ),
        );
      }
      if (provider.status == ModuleStatus.error && provider.session == null) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.sync_problem_rounded, color: AppColors.coral),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(provider.error ?? 'Không thể tải Daily Quest.'),
                ),
                TextButton(
                  onPressed: provider.loadDaily,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        );
      }
      return _QuestPanel(provider: provider, compact: true);
    },
  );
}

class _QuestPanel extends StatelessWidget {
  const _QuestPanel({required this.provider, required this.compact});
  final TriviaProvider provider;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final question = provider.currentQuestion;
    final session = provider.session;
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12233F), Color(0xFF38207C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF12233F).withValues(alpha: .2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: question == null || session?.isCompleted == true
          ? _CompletedQuest(provider: provider, compact: compact)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFFFD166)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DAILY QUEST · CÂU ${session!.answeredCount + 1}/3',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/daily-quest'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        compact ? 'Mở rộng' : '${session.score} điểm',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: session.answeredCount / 3,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: Colors.white12,
                  color: const Color(0xFF7CF3D3),
                ),
                const SizedBox(height: 16),
                Text(
                  question.question,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 280;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: question.options.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: twoColumns ? 2 : 1,
                        mainAxisExtent: 48,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 9,
                      ),
                      itemBuilder: (context, index) => OutlinedButton(
                        onPressed: provider.isAnswering
                            ? null
                            : () => _submit(context, provider, question, index),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: .28),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          '${String.fromCharCode(65 + index)}. ${question.options[index]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    TriviaProvider provider,
    TriviaQuestion question,
    int index,
  ) async {
    final result = await provider.answer(question, index);
    if (!context.mounted || result == null) {
      if (context.mounted && provider.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(provider.error!)));
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.isCorrect ? 'Chính xác!' : 'Chưa đúng.'} ${result.explanation}',
        ),
        backgroundColor: result.isCorrect
            ? const Color(0xFF0B7A66)
            : Theme.of(context).colorScheme.error,
      ),
    );
    if (result.newBadges.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFFFB000),
            size: 44,
          ),
          title: const Text('Mở khóa badge mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final badge in result.newBadges)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_badgeIcon(badge.code)),
                  title: Text(
                    badge.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(badge.description),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      );
    }
  }
}

class _CompletedQuest extends StatelessWidget {
  const _CompletedQuest({required this.provider, required this.compact});
  final TriviaProvider provider;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF7CF3D3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.done_all_rounded,
          color: Color(0xFF073B4C),
          size: 32,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đã hoàn thành hôm nay',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${provider.session?.score ?? 0}/30 điểm · +${provider.session?.xpEarned ?? 0} XP · streak ${provider.profile?.currentStreak ?? 0} ngày',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      if (compact)
        IconButton(
          onPressed: () => context.push('/daily-quest'),
          color: Colors.white,
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
    ],
  );
}

class _QuestStats extends StatelessWidget {
  const _QuestStats({required this.provider});
  final TriviaProvider provider;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.end,
    children: [
      _StatPill(
        icon: Icons.bolt_rounded,
        value: '${provider.profile?.xp ?? 0} XP',
      ),
      _StatPill(
        icon: Icons.local_fire_department_rounded,
        value: '${provider.profile?.currentStreak ?? 0} ngày',
      ),
    ],
  );
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});
  final QuestBadge badge;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _badgeIcon(badge.code),
            color: const Color(0xFFFFB000),
            size: 30,
          ),
          const Spacer(),
          Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

IconData _badgeIcon(String code) => switch (code) {
  'quest-first' => Icons.bolt_rounded,
  'quest-streak-3' => Icons.local_fire_department_rounded,
  'quest-xp-100' => Icons.workspace_premium_rounded,
  'quest-perfect' => Icons.auto_awesome_rounded,
  _ => Icons.military_tech_rounded,
};
