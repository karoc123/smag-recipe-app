import 'package:flutter/material.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';

/// Result of a conflict resolution.
enum ConflictChoice { keepLocal, keepRemote }

/// Dialog that prompts the user to choose between local and remote versions
/// of a recipe when a sync conflict is detected.
class ConflictDialog extends StatelessWidget {
  final Recipe recipe;

  const ConflictDialog({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.conflictTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.conflictMessage),
          const SizedBox(height: 12),
          Text(
            recipe.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (recipe.recipeCategory.isNotEmpty)
            Text(recipe.recipeCategory, style: theme.textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ConflictChoice.keepRemote),
          child: Text(l10n.keepServer),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ConflictChoice.keepLocal),
          child: Text(l10n.keepLocal),
        ),
      ],
    );
  }
}
