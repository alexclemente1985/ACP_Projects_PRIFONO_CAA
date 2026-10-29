import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/editing/presentation/edit_lock_button.dart';
import 'package:prifono_caa/features/editing/presentation/edit_mode_controller.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_controller.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../../support/unlock_edit_mode.dart';
import '../speech/fake_speech_service.dart';

class _App {
  _App(this.speech, this.sentence, this.editMode);

  final FakeSpeechService speech;
  final SentenceController sentence;
  final EditModeController editMode;
}

/// Sobe o app com as pranchas [boards] (nome → cards) e fica na lista.
Future<_App> _pumpApp(
  WidgetTester tester, [
  Map<String, List<CardContent>> boards = const {},
]) async {
  final speech = FakeSpeechService();
  final sentence = SentenceController();
  final editMode = EditModeController();
  final repository = InMemoryBoardRepository();
  for (final entry in boards.entries) {
    final board = await repository.createBoard(name: entry.key);
    for (final card in entry.value) {
      await repository.addCard(board.id, card);
    }
  }
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_edit_');
  addTearDown(() => root.deleteSync(recursive: true));

  await tester.pumpWidget(
    AppScope(
      settings: SettingsController(),
      boards: repository,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      speech: speech,
      sentence: sentence,
      editMode: editMode,
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return _App(speech, sentence, editMode);
}

void _setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Finder get _lockClosed => find.byIcon(Icons.lock_outline);

/// Simula o app indo para segundo plano e voltando, na mesma sequência de
/// estados do sistema (o Flutter recusa pular etapas). A edição é travada na
/// ida; a volta só deixa a tela redesenhar (frames pausam fora de cena).
Future<void> _sendToBackgroundAndBack(WidgetTester tester) async {
  const goingAway = [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ];
  const comingBack = [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ];
  for (final state in goingAway) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
  for (final state in comingBack) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

/// Volta uma tela, como a seta da AppBar faria.
Future<void> _back(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pumpAndSettle();
}

void main() {
  group('lista de pranchas', () {
    testWidgets('abre em modo de uso: sem "Nova prancha" e sem menu', (
      tester,
    ) async {
      final app = await _pumpApp(tester, {
        'Casa': const [],
      });

      expect(app.editMode.isEditing, isFalse);
      expect(_lockClosed, findsOneWidget);
      expect(find.text('Nova prancha'), findsNothing);
      expect(find.byTooltip('Mais opções'), findsNothing);
      // Abrir a prancha continua livre.
      expect(find.text('Casa'), findsOneWidget);
    });

    testWidgets('sem nenhuma prancha ainda dá para criar a primeira', (
      tester,
    ) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Criar primeira prancha'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('segurar o cadeado por 1,5 s entra em edição', (tester) async {
      final app = await _pumpApp(tester, {
        'Casa': const [],
      });

      await unlockEditMode(tester);

      expect(app.editMode.isEditing, isTrue);
      expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
      expect(find.text('Nova prancha'), findsOneWidget);
      expect(find.byTooltip('Mais opções'), findsOneWidget);
    });

    testWidgets('soltar antes de 1,5 s não destrava e mostra a dica', (
      tester,
    ) async {
      final app = await _pumpApp(tester, {
        'Casa': const [],
      });

      final gesture = await tester.startGesture(tester.getCenter(_lockClosed));
      await tester.pump(); // dá a partida na animação
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await gesture.up();
      await tester.pump();

      expect(app.editMode.isEditing, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text('Segure o cadeado por 1,5 segundo para editar.'),
        findsOneWidget,
      );
    });

    testWidgets('um toque rápido no cadeado só mostra a dica', (tester) async {
      final app = await _pumpApp(tester, {
        'Casa': const [],
      });

      await tester.tap(_lockClosed);
      await tester.pump();

      expect(app.editMode.isEditing, isFalse);
      expect(find.textContaining('Segure o cadeado'), findsOneWidget);
    });

    testWidgets('tocar no cadeado aberto volta ao modo de uso', (tester) async {
      final app = await _pumpApp(tester, {
        'Casa': const [],
      });
      await unlockEditMode(tester);

      await tester.tap(find.byTooltip('Sair do modo de edição'));
      await tester.pumpAndSettle();

      expect(app.editMode.isEditing, isFalse);
      expect(find.text('Nova prancha'), findsNothing);
      expect(_lockClosed, findsOneWidget);
    });

    testWidgets('Ajustes continuam livres no modo de uso', (tester) async {
      await _pumpApp(tester, {
        'Casa': const [],
      });

      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();

      expect(find.text('Sobre e créditos'), findsOneWidget);
    });
  });

  group('prancha', () {
    testWidgets('em edição, tocar no card abre o editor sem falar', (
      tester,
    ) async {
      final app = await _pumpApp(tester, {
        'Casa': const [CardContent(label: 'Água')],
      });
      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();
      await unlockEditMode(tester);

      await tester.tap(find.text('Água'));
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorPage), findsOneWidget);
      expect(app.speech.spoken, isEmpty);
      expect(app.sentence.isEmpty, isTrue);
    });

    testWidgets('destravar na lista vale na prancha, e travar vale na lista', (
      tester,
    ) async {
      final app = await _pumpApp(tester, {
        'Casa': const [CardContent(label: 'Água')],
      });
      await unlockEditMode(tester);

      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Adicionar card'), findsOneWidget);

      await tester.tap(find.byTooltip('Sair do modo de edição'));
      await tester.pumpAndSettle();
      expect(app.editMode.isEditing, isFalse);
      expect(find.byTooltip('Adicionar card'), findsNothing);

      await _back(tester);
      expect(find.text('Nova prancha'), findsNothing);
      expect(find.byTooltip('Mais opções'), findsNothing);
    });
  });

  group('travar ao ir para segundo plano', () {
    testWidgets('na lista de pranchas', (tester) async {
      final app = await _pumpApp(tester, {
        'Casa': const [],
      });
      await unlockEditMode(tester);
      expect(app.editMode.isEditing, isTrue);

      await _sendToBackgroundAndBack(tester);

      expect(app.editMode.isEditing, isFalse);
      expect(find.text('Nova prancha'), findsNothing);
    });

    testWidgets('dentro de uma prancha', (tester) async {
      final app = await _pumpApp(tester, {
        'Casa': const [CardContent(label: 'Água')],
      });
      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();
      await unlockEditMode(tester);
      expect(find.byTooltip('Adicionar card'), findsOneWidget);

      await _sendToBackgroundAndBack(tester);

      expect(app.editMode.isEditing, isFalse);
      expect(find.byTooltip('Adicionar card'), findsNothing);
      expect(_lockClosed, findsOneWidget);
    });
  });

  group('cadeado: tamanho', () {
    for (final (name, size) in [
      ('telefone', const Size(390, 844)),
      ('tablet', const Size(1280, 800)),
    ]) {
      testWidgets('alvo de toque de pelo menos 48 dp: $name', (tester) async {
        _setScreen(tester, size);
        await _pumpApp(tester, {
          'Casa': const [],
        });

        final lock = tester.getSize(find.byType(HoldToUnlock));

        expect(lock.width, greaterThanOrEqualTo(48));
        expect(lock.height, greaterThanOrEqualTo(48));
      });
    }
  });
}