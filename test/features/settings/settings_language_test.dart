import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/settings/data/in_memory_settings_repository.dart';
import 'package:prifono_caa/features/settings/domain/app_language.dart';
import 'package:prifono_caa/features/settings/domain/settings_repository.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';

class _FlakyRepository implements SettingsRepository {
  final Map<String, String> data = {};
  bool failWrites = false;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw Exception('disco cheio');
    data[key] = value;
  }
}

void main() {
  group('SettingsController: idioma (ADR-034)', () {
    test('sem nada gravado vale o defaultLanguage (português nos testes)', () {
      final settings = SettingsController();

      expect(settings.language, AppLanguage.portuguese);
      expect(settings.effectiveLanguage, AppLanguage.portuguese);
    });

    test('load sem nada gravado mantém o padrão informado', () async {
      final settings = SettingsController(
        defaultLanguage: AppLanguage.system,
        deviceLocales: const [Locale('es', 'MX')],
      );

      await settings.load();

      expect(settings.language, AppLanguage.system);
      expect(settings.effectiveLanguage, AppLanguage.spanish);
    });

    test('setLanguage grava, avisa os ouvintes e vira o idioma em uso',
        () async {
      final repository = _FlakyRepository();
      final settings = SettingsController(repository: repository);
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setLanguage(AppLanguage.english);

      expect(settings.language, AppLanguage.english);
      expect(settings.effectiveLanguage, AppLanguage.english);
      expect(repository.data[SettingsController.languageKey], 'english');
      expect(notifications, 1);
    });

    test('escolher o mesmo idioma não notifica nem grava', () async {
      final repository = _FlakyRepository();
      final settings = SettingsController(repository: repository);
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setLanguage(AppLanguage.portuguese);

      expect(notifications, 0);
      expect(repository.data, isEmpty);
    });

    test('a escolha sobrevive a reabrir o app', () async {
      final repository = InMemorySettingsRepository();
      await SettingsController(repository: repository)
          .setLanguage(AppLanguage.spanish);

      final reopened = SettingsController(
        repository: repository,
        defaultLanguage: AppLanguage.system,
      );
      await reopened.load();

      expect(reopened.language, AppLanguage.spanish);
      expect(reopened.effectiveLanguage, AppLanguage.spanish);
    });

    test('Automático gravado também volta como Automático', () async {
      final repository = InMemorySettingsRepository();
      final first = SettingsController(repository: repository);
      await first.setLanguage(AppLanguage.english);
      await first.setLanguage(AppLanguage.system);

      final reopened = SettingsController(repository: repository);
      await reopened.load();

      expect(reopened.language, AppLanguage.system);
    });

    test('valor gravado desconhecido cai no padrão, sem quebrar', () async {
      final repository = _FlakyRepository()
        ..data[SettingsController.languageKey] = 'klingon';
      final settings = SettingsController(
        repository: repository,
        defaultLanguage: AppLanguage.system,
      );

      await settings.load();

      expect(settings.language, AppLanguage.system);
    });

    test('falha ao gravar não desfaz a escolha nem lança', () async {
      final repository = _FlakyRepository()..failWrites = true;
      final settings = SettingsController(repository: repository);

      await settings.setLanguage(AppLanguage.spanish);

      expect(settings.language, AppLanguage.spanish);
      expect(repository.data, isEmpty);
    });
  });

  group('SettingsController: Automático segue o aparelho', () {
    test('aparelho em idioma sem tradução usa inglês', () {
      final settings = SettingsController(
        defaultLanguage: AppLanguage.system,
        deviceLocales: const [Locale('fr', 'FR')],
      );

      expect(settings.effectiveLanguage, AppLanguage.english);
    });

    test('mudar o idioma do aparelho muda o idioma em uso e avisa', () {
      final settings = SettingsController(
        defaultLanguage: AppLanguage.system,
        deviceLocales: const [Locale('pt', 'BR')],
      );
      var notifications = 0;
      settings.addListener(() => notifications++);

      settings.deviceLocalesChanged(const [Locale('es', 'ES')]);

      expect(settings.effectiveLanguage, AppLanguage.spanish);
      expect(notifications, 1);
    });

    test('mudança que não altera o idioma em uso não avisa', () {
      final settings = SettingsController(
        defaultLanguage: AppLanguage.system,
        deviceLocales: const [Locale('es', 'ES')],
      );
      var notifications = 0;
      settings.addListener(() => notifications++);

      settings.deviceLocalesChanged(const [Locale('es', 'MX')]);

      expect(notifications, 0);
    });

    test('com vários idiomas no aparelho vale o primeiro traduzido', () {
      final settings = SettingsController(
        defaultLanguage: AppLanguage.system,
        deviceLocales: const [Locale('fr', 'FR'), Locale('es', 'MX')],
      );

      expect(settings.effectiveLanguage, AppLanguage.spanish);
    });

    test('com idioma escolhido, o aparelho é ignorado', () async {
      final settings = SettingsController(
        deviceLocales: const [Locale('pt', 'BR')],
      );
      await settings.setLanguage(AppLanguage.english);
      var notifications = 0;
      settings.addListener(() => notifications++);

      settings.deviceLocalesChanged(const [Locale('es', 'ES')]);

      expect(settings.effectiveLanguage, AppLanguage.english);
      expect(notifications, 0);
    });

    test('voltar para Automático usa o aparelho de novo', () async {
      final settings = SettingsController(
        deviceLocales: const [Locale('es', 'ES')],
      );
      await settings.setLanguage(AppLanguage.english);

      await settings.setLanguage(AppLanguage.system);

      expect(settings.effectiveLanguage, AppLanguage.spanish);
    });
  });
}
