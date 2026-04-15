import 'package:flutter/material.dart';
import 'package:smag/l10n/app_localizations.dart';

class OverwriteDialog extends StatelessWidget {
  final String recipeTitle;
  const OverwriteDialog({super.key, required this.recipeTitle});

  static Future<bool?> show(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (_) => OverwriteDialog(recipeTitle: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.overwriteTitle),
      content: Text(l10n.overwriteMessage(recipeTitle)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            l10n.overwrite,
            style: const TextStyle(
              color: Color(0xFF6B8F71),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
