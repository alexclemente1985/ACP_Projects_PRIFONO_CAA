// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Privox';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonRetry => 'Tentar de novo';

  @override
  String get themeSectionTitle => 'Aparência';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get creditsButton => 'Créditos e licenças';

  @override
  String get boardsTitle => 'Pranchas';

  @override
  String get boardsEmptyTitle => 'Nenhuma prancha ainda';

  @override
  String get boardsEmptyMessage =>
      'Crie a sua primeira prancha de comunicação.';

  @override
  String get boardsEmptyAction => 'Criar primeira prancha';

  @override
  String get boardsLoadError => 'Não foi possível carregar as pranchas.';

  @override
  String get boardNew => 'Nova prancha';

  @override
  String get boardEdit => 'Editar';

  @override
  String get boardDelete => 'Excluir';

  @override
  String get boardMoreOptions => 'Mais opções';

  @override
  String boardGridSummary(int columns, int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      columns,
      locale: localeName,
      other: '$columns colunas',
      one: '1 coluna',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows linhas',
      one: '1 linha',
    );
    return '$_temp0 × $_temp1';
  }

  @override
  String get boardActionFailed =>
      'Não foi possível concluir a ação. Tente novamente.';

  @override
  String boardGridTooSmall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'Remova $_temp0 antes de reduzir a grade.';
  }

  @override
  String get boardEmptyHint => 'Toque no + para adicionar o primeiro card.';

  @override
  String boardFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'Prancha cheia: $_temp0. Aumente a grade ou remova cards para adicionar mais.';
  }

  @override
  String get boardCardsLoadError => 'Não foi possível carregar os cards.';

  @override
  String get cardAdd => 'Adicionar card';

  @override
  String get cardEditorNewTitle => 'Novo card';

  @override
  String get cardEditorEditTitle => 'Editar card';

  @override
  String get cardLabelLabel => 'Texto do card';

  @override
  String get cardLabelRequired => 'Escreva o texto do card.';

  @override
  String get cardSpeechLabel => 'Texto falado (opcional)';

  @override
  String get cardSpeechHelper => 'Se ficar vazio, o app fala o texto do card.';

  @override
  String get cardSaving => 'Salvando…';

  @override
  String get cardSymbolSectionTitle => 'Pictograma';

  @override
  String get cardSymbolChoose => 'Escolher pictograma';

  @override
  String get cardSymbolChange => 'Trocar pictograma';

  @override
  String get cardSymbolRemove => 'Remover pictograma';

  @override
  String get cardSymbolDownloading => 'Baixando o pictograma…';

  @override
  String get cardSymbolFailedHint =>
      'Tente de novo ou remova o pictograma para salvar só com texto.';

  @override
  String get cardColorSectionTitle => 'Cor do card';

  @override
  String get cardColorDefault => 'Padrão';

  @override
  String get cardColorPink => 'Rosa';

  @override
  String get cardColorBlue => 'Azul';

  @override
  String get cardColorBeige => 'Bege';

  @override
  String get cardColorWhite => 'Branco';

  @override
  String get cardDelete => 'Excluir card';

  @override
  String get cardDeleteTitle => 'Excluir card?';

  @override
  String cardDeleteMessage(String label) {
    return 'O card “$label” será excluído. Isso não pode ser desfeito.';
  }

  @override
  String get boardFormNewTitle => 'Nova prancha';

  @override
  String get boardFormEditTitle => 'Editar prancha';

  @override
  String get boardFormNameLabel => 'Nome da prancha';

  @override
  String get boardFormNameRequired => 'Dê um nome à prancha.';

  @override
  String get boardFormColumns => 'Colunas';

  @override
  String get boardFormRows => 'Linhas';

  @override
  String get boardColumnsDecrease => 'Diminuir colunas';

  @override
  String get boardColumnsIncrease => 'Aumentar colunas';

  @override
  String get boardRowsDecrease => 'Diminuir linhas';

  @override
  String get boardRowsIncrease => 'Aumentar linhas';

  @override
  String boardFormShrinkBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'Esta prancha tem $_temp0. Para reduzir mais a grade, remova cards antes.';
  }

  @override
  String get boardDeleteTitle => 'Excluir prancha?';

  @override
  String boardDeleteMessage(String name) {
    return 'A prancha “$name” e todos os seus cards serão excluídos. Isso não pode ser desfeito.';
  }

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
