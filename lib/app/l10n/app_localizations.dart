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
  /// **'PRIFONO CAA'**
  String get appName;

  /// No description provided for @homeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Laboratório de tema'**
  String get homeTitle;

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

  /// No description provided for @paletteSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cores da marca'**
  String get paletteSectionTitle;

  /// No description provided for @colorRosa.
  ///
  /// In pt, this message translates to:
  /// **'Rosa'**
  String get colorRosa;

  /// No description provided for @colorAzul.
  ///
  /// In pt, this message translates to:
  /// **'Azul'**
  String get colorAzul;

  /// No description provided for @colorBege.
  ///
  /// In pt, this message translates to:
  /// **'Bege'**
  String get colorBege;

  /// No description provided for @colorBranco.
  ///
  /// In pt, this message translates to:
  /// **'Branco'**
  String get colorBranco;

  /// No description provided for @buttonsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Botões'**
  String get buttonsSectionTitle;

  /// No description provided for @primaryButton.
  ///
  /// In pt, this message translates to:
  /// **'Botão principal'**
  String get primaryButton;

  /// No description provided for @tonalButton.
  ///
  /// In pt, this message translates to:
  /// **'Botão secundário'**
  String get tonalButton;

  /// No description provided for @tryOutSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pictogramas (teste)'**
  String get tryOutSectionTitle;

  /// No description provided for @tryOutButton.
  ///
  /// In pt, this message translates to:
  /// **'Buscar pictograma'**
  String get tryOutButton;

  /// No description provided for @tryOutDownloading.
  ///
  /// In pt, this message translates to:
  /// **'Baixando pictograma'**
  String get tryOutDownloading;

  /// No description provided for @tryOutDownloadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível baixar o pictograma.'**
  String get tryOutDownloadFailed;

  /// No description provided for @creditsButton.
  ///
  /// In pt, this message translates to:
  /// **'Créditos e licenças'**
  String get creditsButton;

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

  /// No description provided for @attributionShort.
  ///
  /// In pt, this message translates to:
  /// **'Pictogramas: ARASAAC (Governo de Aragão), licença CC BY-NC-SA. Toque para ver os créditos.'**
  String get attributionShort;

  /// No description provided for @creditsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Créditos e licenças'**
  String get creditsTitle;

  /// No description provided for @creditsArasaacTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pictogramas'**
  String get creditsArasaacTitle;

  /// No description provided for @creditsArasaacBody.
  ///
  /// In pt, this message translates to:
  /// **'Os símbolos pictográficos utilizados são de propriedade do Governo de Aragão e foram criados por Sergio Palao para o ARASAAC (https://arasaac.org), que os distribui sob licença Creative Commons (BY-NC-SA).'**
  String get creditsArasaacBody;

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
