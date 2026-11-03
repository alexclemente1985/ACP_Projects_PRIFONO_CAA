import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/settings/data/in_memory_settings_repository.dart';
import 'package:prifono_caa/features/settings/domain/settings_repository.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';

/// Repositório que pode passar a falhar nas gravações.
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
  group('SettingsController: PIN do modo de edição (ADR-040)', () {
    test('começa sem PIN', () {
      final settings = SettingsController();

      expect(settings.hasPin, isFalse);
      expect(settings.checkPin('1234'), isFalse);
    });

    test('setPin liga o PIN, avisa os ouvintes e checkPin confere', () async {
      final settings = SettingsController();
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setPin('1234');

      expect(settings.hasPin, isTrue);
      expect(settings.checkPin('1234'), isTrue);
      expect(settings.checkPin('4321'), isFalse);
      expect(settings.checkPin(''), isFalse);
      expect(notifications, 1);
    });

    test('o PIN gravado volta quando o app abre de novo', () async {
      final repository = InMemorySettingsRepository();
      await SettingsController(repository: repository).setPin('2580');

      final reopened = SettingsController(repository: repository);
      await reopened.load();

      expect(reopened.hasPin, isTrue);
      expect(reopened.checkPin('2580'), isTrue);
    });

    test('trocar o PIN faz o antigo deixar de valer', () async {
      final settings = SettingsController();
      await settings.setPin('1111');

      await settings.setPin('2222');

      expect(settings.checkPin('1111'), isFalse);
      expect(settings.checkPin('2222'), isTrue);
    });

    test('PIN inválido é recusado e nada muda', () async {
      final settings = SettingsController();
      await settings.setPin('1234');

      for (final bad in ['', '123', '12345', 'abcd', '12 4']) {
        await expectLater(settings.setPin(bad), throwsArgumentError);
      }
      expect(settings.checkPin('1234'), isTrue);
    });

    test('clearPin desliga o PIN e o desligamento sobrevive ao reinício', () async {
      final repository = InMemorySettingsRepository();
      final settings = SettingsController(repository: repository);
      await settings.setPin('1234');

      await settings.clearPin();

      expect(settings.hasPin, isFalse);
      expect(settings.checkPin('1234'), isFalse);
      final reopened = SettingsController(repository: repository);
      await reopened.load();
      expect(reopened.hasPin, isFalse);
    });

    test('clearPin sem PIN não faz nada nem avisa', () async {
      final settings = SettingsController();
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.clearPin();

      expect(notifications, 0);
    });

    test('falha ao gravar: o erro sobe e o PIN anterior continua valendo', () async {
      final repository = _FlakyRepository();
      final settings = SettingsController(repository: repository);
      await settings.setPin('1234');
      repository.failWrites = true;

      await expectLater(settings.setPin('5678'), throwsException);
      await expectLater(settings.clearPin(), throwsException);

      expect(settings.checkPin('1234'), isTrue);
      expect(settings.checkPin('5678'), isFalse);
      expect(settings.hasPin, isTrue);
    });

    test('falha ao gravar o primeiro PIN: continua sem PIN', () async {
      final repository = _FlakyRepository()..failWrites = true;
      final settings = SettingsController(repository: repository);

      await expectLater(settings.setPin('1234'), throwsException);

      expect(settings.hasPin, isFalse);
    });

    test('PIN gravado de forma inválida vale como sem PIN', () async {
      for (final corrupted in ['12', 'abcd', '12345', '']) {
        final repository = _FlakyRepository()
          ..data[SettingsController.editPinKey] = corrupted;
        final settings = SettingsController(repository: repository);

        await settings.load();

        expect(settings.hasPin, isFalse, reason: 'valor "$corrupted"');
      }
    });

    test('load avisa quando o PIN gravado muda o estado, e só então', () async {
      final repository = _FlakyRepository()
        ..data[SettingsController.editPinKey] = '1234';
      final settings = SettingsController(repository: repository);
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.load();
      expect(notifications, 1);
      expect(settings.hasPin, isTrue);

      await settings.load(); // nada mudou
      expect(notifications, 1);
    });

    test('o PIN não mexe no tema', () async {
      final settings = SettingsController();

      await settings.setPin('1234');

      expect(settings.themeMode.name, 'system');
    });
  });
}
