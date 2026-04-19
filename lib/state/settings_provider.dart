import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/nextcloud_sso.dart';

/// Available app themes.
enum AppTheme { light, oledDark }

/// Manages app-wide settings: theme, language, Nextcloud account state.
class SettingsProvider extends ChangeNotifier {
  static const _keyTheme = 'smag_theme';
  static const _keyLocale = 'smag_locale';
  static const _keyCookbookFolderOverride = 'smag_cookbook_folder_override';

  final NextcloudSso _sso;

  AppTheme _theme = AppTheme.light;
  Locale _locale = const Locale('de');
  NextcloudAccount? _account;
  int _activeSyncOperations = 0;
  bool _linkingAccount = false;
  String _cookbookFolderOverride = '';

  SettingsProvider(this._sso);

  // ---- Getters ----

  AppTheme get theme => _theme;
  Locale get locale => _locale;
  NextcloudAccount? get account => _account;
  bool get isLinked => _account != null;
  bool get syncing => _activeSyncOperations > 0;
  bool get linkingAccount => _linkingAccount;
  String? get cookbookFolderOverride {
    final trimmed = _cookbookFolderOverride.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get hasCookbookFolderOverride => cookbookFolderOverride != null;

  // ---- Initialization ----

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final themeName = prefs.getString(_keyTheme) ?? 'light';
    _theme = AppTheme.values.firstWhere(
      (t) => t.name == themeName,
      orElse: () => AppTheme.light,
    );

    final localeCode = prefs.getString(_keyLocale) ?? 'de';
    _locale = Locale(localeCode);

    _cookbookFolderOverride = prefs.getString(_keyCookbookFolderOverride) ?? '';

    try {
      _account = await _sso.getCurrentAccount();
    } catch (_) {
      _account = null;
    }
    notifyListeners();
  }

  // ---- Theme ----

  Future<void> setTheme(AppTheme t) async {
    _theme = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, t.name);
  }

  // ---- Locale ----

  Future<void> setLocale(Locale l) async {
    _locale = l;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, l.languageCode);
  }

  // ---- Nextcloud account ----

  Future<bool> linkAccount() async {
    if (_linkingAccount) {
      return false;
    }

    _linkingAccount = true;
    notifyListeners();

    try {
      final result = await _sso.pickAccount();
      if (result != null) {
        _account = result;
        notifyListeners();
        return true;
      }
      return false;
    } finally {
      _linkingAccount = false;
      notifyListeners();
    }
  }

  Future<void> unlinkAccount() async {
    await _sso.resetAccount();
    _account = null;
    notifyListeners();
  }

  void setSyncing(bool v) {
    if (v) {
      _activeSyncOperations++;
      if (_activeSyncOperations == 1) {
        notifyListeners();
      }
      return;
    }

    if (_activeSyncOperations == 0) {
      return;
    }

    _activeSyncOperations--;
    if (_activeSyncOperations == 0) {
      notifyListeners();
    }
  }

  Future<T> runWhileSyncing<T>(Future<T> Function() action) async {
    setSyncing(true);
    try {
      return await action();
    } finally {
      setSyncing(false);
    }
  }

  Future<void> setCookbookFolderOverride(String value) async {
    _cookbookFolderOverride = value.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCookbookFolderOverride, _cookbookFolderOverride);
  }

  Future<void> clearCookbookFolderOverride() async {
    await setCookbookFolderOverride('');
  }
}
