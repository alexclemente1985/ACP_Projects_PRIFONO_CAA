import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';

/// Tela provisória da E0: confere visualmente tema, l10n e estado.
/// Será substituída pela lista de pranchas na E4.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.themeSectionTitle, style: textTheme.titleLarge),
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
                        onSelected: (_) => settings.setThemeMode(mode),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(l10n.paletteSectionTitle, style: textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Swatch(
                  name: l10n.colorRosa,
                  color: BrandColors.rosa,
                  hex: '#FBB7C4',
                ),
                _Swatch(
                  name: l10n.colorAzul,
                  color: BrandColors.azul,
                  hex: '#56B2CB',
                ),
                _Swatch(
                  name: l10n.colorBege,
                  color: BrandColors.bege,
                  hex: '#FEFEE9',
                ),
                _Swatch(
                  name: l10n.colorBranco,
                  color: BrandColors.branco,
                  hex: '#FFFFFF',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.buttonsSectionTitle, style: textTheme.titleLarge),
            const SizedBox(height: 12),
            FilledButton(onPressed: () {}, child: Text(l10n.primaryButton)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () {}, child: Text(l10n.tonalButton)),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.color,
    required this.hex,
  });

  final String name;
  final Color color;
  final String hex;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).colorScheme.outline;
    return Semantics(
      label: '$name $hex',
      excludeSemantics: true,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Texto sempre em tinta: contraste >= 7:1 sobre as 4 cores da marca.
            Text(
              name,
              style: const TextStyle(
                color: BrandColors.tinta,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              hex,
              style: const TextStyle(color: BrandColors.tinta, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}