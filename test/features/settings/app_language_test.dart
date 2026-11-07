import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/settings/domain/app_language.dart';

void main() {
  group('AppLanguage.fromLocale (ADR-034)', () {
    test('pt, es e en valem, com qualquer variante regional', () {
      expect(
        AppLanguage.fromLocale(const Locale('pt', 'BR')),
        AppLanguage.portuguese,
      );
      expect(
        AppLanguage.fromLocale(const Locale('pt', 'PT')),
        AppLanguage.portuguese,
      );
      expect(
        AppLanguage.fromLocale(const Locale('es', 'MX')),
        AppLanguage.spanish,
      );
      expect(
        AppLanguage.fromLocale(const Locale('es')),
        AppLanguage.spanish,
      );
      expect(
        AppLanguage.fromLocale(const Locale('en', 'GB')),
        AppLanguage.english,
      );
    });

    test('idioma sem tradução cai em inglês', () {
      expect(AppLanguage.fromLocale(const Locale('fr')), AppLanguage.english);
      expect(
        AppLanguage.fromLocale(const Locale('ja', 'JP')),
        AppLanguage.english,
      );
      expect(AppLanguage.fallback, AppLanguage.english);
    });
  });

  group('AppLanguage.fromLocales (lista de preferência do aparelho)', () {
    test('vale o primeiro idioma que o app traduz', () {
      expect(
        AppLanguage.fromLocales(const [Locale('fr'), Locale('es', 'ES')]),
        AppLanguage.spanish,
      );
      expect(
        AppLanguage.fromLocales(const [Locale('pt', 'BR'), Locale('en')]),
        AppLanguage.portuguese,
      );
    });

    test('inglês na lista vale como inglês', () {
      expect(
        AppLanguage.fromLocales(const [Locale('de'), Locale('en', 'US')]),
        AppLanguage.english,
      );
    });

    test('nenhum idioma traduzido, ou lista vazia, cai em inglês', () {
      expect(
        AppLanguage.fromLocales(const [Locale('fr'), Locale('de')]),
        AppLanguage.english,
      );
      expect(AppLanguage.fromLocales(const []), AppLanguage.english);
    });
  });

  group('AppLanguage: valores de cada idioma', () {
    test('textos, busca do ARASAAC e voz', () {
      expect(AppLanguage.portuguese.locale, const Locale('pt'));
      expect(AppLanguage.portuguese.arasaacCode, 'br');
      expect(AppLanguage.portuguese.ttsLanguage, 'pt-BR');

      expect(AppLanguage.spanish.locale, const Locale('es'));
      expect(AppLanguage.spanish.arasaacCode, 'es');
      expect(AppLanguage.spanish.ttsLanguage, 'es-ES');

      expect(AppLanguage.english.locale, const Locale('en'));
      expect(AppLanguage.english.arasaacCode, 'en');
      expect(AppLanguage.english.ttsLanguage, 'en-US');
    });

    test('o Automático não tem valores próprios e falha alto', () {
      expect(() => AppLanguage.system.locale, throwsStateError);
      expect(() => AppLanguage.system.arasaacCode, throwsStateError);
      expect(() => AppLanguage.system.ttsLanguage, throwsStateError);
    });

    test('nomes aparecem no próprio idioma', () {
      expect(AppLanguage.portuguese.nativeName, 'Português');
      expect(AppLanguage.spanish.nativeName, 'Español');
      expect(AppLanguage.english.nativeName, 'English');
    });

    test('concrete lista só os três idiomas reais', () {
      expect(AppLanguage.concrete, [
        AppLanguage.portuguese,
        AppLanguage.spanish,
        AppLanguage.english,
      ]);
    });
  });

  group('AppLanguage: valor gravado', () {
    test('ida e volta de todos os valores', () {
      for (final language in AppLanguage.values) {
        expect(
          AppLanguage.fromStorage(language.storageValue),
          language,
        );
      }
    });

    test('valores gravados são estáveis', () {
      expect(AppLanguage.system.storageValue, 'system');
      expect(AppLanguage.portuguese.storageValue, 'portuguese');
      expect(AppLanguage.spanish.storageValue, 'spanish');
      expect(AppLanguage.english.storageValue, 'english');
    });

    test('nulo, vazio ou desconhecido devolve null', () {
      expect(AppLanguage.fromStorage(null), isNull);
      expect(AppLanguage.fromStorage(''), isNull);
      expect(AppLanguage.fromStorage('klingon'), isNull);
    });
  });
}
