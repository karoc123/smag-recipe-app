import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/sync_service.dart';
import '../state/recipe_provider.dart';
import '../state/settings_provider.dart';

/// Settings screen with sections for Sync, Theme, Language, and About.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      // Always goes back to the main screen (default pop behaviour).
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: ListView(
          children: const [
            _SyncSection(),
            Divider(height: 1),
            _ThemeSection(),
            Divider(height: 1),
            _LanguageSection(),
            Divider(height: 1),
            _AboutSection(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Sync Section ────────────────────────────────

class _SyncSection extends StatelessWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.syncManagement),
        if (settings.isLinked) ...[
          ListTile(
            leading: const Icon(Icons.cloud_done),
            title: Text(settings.account!.name),
            subtitle: Text(settings.account!.url),
          ),
          ListTile(
            leading: settings.syncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            title: Text(l10n.syncNow),
            onTap: settings.syncing ? null : () => _sync(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.disconnectAccount),
            onTap: () => _disconnect(context),
          ),
        ] else ...[
          ListTile(
            leading: const Icon(Icons.cloud_off),
            title: Text(l10n.noAccountLinked),
            subtitle: Text(l10n.connectNextcloudHint),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: () => _connect(context),
              icon: const Icon(Icons.link),
              label: Text(l10n.connectNextcloud),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _connect(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final success = await settings.linkAccount();
    if (success && context.mounted) {
      // Trigger initial sync.
      _sync(context);
    }
  }

  Future<void> _disconnect(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.disconnectAccount),
        content: Text(l10n.disconnectConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.disconnect),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SettingsProvider>().unlinkAccount();
    }
  }

  Future<void> _sync(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    final syncService = context.read<SyncService>();
    final recipes = context.read<RecipeProvider>();

    settings.setSyncing(true);
    try {
      final result = await syncService.sync();
      await recipes.loadRecipes();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.syncComplete(result.toString()))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync error: $e')));
      }
    } finally {
      settings.setSyncing(false);
    }
  }
}

// ─────────────────── Theme Section ───────────────────────────────

class _ThemeSection extends StatelessWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.themeSelector),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<AppTheme>(
            segments: [
              ButtonSegment<AppTheme>(
                value: AppTheme.light,
                label: Text(l10n.lightTheme),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<AppTheme>(
                value: AppTheme.oledDark,
                label: Text(l10n.oledDarkTheme),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {settings.theme},
            showSelectedIcon: false,
            onSelectionChanged: (values) => settings.setTheme(values.first),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── Language Section ─────────────────────────────

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.languageSelector),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<Locale>(
            segments: const [
              ButtonSegment<Locale>(
                value: Locale('de'),
                label: Text('Deutsch'),
              ),
              ButtonSegment<Locale>(
                value: Locale('en'),
                label: Text('English'),
              ),
            ],
            selected: {settings.locale},
            showSelectedIcon: false,
            onSelectionChanged: (values) => settings.setLocale(values.first),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── About Section ───────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.about),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text(l10n.githubRepo),
          subtitle: const Text('github.com/karoc123/smag-recipe-app'),
          onTap: () => launchUrl(
            Uri.parse('https://github.com/karoc123/smag-recipe-app'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.favorite_outline),
          title: Text(l10n.philosophy),
          onTap: () => _showPhilosophy(context),
        ),
      ],
    );
  }

  void _showPhilosophy(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.philosophyTitle),
        content: SingleChildScrollView(child: Text(l10n.philosophyBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Shared ──────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
