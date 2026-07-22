import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/local_data_service.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _days = const [];
  List<Map<String, dynamic>> _users = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        LocalDataService.instance.adminStats(),
        LocalDataService.instance.postsPerDay(),
        LocalDataService.instance.adminUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _days = results[1] as List<Map<String, dynamic>>;
        _users = results[2] as List<Map<String, dynamic>>;
      });
    } on LocalDataFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhịp cộng đồng'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? FriendlyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Không thể mở quản trị',
              message: _error!,
              actionLabel: 'Thử lại',
              onAction: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 18),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.science_rounded),
                      ),
                      title: const Text(
                        'Quản trị 4 module Tech Lab',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: const Text(
                        'Trivia, linh kiện PC, AI prompt và chỉ mục giá thiết bị',
                      ),
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      onTap: () => context.push('/admin/tech-modules'),
                    ),
                  ),
                  Text(
                    'TỔNG QUAN / SQLITE',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.coral,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width >= 700
                        ? 4
                        : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      _Metric(
                        'Thành viên',
                        _stats?['totalUsers'],
                        Icons.people_alt_rounded,
                        AppColors.indigo,
                      ),
                      _Metric(
                        'Bài viết',
                        _stats?['totalPosts'],
                        Icons.article_rounded,
                        AppColors.coral,
                      ),
                      _Metric(
                        'Bình luận',
                        _stats?['totalComments'],
                        Icons.forum_rounded,
                        AppColors.mint,
                      ),
                      _Metric(
                        'Nhóm',
                        _stats?['totalGroups'],
                        Icons.diversity_3_rounded,
                        AppColors.grape,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bài viết theo ngày',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _PostBars(days: _days),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Quản lý thành viên',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${_users.length} tài khoản',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final user in _users)
                    _UserRow(user: user, onDelete: () => _deleteUser(user)),
                ],
              ),
            ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: Text(
          'Tài khoản ${user['displayName']} sẽ bị ẩn khỏi ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await LocalDataService.instance.delete('/admin/users/${user['id']}');
      await _load();
    } on LocalDataFailure catch (error) {
      if (mounted) showResultMessage(context, error.message, error: true);
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, this.color);
  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            '${value ?? 0}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    ),
  );
}

class _PostBars extends StatelessWidget {
  const _PostBars({required this.days});
  final List<Map<String, dynamic>> days;
  @override
  Widget build(BuildContext context) {
    final max = days.fold<int>(1, (current, row) {
      final value = row['count'] is int ? row['count'] as int : 0;
      return value > current ? value : current;
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final day in days.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(
                        '${day['day']}'.substring(5),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width:
                                constraints.maxWidth *
                                ((day['count'] as int) / max),
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.indigo,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${day['count']}',
                        textAlign: TextAlign.right,
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

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onDelete});
  final Map<String, dynamic> user;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: UserAvatar(
        label: '${user['displayName']}',
        accent: user['role'] == 'Admin' ? AppColors.coral : AppColors.mint,
      ),
      title: Text(
        '${user['displayName']}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${user['email']} · ${user['role']}'),
      trailing: IconButton(
        tooltip: 'Xóa người dùng',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    ),
  );
}
