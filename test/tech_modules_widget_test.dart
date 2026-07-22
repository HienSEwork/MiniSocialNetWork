import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tech_net_mobile/ui/widgets/module_states.dart';
import 'package:tech_net_mobile/ui/widgets/tech_lab_widgets.dart';

void main() {
  testWidgets('module hero adapts to compact width without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: ModuleHero(
                eyebrow: 'Tech Lab',
                title: 'PC Builder & Compatibility Checker',
                description:
                    'Kiểm tra socket và công suất nguồn trên màn hình hẹp.',
                icon: Icons.memory_rounded,
                colors: [Colors.deepPurple, Colors.indigo],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('PC Builder & Compatibility Checker'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error state exposes Vietnamese retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorStateWidget(
            message: 'Không thể tải dữ liệu.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });
}
