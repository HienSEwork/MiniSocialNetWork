import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/common.dart';

class TechJobScreen extends StatelessWidget {
  const TechJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 104;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: TechNetGradientHeader(
              title: 'Tech Job',
              subtitle: 'Viec lam, thuc tap va co hoi cong nghe',
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, bottom),
            sliver: SliverList.separated(
              itemCount: _jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  ResponsivePage(child: _JobCard(job: _jobs[index])),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final _DemoJob job;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: job.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(job.icon, color: job.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        job.company,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _JobChip(text: job.type),
                _JobChip(text: job.level),
                _JobChip(text: job.salary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobChip extends StatelessWidget {
  const _JobChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      visualDensity: VisualDensity.compact,
      backgroundColor: AppColors.indigo.withValues(alpha: .08),
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: AppColors.grape,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DemoJob {
  const _DemoJob({
    required this.title,
    required this.company,
    required this.type,
    required this.level,
    required this.salary,
    required this.icon,
    required this.color,
  });

  final String title;
  final String company;
  final String type;
  final String level;
  final String salary;
  final IconData icon;
  final Color color;
}

const _jobs = [
  _DemoJob(
    title: 'Flutter Developer',
    company: 'TechNet Labs - Remote',
    type: 'Full-time',
    level: 'Junior/Mid',
    salary: '18-35M',
    icon: Icons.phone_iphone_rounded,
    color: AppColors.indigo,
  ),
  _DemoJob(
    title: 'AI Engineer Intern',
    company: 'Cloud AI Studio - Ha Noi',
    type: 'Intern',
    level: 'Student',
    salary: '5-10M',
    icon: Icons.smart_toy_rounded,
    color: AppColors.coral,
  ),
  _DemoJob(
    title: 'Backend .NET Engineer',
    company: 'SaaS Platform - HCM',
    type: 'Hybrid',
    level: 'Mid',
    salary: '25-45M',
    icon: Icons.dns_rounded,
    color: AppColors.mint,
  ),
];
