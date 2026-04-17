import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smag/main.dart' as app;

Future<void> pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 100,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsWidgets);
}

Future<void> launchApp(WidgetTester tester) async {
  await app.main();
  await pumpUntilVisible(tester, find.text('Simple Meal Archive Gallery'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap import opens import screen', (tester) async {
    await launchApp(tester);

    // Floating add button -> Import should navigate to ImportScreen.
    await tester.tap(find.byIcon(Icons.add));
    await pumpUntilVisible(tester, find.text('Import'));
    await tester.tap(find.text('Import').last);
    await pumpUntilVisible(tester, find.byType(TabBar));

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(TabBarView), findsOneWidget);
  });

  testWidgets('import screen switches to text import tab', (tester) async {
    await launchApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await pumpUntilVisible(tester, find.text('Import'));
    await tester.tap(find.text('Import').last);
    await pumpUntilVisible(tester, find.byType(TabBar));

    await tester.tap(find.byType(Tab).at(1));
    await pumpUntilVisible(tester, find.byIcon(Icons.copy));

    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('tap search opens search screen', (tester) async {
    await launchApp(tester);

    await tester.tap(find.byIcon(Icons.search));
    await pumpUntilVisible(tester, find.byType(TextField));

    // SearchScreen should have a TextField for entering a query.
    expect(find.byType(TextField), findsOneWidget);

    // Go back.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await pumpUntilVisible(tester, find.text('Simple Meal Archive Gallery'));

    // Title should be visible again.
    expect(find.text('Simple Meal Archive Gallery'), findsOneWidget);
  });

  testWidgets('tap settings opens settings screen', (tester) async {
    await launchApp(tester);

    await tester.tap(find.byIcon(Icons.settings).last);
    await pumpUntilVisible(tester, find.byIcon(Icons.code));

    // Settings screen should show stable About section content.
    expect(find.byIcon(Icons.code), findsOneWidget);

    // Go back.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await pumpUntilVisible(tester, find.text('Simple Meal Archive Gallery'));

    expect(find.text('Simple Meal Archive Gallery'), findsOneWidget);
  });

  testWidgets('toggle grid view and back', (tester) async {
    await launchApp(tester);
    expect(find.byType(FloatingActionButton), findsNWidgets(2));

    // Tap the floating grid toggle button.
    await tester.tap(find.byIcon(Icons.grid_view));
    await pumpUntilVisible(tester, find.byIcon(Icons.list));

    // After toggling, the icon should switch to the list view icon.
    expect(find.byIcon(Icons.list), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Toggle back.
    await tester.tap(find.byIcon(Icons.list));
    await pumpUntilVisible(tester, find.byIcon(Icons.grid_view));

    expect(find.byIcon(Icons.grid_view), findsOneWidget);
  });

  testWidgets('add menu opens recipe create screen', (tester) async {
    await launchApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await pumpUntilVisible(tester, find.byIcon(Icons.edit_note));
    await tester.tap(find.byIcon(Icons.edit_note));
    await pumpUntilVisible(tester, find.byType(TextFormField));

    // Recipe edit screen should have a save button or text fields.
    expect(find.byType(TextFormField), findsWidgets);
  });
}
