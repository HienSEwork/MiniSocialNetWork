import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tech_net_mobile/data/providers/friends_provider.dart';
import 'package:tech_net_mobile/ui/screens/friend_list_screen.dart';

void main() {
  testWidgets('friend list screen renders the main actions', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FriendsProvider(),
        child: const MaterialApp(home: FriendListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bạn bè'), findsOneWidget);
    expect(find.text('Lời mời kết bạn'), findsOneWidget);
    expect(find.text('Tìm bạn bè'), findsOneWidget);
  });
}
