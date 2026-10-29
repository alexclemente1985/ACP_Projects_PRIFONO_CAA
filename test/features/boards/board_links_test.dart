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
import 'package:prifono_caa/features/sentence/presentation/sentence_controller.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../../support/unlock_edit_mode.dart';
import '../speech/fake_speech_service.dart';

class _App {
  _App(this.repository, this.speech, this.sentence);

  final InMemoryBoardRepository repository;
  final FakeSpeechService speech;
  final SentenceController sentence;
}

/// Sobe o app com a prancha "Início" (com um card "Comer" que abre
/// "Comidas", se [linked]) e a prancha "Comidas" (com o card "Maçã").
/// Com [deleteTarget], "Comidas" é apagada antes de o app subir; com
/// [onlyHome], ela nem é criada (o app tem uma prancha só).
Future<_App> _pumpApp(
  WidgetTester tester, {
  bool linked = true,
  bool deleteTarget = false,
  bool onlyHome = false,
}) async {
  final speech = FakeSpeechService();
  final sentence = SentenceController();
  final repository = InMemoryBoardRepository();
  final home = await repository.createBoard(name: 'Início');
  if (onlyHome) {
    await repository.addCard(home.id, const CardContent(label: 'Comer'));
  } else {
    final food = await repository.createBoard(name: 'Comidas');
    await repository.addCard(food.id, const CardContent(label: 'Maçã'));
    await repository.addCard(
      home.id,
      CardContent(label: 'Comer', linkBoardId: linked ? food.id : null),
    );
    if (deleteTarget) await repository.deleteBoard(food.id);
  }

  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_links_');
  addTearDown(() => root.deleteSync(recursive: true));

  await tester.pumpWidget(
    AppScope(
      settings: SettingsController(),
      boards: repository,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      speech: speech,
      sentence: sentence,
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return _App(repository, speech, sentence);
}

Future<void> _open(WidgetTester tester, String boardName) async {
  await tester.tap(find.text(boardName));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pumpAndSettle();
}

/// A prancha aberta no momento (título na AppBar visível).
Finder _boardTitle(String name) => find.widgetWithText(AppBar, name);

void main() {
  group('card com link (E5-4)', () {
    testWidgets('em uso, tocar abre a prancha, sem falar nem entrar na frase', (
      tester,
    ) async {
      final app = await _pumpApp(tester);
      await _open(tester, 'Início');
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);

      await tester.tap(find.text('Comer'));
      await tester.pumpAndSettle();

      expect(_boardTitle('Comidas'), findsOneWidget);
      expect(find.text('Maçã'), findsOneWidget);
      expect(app.speech.spoken, isEmpty);
      expect(app.sentence.isEmpty, isTrue);
    });

    testWidgets('a frase continua ao voltar da prancha de destino', (
      tester,
    ) async {
      final app = await _pumpApp(tester);
      await _open(tester, 'Início');
      await tester.tap(find.text('Comer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maçã'));
      await tester.pump();
      await _back(tester);

      expect(_boardTitle('Início'), findsOneWidget);
      expect(app.sentence.items.map((i) => i.label), ['Maçã']);
      expect(app.speech.spoken, ['Maçã']);
    });

    testWidgets('em edição, tocar abre o editor e não navega', (tester) async {
      await _pumpApp(tester);
      await _open(tester, 'Início');
      await unlockEditMode(tester);

      await tester.tap(find.text('Comer'));
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorPage), findsOneWidget);
      expect(_boardTitle('Comidas'), findsNothing);
    });

    testWidgets('card sem link não mostra a pasta e continua falando', (
      tester,
    ) async {
      final app = await _pumpApp(tester, linked: false);
      await _open(tester, 'Início');

      expect(find.byIcon(Icons.folder_outlined), findsNothing);
      await tester.tap(find.text('Comer'));
      await tester.pump();

      expect(app.speech.spoken, ['Comer']);
    });

    testWidgets('prancha de destino apagada: vira card comum', (tester) async {
      final app = await _pumpApp(tester, deleteTarget: true);
      await _open(tester, 'Início');

      expect(find.byIcon(Icons.folder_outlined), findsNothing);
      await tester.tap(find.text('Comer'));
      await tester.pump();

      expect(app.speech.spoken, ['Comer']);
      expect(app.sentence.items.map((i) => i.label), ['Comer']);
    });
  });

  group('editor: escolher a prancha de destino', () {
    testWidgets('lista só as outras pranchas e "Nenhuma"', (tester) async {
      await _pumpApp(tester, linked: false);
      await _open(tester, 'Início');
      await unlockEditMode(tester);
      await tester.tap(find.text('Comer'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Abrir outra prancha ao tocar'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Nenhuma (o card só fala)'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('Comidas'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('Início'),
        ),
        findsNothing,
      );
    });

    testWidgets('escolher "Comidas" e salvar liga o card à prancha', (
      tester,
    ) async {
      final app = await _pumpApp(tester, linked: false);
      await _open(tester, 'Início');
      await unlockEditMode(tester);
      await tester.tap(find.text('Comer'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Abrir outra prancha ao tocar'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Nenhuma (o card só fala)'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('Comidas'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final boards = await app.repository.listBoards();
      final home = boards.firstWhere((b) => b.name == 'Início');
      final cards = await app.repository.listCards(home.id);
      expect(cards.single.content.linkBoardId, boards.last.id);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('escolher "Nenhuma" remove o link', (tester) async {
      final app = await _pumpApp(tester);
      await _open(tester, 'Início');
      await unlockEditMode(tester);
      await tester.tap(find.text('Comer'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Abrir outra prancha ao tocar'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Comidas'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('Nenhuma (o card só fala)'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final home = (await app.repository.listBoards()).first;
      final cards = await app.repository.listCards(home.id);
      expect(cards.single.content.linkBoardId, isNull);
      expect(find.byIcon(Icons.folder_outlined), findsNothing);
    });

    testWidgets('sem outra prancha, explica em vez de mostrar a lista', (
      tester,
    ) async {
      await _pumpApp(tester, onlyHome: true);
      await _open(tester, 'Início');
      await unlockEditMode(tester);

      await tester.tap(find.text('Comer'));
      await tester.pumpAndSettle();

      expect(
        find.text('Crie outra prancha para poder ligar este card a ela.'),
        findsOneWidget,
      );
      expect(find.text('Nenhuma (o card só fala)'), findsNothing);
    });
  });
}
