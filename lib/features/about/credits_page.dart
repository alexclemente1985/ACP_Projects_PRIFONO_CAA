import 'package:flutter/material.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/about/privox_mark.dart';

/// Tela "Sobre e créditos": marca, licença dos pictogramas do ARASAAC (texto
/// aprovado pela equipe do ARASAAC, ADR-023), privacidade da busca, quem faz o
/// app e endereço da política de privacidade.
///
/// Usa rolagem simples (não `ListView`) para que todo o conteúdo exista na
/// árvore de widgets, inclusive nos testes. Em telas largas o conteúdo fica
/// centralizado e limitado a [maxContentWidth] (ADR-031).
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  /// Largura máxima do conteúdo, em dp.
  static const double maxContentWidth = 720;

  /// Endereço exibido como texto selecionável (sem link clicável: evita
  /// dependência de pacote de abertura de URL).
  // TODO(privox-site): publicar a página em privox.com.br antes da beta.
  static const String privacyPolicyUrl = 'privox.com.br/privacidade';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.creditsTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(),
                  const SizedBox(height: 24),
                  _Section(
                    title: l10n.creditsArasaacTitle,
                    paragraphs: [
                      l10n.creditsArasaacOfficial,
                      l10n.creditsArasaacBody,
                      l10n.creditsArasaacTerms,
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: l10n.creditsPrivacyTitle,
                    paragraphs: [l10n.creditsPrivacyBody],
                  ),
                  const SizedBox(height: 16),
                  // TODO(CFFa): regras do conselho profissional sobre citar o
                  // consultório e a fonoaudióloga NÃO foram verificadas
                  // (ADR-013, ADR-028). Confirmar ou remover antes da captura
                  // enviada ao ARASAAC e antes da beta.
                  _Section(
                    title: l10n.aboutMakersTitle,
                    paragraphs: [l10n.aboutMadeBy, l10n.aboutClinic],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: l10n.aboutPolicyTitle,
                    paragraphs: [l10n.aboutPolicyBody, privacyPolicyUrl],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const PrivoxMark(size: 112),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(l10n.appName, style: textTheme.headlineMedium),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.aboutTagline,
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

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
            for (final paragraph in paragraphs) ...[
              const SizedBox(height: 8),
              SelectableText(paragraph, style: textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}
