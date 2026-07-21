import 'package:flutter/material.dart';

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
              subtitle: 'Việc làm, thực tập và cơ hội công nghệ',
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, bottom),
              child: const ResponsivePage(
                child: FriendlyState(
                  icon: Icons.work_history_outlined,
                  title: 'Tính năng sắp ra mắt',
                  message:
                      'Tech Job chưa có API ổn định. Khi backend sẵn sàng, danh sách việc làm và ứng tuyển sẽ xuất hiện tại đây.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
