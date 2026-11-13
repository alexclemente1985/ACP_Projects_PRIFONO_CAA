import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';

import '../../support/pump_editing_app.dart';
import '../../support/unlock_edit_mode.dart';

const _notice = 'Edição bloqueada por inatividade.';

/// Passa [time] sem ninguém mexer no app e deixa a tela se redesenhar.
Future<void> _idle(WidgetTester tester, Duration time) async {
  await tester.pump(time);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Um toque em qualquer ponto (só interessa que o app o enxergue).
Future<void> _touch(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(2, 2));
  await gesture.up();
  await tester.pump();
}

/// Abre o editor do card "Água" da prancha "Casa" (a edição já destravada).
Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.text('Casa'));
  await tester.pumpAndSettle();
  await unlockEditMode(tester);
  await tester.tap(find.text('Água'));
  await tester.pumpAndSettle();
  expect(find.byType(CardEditorPage), findsOneWidget);
}

void main() {
  group('bloqueio por inatividade', () {
    testWidgets('trava depois de 5 minutos sem toques e avisa', (
      tester,
    ) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      await unlockEditMode(tester);
      expect(app.editMode.isEditing, isTrue);

      await _idle(tester, const Duration(minutes: 4, seconds: 59));
      expect(app.editMode.isEditing, isTrue);

      await _idle(tester, const Duration(seconds: 2));

      expect(app.editMode.isEditing, isFalse);
      expect(app.editMode.lastLockWasIdle, isTrue);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Nova prancha'), findsNothing);
      expect(find.text(_notice), findsOneWidget);
    });

    testWidgets('um toque reinicia a contagem', (tester) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      await unlockEditMode(tester);

      await _idle(tester, const Duration(minutes: 4));
      await _touch(tester);
      await _idle(tester, const Duration(minutes: 4));
      expect(app.editMode.isEditing, isTrue);

      await _idle(tester, const Duration(minutes: 2));
      expect(app.editMode.isEditing, isFalse);
    });

    testWidgets('digitar no editor de card reinicia a contagem', (
      tester,
    ) async {
      final app = await pumpEditingApp(
        tester,
        boards: {
          'Casa': const [CardContent(label: 'Água')],
        },
      );
      await _openEditor(tester);

      await _idle(tester, const Duration(minutes: 4));
      await tester.enterText(find.byType(TextField).first, 'Água fria');
      await _idle(tester, const Duration(minutes: 4));
      expect(app.editMode.isEditing, isTrue);
      expect(find.byType(CardEditorPage), findsOneWidget);

      await _idle(tester, const Duration(minutes: 2));
      expect(app.editMode.isEditing, isFalse);
    });

    testWidgets('fora da edição não há contagem nem aviso', (tester) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});

      await _idle(tester, const Duration(minutes: 30));

      expect(app.editMode.isEditing, isFalse);
      expect(find.text(_notice), findsNothing);
    });

    testWidgets('desligado: a edição nunca trava sozinha', (tester) async {
      final app = await pumpEditingApp(
        tester,
        boards: {'Casa': const []},
        idleMinutes: 0,
      );
      await unlockEditMode(tester);

      await _idle(tester, const Duration(minutes: 60));

      expect(app.editMode.isEditing, isTrue);
      expect(find.text(_notice), findsNothing);
    });

    testWidgets('o tempo escolhido vale: 2 minutos', (tester) async {
      final app = await pumpEditingApp(
        tester,
        boards: {'Casa': const []},
        idleMinutes: 2,
      );
      await unlockEditMode(tester);

      await _idle(tester, const Duration(minutes: 1, seconds: 59));
      expect(app.editMode.isEditing, isTrue);

      await _idle(tester, const Duration(seconds: 2));
      expect(app.editMode.isEditing, isFalse);
    });

    testWidgets('trocar o tempo com a edição aberta reinicia a contagem', (
      tester,
    ) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      await unlockEditMode(tester);
      await _idle(tester, const Duration(minutes: 4));

      await app.settings.setEditIdleMinutes(10);
      await _idle(tester, const Duration(minutes: 9));

      expect(app.editMode.isEditing, isTrue);
      await _idle(tester, const Duration(minutes: 2));
      expect(app.editMode.isEditing, isFalse);
    });

    testWidgets('com leitor de tela ligado a contagem fica parada', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      await unlockEditMode(tester);

      await _idle(tester, const Duration(minutes: 30));

      expect(app.editMode.isEditing, isTrue);
    });
  });

  group('ao travar, o que estava aberto fecha', () {
    testWidgets('o editor de card fecha sem salvar', (tester) async {
      final app = await pumpEditingApp(
        tester,
        boards: {
          'Casa': const [CardContent(label: 'Água')],
        },
      );
      await _openEditor(tester);
      await tester.enterText(find.byType(TextField).first, 'Suco');

      await _idle(tester, const Duration(minutes: 6));
      await tester.pumpAndSettle();

      expect(app.editMode.isEditing, isFalse);
      expect(find.byType(CardEditorPage), findsNothing);
      // Voltou para a prancha, e o card continua como estava.
      expect(find.text('Água'), findsOneWidget);
      expect(find.text('Suco'), findsNothing);
    });

    testWidgets('o menu aberto fecha', (tester) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      await unlockEditMode(tester);
      await tester.tap(find.byTooltip('Mais opções de Casa'));
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate((w) => w is PopupMenuItem), findsWidgets);

      await _idle(tester, const Duration(minutes: 6));
      await tester.pumpAndSettle();

      expect(app.editMode.isEditing, isFalse);
      expect(find.byWidgetPredicate((w) => w is PopupMenuItem), findsNothing);
    });

    testWidgets('o editor fecha também ao ir para segundo plano', (
      tester,
    ) async {
      final app = await pumpEditingApp(
        tester,
        boards: {
          'Casa': const [CardContent(label: 'Água')],
        },
      );
      await _openEditor(tester);

      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      for (final state in const [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();

      expect(app.editMode.isEditing, isFalse);
      expect(find.byType(CardEditorPage), findsNothing);
      // Segundo plano não é inatividade: sem aviso.
      expect(app.editMode.lastLockWasIdle, isFalse);
      expect(find.text(_notice), findsNothing);
    });
  });
}
