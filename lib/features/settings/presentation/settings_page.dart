import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/about/credits_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Semantics(
              header: true,
              child: Text(l10n.themeSectionTitle, style: textTheme.titleLarge),
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: settings,
              builder: (context, _) {
                final options = <(ThemeMode, String)>[
                  (ThemeMode.system, l10n.themeSystem),
                  (ThemeMode.light, l10n.themeLight),
                  (ThemeMode.dark, l10n.themeDark),
                ];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (mode, label) in options)
                      ChoiceChip(
                        label: Text(label),
                        selected: settings.themeMode == mode,
                        onSelected: (_) =>
                            unawaited(settings.setThemeMode(mode)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CreditsPage()),
              ),
              child: Text(l10n.creditsButton),
            ),
          ],
        ),
      ),
    );
  }
}
