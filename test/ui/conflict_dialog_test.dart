import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smag/domain/recipe.dart';
import 'package:smag/l10n/app_localizations.dart';
import 'package:smag/ui/conflict_dialog.dart';

Future<void> _pumpDialog(
  WidgetTester tester, {
  required Recipe local,
  required Recipe remote,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ConflictDialog(localRecipe: local, remoteRecipe: remote),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ConflictDialog image differences', () {
    testWidgets(
      'hides image difference for local file path vs cookbook image',
      (tester) async {
        final local = const Recipe(
          name: 'Soup',
          image:
              '/data/user/0/de.karoc.smag/app_flutter/smag_local_images/1.jpg',
          localImagePath:
              '/data/user/0/de.karoc.smag/app_flutter/smag_local_images/1.jpg',
        );
        final remote = const Recipe(name: 'Soup', image: 'full.jpg');

        await _pumpDialog(tester, local: local, remote: remote);

        expect(find.text('image'), findsNothing);
        expect(
          find.text('No field-level differences detected.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows image difference for two distinct external URLs', (
      tester,
    ) async {
      final local = const Recipe(
        name: 'Soup',
        image: 'https://example.com/a.jpg',
      );
      final remote = const Recipe(
        name: 'Soup',
        image: 'https://example.com/b.jpg',
      );

      await _pumpDialog(tester, local: local, remote: remote);

      expect(find.text('image'), findsOneWidget);
      expect(find.text('No field-level differences detected.'), findsNothing);
    });
  });
}
