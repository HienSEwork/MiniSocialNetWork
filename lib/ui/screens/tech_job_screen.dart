import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/local_data_service.dart';
import '../widgets/common.dart';

class TechJobScreen extends StatefulWidget {
  const TechJobScreen({super.key});

  @override
  State<TechJobScreen> createState() => _TechJobScreenState();
}

class _TechJobScreenState extends State<TechJobScreen> {
  final _search = TextEditingController();
  List<TechJob> _jobs = const [];
  bool _loading = true;
  bool _savedOnly = false;
  String? _workType;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await LocalDataService.instance.jobs(
        keyword: _search.text,
        workType: _workType,
        savedOnly: _savedOnly,
      );
      if (!mounted) return;
      setState(() => _jobs = raw.map(TechJob.fromJson).toList());
    } on LocalDataFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 104;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _JobRadarHeader(count: _jobs.length)),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _load(),
                        decoration: InputDecoration(
                          hintText: 'Tìm vị trí, công ty hoặc công nghệ',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'Tìm kiếm',
                            onPressed: _load,
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Tất cả',
                              selected: _workType == null && !_savedOnly,
                              onTap: () {
                                _workType = null;
                                _savedOnly = false;
                                _load();
                              },
                            ),
                            for (final type in const [
                              'Remote',
                              'Hybrid',
                              'On-site',
                            ])
                              _FilterChip(
                                label: type,
                                selected: _workType == type,
                                onTap: () {
                                  _workType = _workType == type ? null : type;
                                  _load();
                                },
                              ),
                            _FilterChip(
                              label: 'Đã lưu',
                              icon: Icons.bookmark_rounded,
                              selected: _savedOnly,
                              onTap: () {
                                _savedOnly = !_savedOnly;
                                _load();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: FriendlyState(
                  icon: Icons.work_off_outlined,
                  title: 'Chưa tải được việc làm',
                  message: _error!,
                  actionLabel: 'Thử lại',
                  onAction: _load,
                ),
              )
            else if (_jobs.isEmpty)
              const SliverFillRemaining(
                child: FriendlyState(
                  icon: Icons.filter_alt_off_rounded,
                  title: 'Chưa có vị trí phù hợp',
                  message: 'Đổi từ khóa hoặc bỏ bớt bộ lọc để xem thêm cơ hội.',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
                sliver: SliverList.separated(
                  itemCount: _jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => ResponsivePage(
                    child: _JobCard(
                      job: _jobs[index],
                      sequence: index + 1,
                      onOpen: () => _openJob(_jobs[index]),
                      onSave: () => _toggleSave(_jobs[index]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSave(TechJob job) async {
    try {
      await LocalDataService.instance.post('/jobs/${job.id}/save');
      await _load();
    } on LocalDataFailure catch (error) {
      if (mounted) showResultMessage(context, error.message, error: true);
    }
  }

  Future<void> _openJob(TechJob job) async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _JobDetailSheet(job: job),
    );
    if (applied == true && mounted) {
      showResultMessage(
        context,
        'Đã ghi nhận quan tâm. Bạn có thể theo dõi tại mục Đã lưu.',
      );
      _load();
    }
  }
}

class _JobRadarHeader extends StatelessWidget {
  const _JobRadarHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.paddingOf(context).top + 22,
        22,
        22,
      ),
      child: ResponsivePage(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JOB RADAR / TECHNET',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.coral,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cơ hội đáng để mở',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Việc làm và thực tập IT được lưu ngay trên thiết bị.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.indigo,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'VỊ TRÍ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: icon == null ? null : Icon(icon, size: 17),
      label: Text(label),
    ),
  );
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.sequence,
    required this.onOpen,
    required this.onSave,
  });
  final TechJob job;
  final int sequence;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final accents = [
      AppColors.indigo,
      AppColors.coral,
      AppColors.mint,
      AppColors.grape,
    ];
    final accent = accents[job.accent % accents.length];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  sequence.toString().padLeft(2, '0'),
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.company.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accent,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(job.location, Icons.location_on_outlined),
                        _Tag(job.workType, Icons.schedule_rounded),
                        _Tag(job.level, Icons.trending_up_rounded),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job.stack,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      job.salary,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: job.isSaved ? 'Bỏ lưu' : 'Lưu việc làm',
                onPressed: onSave,
                icon: Icon(
                  job.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: job.isSaved ? AppColors.coral : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.icon);
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _JobDetailSheet extends StatefulWidget {
  const _JobDetailSheet({required this.job});
  final TechJob job;
  @override
  State<_JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<_JobDetailSheet> {
  final _note = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      24,
      4,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 28,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.job.company.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.coral,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.job.title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Tag(widget.job.location, Icons.location_on_outlined),
            _Tag(widget.job.workType, Icons.schedule_rounded),
            _Tag(widget.job.level, Icons.trending_up_rounded),
          ],
        ),
        const SizedBox(height: 20),
        Text('Công việc', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          widget.job.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        Text('Công nghệ', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(widget.job.stack),
        const SizedBox(height: 18),
        TextField(
          controller: _note,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lời nhắn quan tâm',
            hintText: 'Một câu ngắn về điều bạn muốn đóng góp…',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving || widget.job.hasInterest ? null : _apply,
            icon: Icon(
              widget.job.hasInterest
                  ? Icons.check_circle_rounded
                  : Icons.send_rounded,
            ),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                widget.job.hasInterest ? 'Đã gửi quan tâm' : 'Gửi quan tâm',
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      await LocalDataService.instance.post(
        '/jobs/${widget.job.id}/interest',
        data: {'note': _note.text.trim()},
      );
      if (mounted) Navigator.pop(context, true);
    } on LocalDataFailure catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showResultMessage(context, error.message, error: true);
      }
    }
  }
}

class TechJob {
  const TechJob({
    required this.id,
    required this.company,
    required this.title,
    required this.description,
    required this.location,
    required this.workType,
    required this.level,
    required this.stack,
    required this.salary,
    required this.accent,
    required this.isSaved,
    required this.hasInterest,
  });
  factory TechJob.fromJson(Map<String, dynamic> json) => TechJob(
    id: '${json['id']}',
    company: '${json['company']}',
    title: '${json['title']}',
    description: '${json['description']}',
    location: '${json['location']}',
    workType: '${json['workType']}',
    level: '${json['level']}',
    stack: '${json['stack']}',
    salary: '${json['salary']}',
    accent: json['accent'] is int ? json['accent'] as int : 0,
    isSaved: json['isSaved'] == true,
    hasInterest: json['hasInterest'] == true,
  );
  final String id,
      company,
      title,
      description,
      location,
      workType,
      level,
      stack,
      salary;
  final int accent;
  final bool isSaved, hasInterest;
}
