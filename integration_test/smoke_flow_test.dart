import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smag/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap import opens import screen', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Bottom navigation import button should navigate to ImportScreen.
    await tester.tap(find.byIcon(Icons.download));
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(TabBarView), findsOneWidget);
  });
}
