import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

class WebDavConfig {
  final bool enabled;
  final String baseUrl;
  final String username;
  final String password;
  final String remotePath;

  const WebDavConfig({
    required this.enabled,
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.remotePath,
  });

  bool get isComplete =>
      baseUrl.trim().isNotEmpty &&
      username.trim().isNotEmpty &&
      password.trim().isNotEmpty;

  WebDavConfig copyWith({
    bool? enabled,
    String? baseUrl,
    String? username,
    String? password,
    String? remotePath,
  }) {
    return WebDavConfig(
      enabled: enabled ?? this.enabled,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
    );
  }

  static const defaults = WebDavConfig(
    enabled: false,
    baseUrl: '',
    username: '',
    password: '',
    remotePath: '/smag',
  );
}

class SyncResult {
  final int uploadedFiles;

  const SyncResult({required this.uploadedFiles});
}

class WebDavSyncService {
  static const _enabledKey = 'webdav_enabled';
  static const _urlKey = 'webdav_url';
  static const _usernameKey = 'webdav_username';
  static const _passwordKey = 'webdav_password';
  static const _pathKey = 'webdav_remote_path';

  Future<WebDavConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return WebDavConfig(
      enabled: prefs.getBool(_enabledKey) ?? WebDavConfig.defaults.enabled,
      baseUrl: prefs.getString(_urlKey) ?? WebDavConfig.defaults.baseUrl,
      username: prefs.getString(_usernameKey) ?? WebDavConfig.defaults.username,
      password: prefs.getString(_passwordKey) ?? WebDavConfig.defaults.password,
      remotePath: prefs.getString(_pathKey) ?? WebDavConfig.defaults.remotePath,
    );
  }

  Future<void> saveConfig(WebDavConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, config.enabled);
    await prefs.setString(_urlKey, config.baseUrl.trim());
    await prefs.setString(_usernameKey, config.username.trim());
    await prefs.setString(_passwordKey, config.password);
    await prefs.setString(_pathKey, _normalizeRemoteRoot(config.remotePath));
  }

  Future<SyncResult> syncLocalToRemote(String localRoot) async {
    final config = await loadConfig();
    if (!config.enabled || !config.isComplete) {
      return const SyncResult(uploadedFiles: 0);
    }

    final client = webdav.newClient(
      config.baseUrl.trim(),
      user: config.username.trim(),
      password: config.password,
    );

    client.setConnectTimeout(10000);
    client.setSendTimeout(10000);
    client.setReceiveTimeout(20000);

    await client.ping();

    final remoteRoot = _normalizeRemoteRoot(config.remotePath);
    await client.mkdirAll(remoteRoot);

    final root = Directory(localRoot);
    if (!await root.exists()) {
      return const SyncResult(uploadedFiles: 0);
    }

    int uploaded = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      final relPath = p
          .relative(entity.path, from: localRoot)
          .replaceAll('\\', '/');
      final remotePath = _joinRemote(remoteRoot, relPath);
      final parent = p.posix.dirname(remotePath);
      await client.mkdirAll(parent);
      await client.writeFromFile(entity.path, remotePath);
      uploaded++;
    }

    return SyncResult(uploadedFiles: uploaded);
  }

  String _normalizeRemoteRoot(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '/smag';
    final withPrefix = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return withPrefix
        .replaceAll(RegExp(r'/+'), '/')
        .replaceFirst(RegExp(r'/+$'), '');
  }

  String _joinRemote(String root, String rel) {
    final joined = '$root/$rel';
    return joined.replaceAll(RegExp(r'/+'), '/');
  }
}
