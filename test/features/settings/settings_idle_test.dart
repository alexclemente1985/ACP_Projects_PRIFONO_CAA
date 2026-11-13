import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/settings/data/in_memory_settings_repository.dart';
import 'package:prifono_caa/features/settings/domain/edit_idle_timeout.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';

import '../../support/pump_editing_app.dart';
import '../../support/unlock_edit_mode.dart';

void main() {
  group('EditIdleTimeout', () {
    test('as opções são desligado, 2, 5 e 10 minutos', () {
      expect(EditIdleTimeout.options, [0, 2, 5, 10]);
      expect(EditIdleTimeout.defaultMinutes, 5);
    });

    test('fromStorage aceita só valores das opções', () {
      expect(EditIdleTimeout.fromStorage('0'), 0);
      expect(EditIdleTimeout.fromStorage('2'), 2);
      expect(EditIdleTimeout.fromStorage('10'), 10);
      expect(EditIdleTimeout.fromStorage(null), 5);
      expect(EditIdleTimeout.fromStorage(''), 5);
      expect(EditIdleTimeout.fromStorage('abc'), 5);
      expect(EditIdleTimeout.fromStorage('7'), 5);
      expect(EditIdleTimeout.fromStorage('-1'), 5);
    });

    test('toDuration: 0 vira "sem bloqueio"', () {
      expect(EditIdleTimeout.toDuration(0), isNull);
      expect(EditIdleTimeout.toDuration(5), const Duration(minutes: 5));
    });
  });

  group('SettingsController: bloqueio por inatividade', () {
    test('o padrão é 5 minutos', () {
      final settings = SettingsController();

      expect(settings.editIdleMinutes, 5);
      expect(settings.editIdleTimeout, const Duration(minutes: 5));
    });

    test('escolher atualiza na hora e grava', () async {
      final repository = InMemorySettingsRepository();
      final settings = SettingsController(repository: repository);
      var notified = 0;
      settings.addListener(() => notified++);

      final saving = settings.setEditIdleMinutes(10);
      expect(settings.editIdleMinutes, 10);
      expect(notified, 1);
      await saving;

      expect(
        await repository.read(SettingsController.editIdleMinutesKey),
        '10',
      );
    });

    test('0 desliga o bloqueio', () async {
      final settings = SettingsController();

      await settings.setEditIdleMinutes(0);

      expect(settings.editIdleMinutes, 0);
      expect(settings.editIdleTimeout, isNull);
    });

    test('escolher o mesmo valor não avisa nem grava de novo', () async {
      final settings = SettingsController();
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setEditIdleMinutes(5);

      expect(notified, 0);
    });

    test('valor fora das opções é recusado', () async {
      final settings = SettingsController();

      await expectLater(
        settings.setEditIdleMinutes(7),
        throwsArgumentError,
      );
      expect(settings.editIdleMinutes, 5);
    });

    test('load() restaura o valor gravado', () async {
      final repository = InMemorySettingsRepository();
      await repository.write(SettingsController.editIdleMinutesKey, '2');
      final settings = SettingsController(repository: repository);

      await settings.load();

      expect(settings.editIdleMinutes, 2);
    });

    test('load() com valor estranho volta ao padrão', () async {
      final repository = InMemorySettingsRepository();
      await repository.write(SettingsController.editIdleMinutesKey, 'xyz');
      final settings = SettingsController(repository: repository);

      await settings.load();

      expect(settings.editIdleMinutes, 5);
    });
  });

  group('Ajustes: bloqueio automático da edição', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
    }

    bool selected(WidgetTester tester, String label) => tester
        .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
        .selected;

    testWidgets('mostra as quatro opções, com 5 min escolhido', (
      tester,
    ) async {
      await pumpEditingApp(tester, boards: {'Casa': const []});
      await openSettings(tester);
      await tester.ensureVisible(find.text('Bloqueio automático da edição'));

      expect(find.text('Bloqueio automático da edição'), findsOneWidget);
      for (final label in ['Nunca', '2 min', '5 min', '10 min']) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      expect(selected(tester, '5 min'), isTrue);
      expect(selected(tester, '10 min'), isFalse);
    });

    testWidgets('tocar em uma opção escolhe e grava', (tester) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      await openSettings(tester);
      await tester.ensureVisible(find.text('10 min'));

      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();

      expect(app.settings.editIdleMinutes, 10);
      expect(selected(tester, '10 min'), isTrue);
      expect(selected(tester, '5 min'), isFalse);
    });

    testWidgets('a escolha vale para a edição seguinte', (tester) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      await openSettings(tester);
      await tester.ensureVisible(find.text('2 min'));
      await tester.tap(find.text('2 min'));
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await unlockEditMode(tester);
      await tester.pump(const Duration(minutes: 2, seconds: 1));
      await tester.pump();

      expect(app.editMode.isEditing, isFalse);
    });
  });
}
