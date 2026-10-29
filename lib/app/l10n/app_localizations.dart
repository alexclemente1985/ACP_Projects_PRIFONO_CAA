import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'Privox'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get commonRetry;

  /// No description provided for @themeSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get themeSectionTitle;

  /// No description provided for @themeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @creditsButton.
  ///
  /// In pt, this message translates to:
  /// **'Sobre e créditos'**
  String get creditsButton;

  /// No description provided for @boardsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pranchas'**
  String get boardsTitle;

  /// No description provided for @boardsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma prancha ainda'**
  String get boardsEmptyTitle;

  /// No description provided for @boardsEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Crie a sua primeira prancha de comunicação.'**
  String get boardsEmptyMessage;

  /// No description provided for @boardsEmptyAction.
  ///
  /// In pt, this message translates to:
  /// **'Criar primeira prancha'**
  String get boardsEmptyAction;

  /// No description provided for @boardsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as pranchas.'**
  String get boardsLoadError;

  /// No description provided for @boardNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova prancha'**
  String get boardNew;

  /// No description provided for @boardEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get boardEdit;

  /// No description provided for @boardDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get boardDelete;

  /// No description provided for @boardMoreOptions.
  ///
  /// In pt, this message translates to:
  /// **'Mais opções'**
  String get boardMoreOptions;

  /// No description provided for @boardGridSummary.
  ///
  /// In pt, this message translates to:
  /// **'{columns, plural, =1{1 coluna} other{{columns} colunas}} × {rows, plural, =1{1 linha} other{{rows} linhas}}'**
  String boardGridSummary(int columns, int rows);

  /// No description provided for @boardActionFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a ação. Tente novamente.'**
  String get boardActionFailed;

  /// No description provided for @boardGridTooSmall.
  ///
  /// In pt, this message translates to:
  /// **'Remova {count, plural, =1{1 card} other{{count} cards}} antes de reduzir a grade.'**
  String boardGridTooSmall(int count);

  /// No description provided for @boardEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque no + para adicionar o primeiro card.'**
  String get boardEmptyHint;

  /// No description provided for @boardFull.
  ///
  /// In pt, this message translates to:
  /// **'Prancha cheia: {count, plural, =1{1 card} other{{count} cards}}. Aumente a grade ou remova cards para adicionar mais.'**
  String boardFull(int count);

  /// No description provided for @boardCardsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os cards.'**
  String get boardCardsLoadError;

  /// No description provided for @cardAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar card'**
  String get cardAdd;

  /// No description provided for @cardEditorNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo card'**
  String get cardEditorNewTitle;

  /// No description provided for @cardEditorEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar card'**
  String get cardEditorEditTitle;

  /// No description provided for @cardLabelLabel.
  ///
  /// In pt, this message translates to:
  /// **'Texto do card'**
  String get cardLabelLabel;

  /// No description provided for @cardLabelRequired.
  ///
  /// In pt, this message translates to:
  /// **'Escreva o texto do card.'**
  String get cardLabelRequired;

  /// No description provided for @cardSpeechLabel.
  ///
  /// In pt, this message translates to:
  /// **'Texto falado (opcional)'**
  String get cardSpeechLabel;

  /// No description provided for @cardSpeechHelper.
  ///
  /// In pt, this message translates to:
  /// **'Se ficar vazio, o app fala o texto do card.'**
  String get cardSpeechHelper;

  /// No description provided for @cardSaving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando…'**
  String get cardSaving;

  /// No description provided for @cardSymbolSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pictograma'**
  String get cardSymbolSectionTitle;

  /// No description provided for @cardSymbolChoose.
  ///
  /// In pt, this message translates to:
  /// **'Escolher pictograma'**
  String get cardSymbolChoose;

  /// No description provided for @cardSymbolChange.
  ///
  /// In pt, this message translates to:
  /// **'Trocar pictograma'**
  String get cardSymbolChange;

  /// No description provided for @cardSymbolRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover pictograma'**
  String get cardSymbolRemove;

  /// No description provided for @cardSymbolDownloading.
  ///
  /// In pt, this message translates to:
  /// **'Baixando o pictograma…'**
  String get cardSymbolDownloading;

  /// No description provided for @cardSymbolFailedHint.
  ///
  /// In pt, this message translates to:
  /// **'Tente de novo ou remova o pictograma para salvar só com texto.'**
  String get cardSymbolFailedHint;

  /// No description provided for @cardColorSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cor do card'**
  String get cardColorSectionTitle;

  /// No description provided for @cardColorDefault.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get cardColorDefault;

  /// No description provided for @cardColorPink.
  ///
  /// In pt, this message translates to:
  /// **'Rosa'**
  String get cardColorPink;

  /// No description provided for @cardColorBlue.
  ///
  /// In pt, this message translates to:
  /// **'Azul'**
  String get cardColorBlue;

  /// No description provided for @cardColorBeige.
  ///
  /// In pt, this message translates to:
  /// **'Bege'**
  String get cardColorBeige;

  /// No description provided for @cardColorWhite.
  ///
  /// In pt, this message translates to:
  /// **'Branco'**
  String get cardColorWhite;

  /// No description provided for @cardDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir card'**
  String get cardDelete;

  /// No description provided for @cardDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir card?'**
  String get cardDeleteTitle;

  /// No description provided for @cardDeleteMessage.
  ///
  /// In pt, this message translates to:
  /// **'O card “{label}” será excluído. Isso não pode ser desfeito.'**
  String cardDeleteMessage(String label);

  /// No description provided for @boardFormNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova prancha'**
  String get boardFormNewTitle;

  /// No description provided for @boardFormEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar prancha'**
  String get boardFormEditTitle;

  /// No description provided for @boardFormNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da prancha'**
  String get boardFormNameLabel;

  /// No description provided for @boardFormNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Dê um nome à prancha.'**
  String get boardFormNameRequired;

  /// No description provided for @boardFormColumns.
  ///
  /// In pt, this message translates to:
  /// **'Colunas'**
  String get boardFormColumns;

  /// No description provided for @boardFormRows.
  ///
  /// In pt, this message translates to:
  /// **'Linhas'**
  String get boardFormRows;

  /// No description provided for @boardColumnsDecrease.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir colunas'**
  String get boardColumnsDecrease;

  /// No description provided for @boardColumnsIncrease.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar colunas'**
  String get boardColumnsIncrease;

  /// No description provided for @boardRowsDecrease.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir linhas'**
  String get boardRowsDecrease;

  /// No description provided for @boardRowsIncrease.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar linhas'**
  String get boardRowsIncrease;

  /// No description provided for @boardFormShrinkBlocked.
  ///
  /// In pt, this message translates to:
  /// **'Esta prancha tem {count, plural, =1{1 card} other{{count} cards}}. Para reduzir mais a grade, remova cards antes.'**
  String boardFormShrinkBlocked(int count);

  /// No description provided for @boardDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir prancha?'**
  String get boardDeleteTitle;

  /// No description provided for @boardDeleteMessage.
  ///
  /// In pt, this message translates to:
  /// **'A prancha “{name}” e todos os seus cards serão excluídos. Isso não pode ser desfeito.'**
  String boardDeleteMessage(String name);

  /// No description provided for @searchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Buscar pictogramas'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite uma palavra'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar busca'**
  String get searchClear;

  /// No description provided for @searchLoading.
  ///
  /// In pt, this message translates to:
  /// **'Buscando'**
  String get searchLoading;

  /// No description provided for @searchIdleMessage.
  ///
  /// In pt, this message translates to:
  /// **'Digite uma palavra para buscar pictogramas.'**
  String get searchIdleMessage;

  /// No description provided for @searchEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pictograma encontrado para “{query}”.'**
  String searchEmptyMessage(String query);

  /// No description provided for @searchErrorOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet. Verifique a rede e tente de novo.'**
  String get searchErrorOffline;

  /// No description provided for @searchErrorTimeout.
  ///
  /// In pt, this message translates to:
  /// **'A busca demorou demais. Tente novamente.'**
  String get searchErrorTimeout;

  /// No description provided for @searchErrorServer.
  ///
  /// In pt, this message translates to:
  /// **'O serviço de pictogramas está indisponível no momento.'**
  String get searchErrorServer;

  /// No description provided for @searchErrorGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler a resposta do serviço de pictogramas.'**
  String get searchErrorGeneric;

  /// No description provided for @searchRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get searchRetry;

  /// No description provided for @imageUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Imagem indisponível'**
  String get imageUnavailable;

  /// No description provided for @speechVoiceMissing.
  ///
  /// In pt, this message translates to:
  /// **'Não há voz em português do Brasil neste aparelho. Instale uma nos ajustes de voz do aparelho.'**
  String get speechVoiceMissing;

  /// No description provided for @speechFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível falar agora. Tente de novo.'**
  String get speechFailed;

  /// No description provided for @attributionShort.
  ///
  /// In pt, this message translates to:
  /// **'Pictogramas: ARASAAC (Governo de Aragão), licença CC BY-NC-SA. Toque para ver os créditos.'**
  String get attributionShort;

  /// No description provided for @creditsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre e créditos'**
  String get creditsTitle;

  /// No description provided for @creditsArasaacTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pictogramas'**
  String get creditsArasaacTitle;

  /// No description provided for @creditsArasaacOfficial.
  ///
  /// In pt, this message translates to:
  /// **'Los símbolos pictográficos utilizados son propiedad del Gobierno de Aragón y han sido creados por Sergio Palao para ARASAAC (http://www.arasaac.org), que los distribuye bajo Licencia Creative Commons BY-NC-SA.'**
  String get creditsArasaacOfficial;

  /// No description provided for @creditsArasaacBody.
  ///
  /// In pt, this message translates to:
  /// **'Os símbolos pictográficos utilizados são de propriedade do Governo de Aragão e foram criados por Sergio Palao para o ARASAAC (https://arasaac.org), que os distribui sob licença Creative Commons (BY-NC-SA).'**
  String get creditsArasaacBody;

  /// No description provided for @creditsArasaacTerms.
  ///
  /// In pt, this message translates to:
  /// **'Os pictogramas são para uso não comercial. Ao compartilhar pictogramas ou pranchas feitas com eles, mantenha a atribuição ao ARASAAC e use a mesma licença (CC BY-NC-SA).'**
  String get creditsArasaacTerms;

  /// No description provided for @creditsPrivacyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade da busca'**
  String get creditsPrivacyTitle;

  /// No description provided for @creditsPrivacyBody.
  ///
  /// In pt, this message translates to:
  /// **'Ao buscar pictogramas, a palavra digitada e o endereço IP do aparelho são enviados aos servidores do ARASAAC. O app não envia dados pessoais nem usa conta. Os pictogramas que você escolhe ficam salvos no aparelho para funcionar sem internet.'**
  String get creditsPrivacyBody;

  /// No description provided for @aboutTagline.
  ///
  /// In pt, this message translates to:
  /// **'Pranchas de comunicação gratuitas, sem conta e sem anúncios.'**
  String get aboutTagline;

  /// No description provided for @aboutMakersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quem faz o Privox'**
  String get aboutMakersTitle;

  /// No description provided for @aboutMadeBy.
  ///
  /// In pt, this message translates to:
  /// **'Desenvolvido por ACP Projects.'**
  String get aboutMadeBy;

  /// No description provided for @aboutClinic.
  ///
  /// In pt, this message translates to:
  /// **'Em parceria com o consultório PRIFONO, da fonoaudióloga Priscilla de Sá.'**
  String get aboutClinic;

  /// No description provided for @aboutPolicyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Política de privacidade'**
  String get aboutPolicyTitle;

  /// No description provided for @aboutPolicyBody.
  ///
  /// In pt, this message translates to:
  /// **'A política de privacidade completa fica neste endereço:'**
  String get aboutPolicyBody;

  /// No description provided for @sentenceBarLabel.
  ///
  /// In pt, this message translates to:
  /// **'Frase'**
  String get sentenceBarLabel;

  /// No description provided for @sentenceHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque nos cards para montar uma frase.'**
  String get sentenceHint;

  /// No description provided for @sentenceSpeak.
  ///
  /// In pt, this message translates to:
  /// **'Falar a frase'**
  String get sentenceSpeak;

  /// No description provided for @sentenceDeleteLast.
  ///
  /// In pt, this message translates to:
  /// **'Apagar a última palavra'**
  String get sentenceDeleteLast;

  /// No description provided for @sentenceClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar a frase'**
  String get sentenceClear;

  /// No description provided for @editLockEnter.
  ///
  /// In pt, this message translates to:
  /// **'Entrar no modo de edição. Segure para destravar.'**
  String get editLockEnter;

  /// No description provided for @editLockLeave.
  ///
  /// In pt, this message translates to:
  /// **'Sair do modo de edição'**
  String get editLockLeave;

  /// No description provided for @editLockHoldHint.
  ///
  /// In pt, this message translates to:
  /// **'Segure o cadeado por 1,5 segundo para editar.'**
  String get editLockHoldHint;

  /// No description provided for @editModeHint.
  ///
  /// In pt, this message translates to:
  /// **'Modo de edição: toque num card para editar.'**
  String get editModeHint;

  /// No description provided for @boardEmptyUseHint.
  ///
  /// In pt, this message translates to:
  /// **'Esta prancha está vazia. Segure o cadeado por 1,5 segundo para adicionar cards.'**
  String get boardEmptyUseHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
