import 'package:flutter/material.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';

/// Result of a conflict resolution.
enum ConflictChoice { keepLocal, keepRemote, skip, cancelSync }

/// Dialog that prompts the user to choose between local and remote versions
/// of a recipe when a sync conflict is detected.
class ConflictDialog extends StatelessWidget {
  final Recipe localRecipe;
  final Recipe? remoteRecipe;

  const ConflictDialog({
    super.key,
    required this.localRecipe,
    required this.remoteRecipe,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final differences = _buildDifferences();

    return AlertDialog(
      title: Text(l10n.conflictTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.conflictMessage),
              const SizedBox(height: 12),
              Text(
                localRecipe.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (localRecipe.recipeCategory.isNotEmpty)
                Text(
                  localRecipe.recipeCategory,
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              if (remoteRecipe == null)
                Text(l10n.conflictNoServerData)
              else if (differences.isEmpty)
                Text(l10n.conflictNoFieldDifferences)
              else ...[
                Text(
                  l10n.conflictFieldDifferences,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...differences.map(
                  (diff) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(diff.field, style: theme.textTheme.labelLarge),
                          const SizedBox(height: 6),
                          Text(
                            '${l10n.conflictLocalLabel}: ${_displayValue(diff.localValue)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.conflictServerLabel}: ${_displayValue(diff.remoteValue)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ConflictChoice.cancelSync),
          child: Text(l10n.cancelSync),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ConflictChoice.skip),
          child: Text(l10n.skipConflict),
        ),
        OutlinedButton(
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

  List<_FieldDifference> _buildDifferences() {
    final remote = remoteRecipe;
    if (remote == null) return const [];

    final differences = <_FieldDifference>[];
    void add(String field, String localValue, String remoteValue) {
      if (_normalize(localValue) != _normalize(remoteValue)) {
        differences.add(
          _FieldDifference(
            field: field,
            localValue: localValue,
            remoteValue: remoteValue,
          ),
        );
      }
    }

    add('name', localRecipe.name, remote.name);
    add('description', localRecipe.description, remote.description);
    add('recipeCategory', localRecipe.recipeCategory, remote.recipeCategory);
    add('recipeYield', localRecipe.recipeYield, remote.recipeYield);
    add('prepTime', localRecipe.prepTime, remote.prepTime);
    add('cookTime', localRecipe.cookTime, remote.cookTime);
    add('totalTime', localRecipe.totalTime, remote.totalTime);
    add('keywords', localRecipe.keywords, remote.keywords);
    add('url', localRecipe.url, remote.url);
    if (!_isEquivalentImageAlias(localRecipe, remote)) {
      add('image', localRecipe.image, remote.image);
    }
    add(
      'recipeIngredient',
      localRecipe.recipeIngredient.join('\n'),
      remote.recipeIngredient.join('\n'),
    );
    add(
      'recipeInstructions',
      localRecipe.recipeInstructions.join('\n'),
      remote.recipeInstructions.join('\n'),
    );

    return differences;
  }

  String _normalize(String value) => value.trim();

  bool _isEquivalentImageAlias(Recipe local, Recipe remote) {
    final localImage = local.image.trim();
    final remoteImage = remote.image.trim();
    if (localImage == remoteImage) {
      return true;
    }

    final localIsFilePath =
        (local.localImagePath.isNotEmpty &&
            localImage == local.localImagePath) ||
        localImage.startsWith('/data/') ||
        localImage.contains('/app_flutter/');
    final remoteIsManagedPath = remoteImage.startsWith('/.smag-recipe-image-');

    return localIsFilePath && remoteIsManagedPath;
  }

  String _displayValue(String value) => value.trim().isEmpty ? '-' : value;
}

class _FieldDifference {
  final String field;
  final String localValue;
  final String remoteValue;

  const _FieldDifference({
    required this.field,
    required this.localValue,
    required this.remoteValue,
  });
}
