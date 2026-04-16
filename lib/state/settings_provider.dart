import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/nextcloud_sso.dart';

/// Available app themes.
enum AppTheme { light, oledDark }

/// Manages app-wide settings: theme, language, Nextcloud account state.
class SettingsProvider extends ChangeNotifier {
  static const _keyTheme = 'smag_theme';
  static const _keyLocale = 'smag_locale';

  final NextcloudSso _sso;

  AppTheme _theme = AppTheme.light;
  Locale _locale = const Locale('de');
  NextcloudAccount? _account;
  bool _syncing = false;

  SettingsProvider(this._sso);

  // ---- Getters ----

  AppTheme get theme => _theme;
  Locale get locale => _locale;
  NextcloudAccount? get account => _account;
  bool get isLinked => _account != null;
  bool get syncing => _syncing;

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
    final result = await _sso.pickAccount();
    if (result != null) {
      _account = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> unlinkAccount() async {
    await _sso.resetAccount();
    _account = null;
    notifyListeners();
  }

  void setSyncing(bool v) {
    _syncing = v;
    notifyListeners();
  }
}
