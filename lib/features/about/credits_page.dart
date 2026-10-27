import 'package:flutter/material.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';

/// Créditos e licenças. Os nomes de quem apoia o app (ACP Projects, PRIFONO)
/// só entram aqui depois da resposta do ARASAAC (ADR-013).
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.creditsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: l10n.creditsArasaacTitle,
              body: l10n.creditsArasaacBody,
            ),
            const SizedBox(height: 16),
            _Section(
              title: l10n.creditsPrivacyTitle,
              body: l10n.creditsPrivacyBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            SelectableText(body, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
