import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smag/data/nextcloud_sso.dart';
import 'package:smag/l10n/app_localizations.dart';
import 'package:smag/state/settings_provider.dart';
import 'package:smag/ui/settings_screen.dart';

class _FakeNextcloudSso extends NextcloudSso {
  NextcloudAccount? current = const NextcloudAccount(
    name: 'Nextcloud',
    userId: 'u1',
    url: 'https://cloud.example',
  );

  @override
  Future<NextcloudAccount?> getCurrentAccount() async => current;

  @override
  Future<NextcloudAccount?> pickAccount() async => current;

  @override
  Future<void> resetAccount() async {
    current = null;
  }
}

void main() {
  testWidgets('other settings remain interactive while syncNow is busy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final settings = SettingsProvider(_FakeNextcloudSso());
    await settings.init();
    settings.setSyncing(true);
    addTearDown(() => settings.setSyncing(false));

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    final syncNowFinder = find.byWidgetPredicate(
      (widget) =>
          widget is ListTile &&
          widget.title is Text &&
          (((widget.title! as Text).data == 'Jetzt synchronisieren') ||
              ((widget.title! as Text).data == 'Sync Now')),
    );
    final syncNowTile = tester.widget<ListTile>(syncNowFinder);
    expect(syncNowTile.onTap, isNull);

    var darkThemeFinder = find.text('OLED Dunkel');
    if (darkThemeFinder.evaluate().isEmpty) {
      darkThemeFinder = find.text('OLED Dark');
    }

    await tester.ensureVisible(darkThemeFinder);
    await tester.tap(darkThemeFinder);
    await tester.pump();

    expect(settings.theme, AppTheme.oledDark);
  });
}
