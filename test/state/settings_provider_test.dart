import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smag/data/nextcloud_sso.dart';
import 'package:smag/state/settings_provider.dart';

class _FakeNextcloudSso extends NextcloudSso {
  int pickCalls = 0;
  int resetCalls = 0;
  NextcloudAccount? pickResult;
  NextcloudAccount? currentAccount;
  Completer<NextcloudAccount?>? pickCompleter;

  @override
  Future<NextcloudAccount?> pickAccount() async {
    pickCalls++;
    if (pickCompleter != null) {
      return pickCompleter!.future;
    }
    return pickResult;
  }

  @override
  Future<NextcloudAccount?> getCurrentAccount() async => currentAccount;

  @override
  Future<void> resetAccount() async {
    resetCalls++;
    currentAccount = null;
  }
}

void main() {
  group('SettingsProvider sync state', () {
    test('runWhileSyncing resets state after success', () async {
      final provider = SettingsProvider(_FakeNextcloudSso());

      expect(provider.syncing, isFalse);
      final result = await provider.runWhileSyncing(() async {
        expect(provider.syncing, isTrue);
        return 7;
      });

      expect(result, 7);
      expect(provider.syncing, isFalse);
    });

    test('runWhileSyncing resets state after error', () async {
      final provider = SettingsProvider(_FakeNextcloudSso());

      await expectLater(
        provider.runWhileSyncing<int>(() async {
          throw StateError('boom');
        }),
        throwsA(isA<StateError>()),
      );

      expect(provider.syncing, isFalse);
    });

    test('overlapping runWhileSyncing calls are reference-counted', () async {
      final provider = SettingsProvider(_FakeNextcloudSso());
      final first = Completer<void>();
      final second = Completer<void>();

      final f1 = provider.runWhileSyncing(() => first.future);
      final f2 = provider.runWhileSyncing(() => second.future);

      expect(provider.syncing, isTrue);

      first.complete();
      await Future<void>.delayed(Duration.zero);
      expect(provider.syncing, isTrue);

      second.complete();
      await Future.wait<void>([f1, f2]);
      expect(provider.syncing, isFalse);
    });
  });

  group('SettingsProvider linking state', () {
    test('blocks duplicate linkAccount calls while picker is open', () async {
      final sso = _FakeNextcloudSso()
        ..pickCompleter = Completer<NextcloudAccount?>();
      final provider = SettingsProvider(sso);

      final firstCall = provider.linkAccount();
      expect(provider.linkingAccount, isTrue);

      final secondCall = await provider.linkAccount();
      expect(secondCall, isFalse);
      expect(sso.pickCalls, 1);

      sso.pickCompleter!.complete(
        const NextcloudAccount(
          name: 'Nextcloud',
          userId: 'u1',
          url: 'https://cloud.example',
        ),
      );

      expect(await firstCall, isTrue);
      expect(provider.linkingAccount, isFalse);
      expect(provider.isLinked, isTrue);
      expect(provider.account?.name, 'Nextcloud');
    });
  });
}
