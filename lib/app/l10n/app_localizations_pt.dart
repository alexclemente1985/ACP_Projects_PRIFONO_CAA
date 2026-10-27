// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'PRIFONO CAA';

  @override
  String get homeTitle => 'Laboratório de tema';

  @override
  String get themeSectionTitle => 'Aparência';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get paletteSectionTitle => 'Cores da marca';

  @override
  String get colorRosa => 'Rosa';

  @override
  String get colorAzul => 'Azul';

  @override
  String get colorBege => 'Bege';

  @override
  String get colorBranco => 'Branco';

  @override
  String get buttonsSectionTitle => 'Botões';

  @override
  String get primaryButton => 'Botão principal';

  @override
  String get tonalButton => 'Botão secundário';

  @override
  String get tryOutSectionTitle => 'Pictogramas (teste)';

  @override
  String get tryOutButton => 'Buscar pictograma';

  @override
  String get tryOutDownloading => 'Baixando pictograma';

  @override
  String get tryOutDownloadFailed => 'Não foi possível baixar o pictograma.';

  @override
  String get creditsButton => 'Créditos e licenças';

  @override
  String get searchTitle => 'Buscar pictogramas';

  @override
  String get searchHint => 'Digite uma palavra';

  @override
  String get searchClear => 'Limpar busca';

  @override
  String get searchLoading => 'Buscando';

  @override
  String get searchIdleMessage => 'Digite uma palavra para buscar pictogramas.';

  @override
  String searchEmptyMessage(String query) {
    return 'Nenhum pictograma encontrado para “$query”.';
  }

  @override
  String get searchErrorOffline =>
      'Sem conexão com a internet. Verifique a rede e tente de novo.';

  @override
  String get searchErrorTimeout => 'A busca demorou demais. Tente novamente.';

  @override
  String get searchErrorServer =>
      'O serviço de pictogramas está indisponível no momento.';

  @override
  String get searchErrorGeneric =>
      'Não foi possível ler a resposta do serviço de pictogramas.';

  @override
  String get searchRetry => 'Tentar de novo';

  @override
  String get imageUnavailable => 'Imagem indisponível';

  @override
  String get attributionShort =>
      'Pictogramas: ARASAAC (Governo de Aragão), licença CC BY-NC-SA. Toque para ver os créditos.';

  @override
  String get creditsTitle => 'Créditos e licenças';

  @override
  String get creditsArasaacTitle => 'Pictogramas';

  @override
  String get creditsArasaacBody =>
      'Os símbolos pictográficos utilizados são de propriedade do Governo de Aragão e foram criados por Sergio Palao para o ARASAAC (https://arasaac.org), que os distribui sob licença Creative Commons (BY-NC-SA).';

  @override
  String get creditsPrivacyTitle => 'Privacidade da busca';

  @override
  String get creditsPrivacyBody =>
      'Ao buscar pictogramas, a palavra digitada e o endereço IP do aparelho são enviados aos servidores do ARASAAC. O app não envia dados pessoais nem usa conta. Os pictogramas que você escolhe ficam salvos no aparelho para funcionar sem internet.';
}
