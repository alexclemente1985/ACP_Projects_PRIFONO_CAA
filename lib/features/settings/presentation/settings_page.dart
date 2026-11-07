import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/about/credits_page.dart';
import 'package:prifono_caa/features/pin/presentation/pin_flows.dart';
import 'package:prifono_caa/features/settings/domain/app_language.dart';

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
            Semantics(
              header: true,
              child: Text(l10n.pinSectionTitle, style: textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            Text(l10n.pinSectionHelp, style: textTheme.bodyMedium),
            ListenableBuilder(
              listenable: settings,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pinSwitchTitle),
                      subtitle:
                          Text(settings.hasPin ? l10n.pinOn : l10n.pinOff),
                      value: settings.hasPin,
                      onChanged: (on) => unawaited(
                        on ? enablePinFlow(context) : disablePinFlow(context),
                      ),
                    ),
                    if (settings.hasPin)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OutlinedButton(
                          onPressed: () => unawaited(changePinFlow(context)),
                          child: Text(l10n.pinChange),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                l10n.languageSectionTitle,
                style: textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.languageHelp, style: textTheme.bodyMedium),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: settings,
              builder: (context, _) {
                final options = <(AppLanguage, String)>[
                  (AppLanguage.system, l10n.languageAutomatic),
                  for (final language in AppLanguage.concrete)
                    (language, language.nativeName),
                ];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (language, label) in options)
                      ChoiceChip(
                        label: Text(label),
                        selected: settings.language == language,
                        onSelected: (_) =>
                            unawaited(settings.setLanguage(language)),
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
