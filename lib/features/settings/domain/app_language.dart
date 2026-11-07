import 'package:flutter/widgets.dart';

/// Idioma do app (ADR-034). Um único valor define três coisas ao mesmo tempo:
/// os textos da tela, o idioma da busca de pictogramas no ARASAAC e a voz.
///
/// [system] é só a escolha "Automático": não tem idioma próprio. Antes de usar
/// [locale], [arasaacCode] ou [ttsLanguage], resolva com [resolve] (o
/// `SettingsController.effectiveLanguage` já faz isso).
enum AppLanguage {
  system(null, null, null),
  portuguese(Locale('pt'), 'br', 'pt-BR'),
  spanish(Locale('es'), 'es', 'es-ES'),
  english(Locale('en'), 'en', 'en-US');

  const AppLanguage(this._locale, this._arasaacCode, this._ttsLanguage);

  final Locale? _locale;
  final String? _arasaacCode;
  final String? _ttsLanguage;

  /// Idioma do aparelho que o app não traduz cai em inglês (ADR-034).
  static const AppLanguage fallback = AppLanguage.english;

  /// Idiomas que a pessoa pode escolher de fato (sem o Automático).
  static const List<AppLanguage> concrete = [
    AppLanguage.portuguese,
    AppLanguage.spanish,
    AppLanguage.english,
  ];

  /// Idioma do app para um [device] locale: pt, es ou en; qualquer outro vira
  /// [fallback]. Só olha o código do idioma (pt-PT, es-MX, en-GB valem).
  static AppLanguage fromLocale(Locale device) {
    return switch (device.languageCode) {
      'pt' => AppLanguage.portuguese,
      'es' => AppLanguage.spanish,
      'en' => AppLanguage.english,
      _ => fallback,
    };
  }

  /// Idioma do app para a lista de idiomas preferidos do aparelho (a ordem é
  /// a escolhida pela pessoa): vale o primeiro que o app traduz; se nenhum,
  /// [fallback]. Lista vazia também cai em [fallback].
  static AppLanguage fromLocales(List<Locale> device) {
    for (final locale in device) {
      final language = fromLocale(locale);
      if (language != fallback || locale.languageCode == 'en') return language;
    }
    return fallback;
  }

  /// Lê o valor gravado. Desconhecido ou vazio devolve null.
  static AppLanguage? fromStorage(String? stored) {
    if (stored == null) return null;
    return AppLanguage.values.asNameMap()[stored];
  }

  /// Valor gravado em `app_settings`. Estável: não renomear os valores do enum.
  String get storageValue => name;

  /// Locale do Flutter (textos, formatos e componentes do Material).
  Locale get locale => _locale ?? _unresolved();

  /// Código de idioma da busca do ARASAAC (verificado: br, es, en).
  String get arasaacCode => _arasaacCode ?? _unresolved();

  /// Idioma da voz do aparelho.
  String get ttsLanguage => _ttsLanguage ?? _unresolved();

  Never _unresolved() {
    throw StateError('O Automático precisa ser resolvido antes de usar.');
  }

  /// Nome do idioma escrito NO PRÓPRIO idioma. Nunca é traduzido: quem abriu o
  /// app no idioma errado precisa reconhecer o seu para voltar.
  /// O Automático não tem nome próprio: use `languageAutomatic` do l10n.
  String get nativeName => switch (this) {
        AppLanguage.system => '',
        AppLanguage.portuguese => 'Português',
        AppLanguage.spanish => 'Español',
        AppLanguage.english => 'English',
      };
}
