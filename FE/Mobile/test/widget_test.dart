import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_net_mobile/main.dart';
import 'package:tech_net_mobile/ui/widgets/common.dart';

void main() {
  testWidgets('TechNet starts with its branded loading screen', (tester) async {
    await tester.pumpWidget(const AppBootstrap());
    expect(find.text('TechNet'), findsOneWidget);
  });

  testWidgets('UserAvatar renders safely without an image URL', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: UserAvatar(label: 'TechNet')),
      ),
    );

    expect(find.text('T'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
