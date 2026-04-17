import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Interprets a sync/API error and returns a user-friendly message.
///
/// Recognises [PlatformException] patterns from the Nextcloud SSO plugin
/// where the HTTP status code is embedded in the message string.
String friendlyErrorMessage(AppLocalizations l10n, Object error) {
  final raw = error.toString();

  // PlatformException(REQUEST_FAILED, HTTP … 409 …)
  if (raw.contains('409')) return l10n.error409RecipeExists;
  if (raw.contains('401') || raw.contains('403')) {
    return l10n.error401Unauthorized;
  }
  if (raw.contains('404')) return l10n.error404NotFound;
  if (raw.contains('500') || raw.contains('502') || raw.contains('503')) {
    return l10n.error500Server;
  }
  if (raw.contains('SocketException') ||
      raw.contains('HandshakeException') ||
      raw.contains('Connection refused') ||
      raw.contains('Network is unreachable')) {
    return l10n.errorNetwork;
  }

  return l10n.errorUnknown;
}

/// Shows a dialog with a user-friendly error message and a button to copy
/// the full technical detail to the clipboard.
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required Object error,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final friendly = friendlyErrorMessage(l10n, error);
  final technical = error.toString();

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(friendly),
          const SizedBox(height: 16),
          Text(
            technical,
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: Text(l10n.copyError),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: technical));
            ScaffoldMessenger.of(
              ctx,
            ).showSnackBar(SnackBar(content: Text(l10n.errorCopied)));
          },
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}
