import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/recipe_database.dart';
import '../l10n/app_localizations.dart';
import '../services/sync_service.dart';
import '../state/recipe_provider.dart';
import '../state/settings_provider.dart';
import 'conflict_dialog.dart';

/// Runs a sync cycle and presents a copyable operation log.
class SyncLogScreen extends StatefulWidget {
  const SyncLogScreen({super.key});

  @override
  State<SyncLogScreen> createState() => _SyncLogScreenState();
}

class _SyncLogScreenState extends State<SyncLogScreen> {
  final List<String> _entries = [];

  bool _running = false;
  bool _canceled = false;
  String? _summary;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _runSync();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncLogTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: l10n.copyPrompt,
            onPressed: _entries.isEmpty ? null : _copyLog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_running) const LinearProgressIndicator(),
          if (_summary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.syncComplete(_summary!)),
                      if (_canceled)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(l10n.syncCanceled),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_errorText!),
                ),
              ),
            ),
          Expanded(
            child: _entries.isEmpty
                ? Center(child: Text(l10n.syncLogEmpty))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SelectableText(_entries[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _runSync() async {
    if (_running) return;

    final syncService = context.read<SyncService>();
    final settings = context.read<SettingsProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    final db = context.read<RecipeDatabase>();

    setState(() {
      _running = true;
      _canceled = false;
      _summary = null;
      _errorText = null;
      _entries.clear();
    });

    settings.setSyncing(true);
    _appendLog('Starting sync.');

    try {
      final result = await syncService.sync(
        onLog: _appendLog,
        cookbookFolderOverride: settings.cookbookFolderOverride,
      );
      await recipeProvider.loadRecipes();

      final canceled = await _resolveConflicts(
        syncService,
        db,
        cookbookFolderOverride: settings.cookbookFolderOverride,
      );
      final remainingConflicts = (await db.getConflicts()).length;
      if (remainingConflicts > 0) {
        _appendLog('Remaining conflicts: $remainingConflicts.');
      }

      await recipeProvider.loadRecipes();

      if (!mounted) return;
      setState(() {
        _summary = result.toString();
        _canceled = canceled;
      });
    } catch (e) {
      _appendLog('Sync failed: $e');
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      settings.setSyncing(false);
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  Future<bool> _resolveConflicts(
    SyncService syncService,
    RecipeDatabase db, {
    String? cookbookFolderOverride,
  }) async {
    final conflicts = await db.getConflicts();
    if (conflicts.isEmpty) {
      _appendLog('No conflicts detected.');
      return false;
    }

    _appendLog('Resolving ${conflicts.length} conflict(s).');

    for (final localRecipe in conflicts) {
      if (!mounted) return true;

      final remoteRecipe = localRecipe.remoteId == null
          ? null
          : await syncService.fetchRemoteRecipe(localRecipe.remoteId!);
      if (!mounted) return true;

      final choice = await showDialog<ConflictChoice>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ConflictDialog(
          localRecipe: localRecipe,
          remoteRecipe: remoteRecipe,
        ),
      );

      if (choice == null || choice == ConflictChoice.skip) {
        _appendLog('Skipped conflict for "${localRecipe.name}".');
        continue;
      }

      if (choice == ConflictChoice.cancelSync) {
        _appendLog('Sync canceled by user during conflict resolution.');
        return true;
      }

      final keepLocal = choice == ConflictChoice.keepLocal;
      await syncService.resolveConflict(
        localRecipe.localId!,
        keepLocal: keepLocal,
        cookbookFolderOverride: cookbookFolderOverride,
      );
      _appendLog(
        keepLocal
            ? 'Resolved "${localRecipe.name}" by keeping local version.'
            : 'Resolved "${localRecipe.name}" by keeping server version.',
      );
    }

    return false;
  }

  void _appendLog(String entry) {
    if (!mounted) return;

    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');

    setState(() {
      _entries.add('[$hh:$mm:$ss] $entry');
    });
  }

  Future<void> _copyLog() async {
    final text = _entries.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.promptCopied)),
    );
  }
}
