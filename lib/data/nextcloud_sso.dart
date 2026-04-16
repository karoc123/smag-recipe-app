import 'package:flutter/services.dart';

/// Dart bridge to the native Nextcloud Android-SingleSignOn plugin.
///
/// All Nextcloud API calls are routed through the native SSO library so the
/// user never has to enter credentials directly.
class NextcloudSso {
  static const _channel = MethodChannel('de.karoc.smag/nextcloud_sso');

  /// Open the Nextcloud account picker. Returns account info or null.
  Future<NextcloudAccount?> pickAccount() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'pickAccount',
      );
      if (result == null) return null;
      return NextcloudAccount.fromMap(result);
    } on PlatformException catch (e) {
      if (e.code == 'NC_NOT_INSTALLED') return null;
      rethrow;
    }
  }

  /// Returns the currently linked account or null.
  Future<NextcloudAccount?> getCurrentAccount() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getCurrentAccount',
    );
    if (result == null) return null;
    return NextcloudAccount.fromMap(result);
  }

  /// Disconnect the current account.
  Future<void> resetAccount() async {
    await _channel.invokeMethod('resetAccount');
  }

  /// Perform an authenticated JSON request. Returns the response body string.
  Future<String> request(String method, String url, {String? body}) async {
    final payload = <String, dynamic>{
      'method': method,
      'url': url,
      'body': body,
    };
    payload.removeWhere((key, value) => value == null);
    final result = await _channel.invokeMethod<String>(
      'performRequest',
      payload,
    );
    return result ?? '';
  }

  /// Perform an authenticated binary GET (e.g. image download).
  /// Returns raw bytes or null if no image is available.
  Future<Uint8List?> binaryRequest(String url) async {
    final result = await _channel.invokeMethod<Uint8List>(
      'performBinaryRequest',
      {'url': url},
    );
    return result;
  }
}

/// Minimal representation of a Nextcloud account.
class NextcloudAccount {
  final String name;
  final String userId;
  final String url;

  const NextcloudAccount({
    required this.name,
    required this.userId,
    required this.url,
  });

  factory NextcloudAccount.fromMap(Map<String, dynamic> map) {
    return NextcloudAccount(
      name: (map['name'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      url: (map['url'] ?? '') as String,
    );
  }
}
