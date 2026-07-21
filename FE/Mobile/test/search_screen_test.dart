import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tech_net_mobile/data/providers/search_provider.dart';
import 'package:tech_net_mobile/ui/screens/search_screen.dart';

void main() {
  testWidgets('search screen adapts and waits for at least two characters', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(390, 844), Size(1024, 768)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SearchProvider(),
          child: const MaterialApp(
            locale: Locale('vi'),
            supportedLocales: [Locale('vi'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Khám phá cả cộng đồng'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(find.text('Khám phá cả cộng đồng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
