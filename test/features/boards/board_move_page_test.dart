import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/board_page.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../../support/unlock_edit_mode.dart';

// Mover cards (ADR-042, E6b-3): arrastar SÓ em edição (soltar numa posição em
// branco move; soltar sobre outro card troca) e a alternativa "Mover…" para
// leitor de tela (botão no editor e ação do card).

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

class _Fixture {
  _Fixture(this.repository, this.board, this.first, this.second);

  final InMemoryBoardRepository repository;
  final Board board;
  final BoardCard first;
  final BoardCard second;
}

/// "Casa" 3 × 3:
///
///     Brincar Brincar  .
///     Brincar Brincar  .
///        .       .    Bola
Future<_Fixture> _seedBig() async {
  final repository = InMemoryBoardRepository();
  final board = await repository.createBoard(
    name: 'Casa',
    gridColumns: 3,
    gridRows: 3,
  );
  final brincar = await repository.addCard(
    board.id,
    const CardContent(label: 'Brincar'),
    placement: _at(0, 0, 2, 2),
  );
  final bola = await repository.addCard(
    board.id,
    const CardContent(label: 'Bola'),
    placement: _at(2, 2),
  );
  return _Fixture(repository, board, brincar, bola);
}

/// "Casa" 3 × 2, dois cards pequenos (a troca sempre cabe):
///
///     Um  .    .
///      .  .  Dois
Future<_Fixture> _seedPair() async {
  final repository = InMemoryBoardRepository();
  final board = await repository.createBoard(
    name: 'Casa',
    gridColumns: 3,
    gridRows: 2,
  );
  final um = await repository.addCard(
    board.id,
    const CardContent(label: 'Um'),
    placement: _at(0, 0),
  );
  final dois = await repository.addCard(
    board.id,
    const CardContent(label: 'Dois'),
    placement: _at(2, 1),
  );
  return _Fixture(repository, board, um, dois);
}

Future<void> _openCasa(
  WidgetTester tester,
  InMemoryBoardRepository repository,
) async {
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_move_');
  addTearDown(() => root.deleteSync(recursive: true));
  await tester.pumpWidget(
    AppScope(
      settings: SettingsController(),
      boards: repository,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle(); // splash
  await tester.tap(find.text('Casa'));
  await tester.pumpAndSettle();
}

Finder _blank(int col, int row) {
  return find.byKey(BoardPage.blankCellKey(col, row));
}

Finder _card(BoardCard card) => find.byKey(BoardPage.cardKey(card.id));

/// Segura o card (~0,5 s), arrasta até [to] e solta.
Future<void> _drag(WidgetTester tester, Finder from, Offset to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump(const Duration(milliseconds: 600));
  await gesture.moveBy(const Offset(12, 12));
  await tester.pump();
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<CardPlacement> _placementOf(_Fixture f, BoardCard card) async {
  final cards = await f.repository.listCards(f.board.id);
  return cards.singleWhere((c) => c.id == card.id).placement;
}

/// Abre o editor do card [label] (modo de edição já destravado).
Future<void> _openEditor(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  expect(find.byType(CardEditorPage), findsOneWidget);
}

Finder get _moveButton => find.widgetWithText(OutlinedButton, 'Mover…');

/// Toca em "Mover…" do editor (rola até ele, se preciso).
Future<void> _tapMove(WidgetTester tester) async {
  await tester.ensureVisible(_moveButton);
  await tester.pumpAndSettle();
  await tester.tap(_moveButton);
  await tester.pumpAndSettle();
}

Finder get _confirm => find.widgetWithText(FilledButton, 'Mover');

void main() {
  group('arrastar', () {
    testWidgets('em modo de uso os cards não são arrastáveis', (tester) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);

      expect(find.byType(LongPressDraggable<int>), findsNothing);
      expect(find.byType(DragTarget<int>), findsNothing);
    });

    testWidgets('em edição: um arrastável por card e um alvo por posição', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);

      expect(find.byType(LongPressDraggable<int>), findsNWidgets(2));
      // 2 cards + 4 posições em branco.
      expect(find.byType(DragTarget<int>), findsNWidgets(6));
    });

    testWidgets('soltar numa posição em branco move o card', (tester) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      final target = tester.getCenter(_blank(2, 0));

      await _drag(tester, _card(fixture.second), target);

      expect(await _placementOf(fixture, fixture.second), _at(2, 0));
      expect(_blank(2, 2), findsOneWidget); // a posição antiga ficou em branco
      expect(_blank(2, 0), findsNothing);
    });

    testWidgets('soltar sobre outro card troca os dois de lugar', (
      tester,
    ) async {
      final fixture = await _seedPair();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      final target = tester.getCenter(_card(fixture.second));

      await _drag(tester, _card(fixture.first), target);

      expect(await _placementOf(fixture, fixture.first), _at(2, 1));
      expect(await _placementOf(fixture, fixture.second), _at(0, 0));
    });

    testWidgets('soltar fora de qualquer alvo não muda nada', (tester) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);

      // O ponto fica acima da prancha (na barra de cima).
      await _drag(tester, _card(fixture.second), const Offset(5, 5));

      expect(await _placementOf(fixture, fixture.second), _at(2, 2));
      expect(find.text('Não cabe aí.'), findsNothing);
    });

    testWidgets('card que não cabe na posição: avisa e não move', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      // O 2×2 no canto de cima à direita sairia da grade de 3 colunas.
      final target = tester.getCenter(_blank(2, 0));

      await _drag(tester, _card(fixture.first), target);

      expect(find.text('Não cabe aí.'), findsOneWidget);
      expect(await _placementOf(fixture, fixture.first), _at(0, 0, 2, 2));
    });

    testWidgets('troca que não cabe: avisa e não troca', (tester) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      final target = tester.getCenter(_card(fixture.first));

      await _drag(tester, _card(fixture.second), target);

      expect(find.text('Não cabe aí.'), findsOneWidget);
      expect(await _placementOf(fixture, fixture.second), _at(2, 2));
      expect(await _placementOf(fixture, fixture.first), _at(0, 0, 2, 2));
    });

    testWidgets('um toque curto no card continua abrindo o editor', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);

      await tester.tap(find.text('Bola'));
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorPage), findsOneWidget);
    });

    testWidgets('contorno aparece sobre uma posição que aceita o card', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      final inBlank = find.descendant(
        of: _blank(2, 0),
        matching: find.byType(DecoratedBox),
      );
      final before = tester.widgetList(inBlank).length;

      final gesture = await tester.startGesture(
        tester.getCenter(_card(fixture.second)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(12, 12));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(_blank(2, 0)));
      await tester.pump();

      expect(tester.widgetList(inBlank).length, before + 1);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('Mover… (alternativa ao arrastar)', () {
    testWidgets('o editor de um card existente tem "Mover…"; o de novo não', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);

      await _openEditor(tester, 'Bola');
      expect(_moveButton, findsOneWidget);

      Navigator.of(tester.element(find.byType(CardEditorPage))).pop();
      await tester.pumpAndSettle();
      await tester.tap(_blank(2, 0));
      await tester.pumpAndSettle();
      expect(find.text('Novo card'), findsOneWidget);
      expect(_moveButton, findsNothing);
    });

    testWidgets('o diálogo abre na posição atual e diz que nada muda', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Bola');

      await _tapMove(tester);

      expect(find.text('Mover card'), findsOneWidget);
      expect(find.text('Linha 3 de 3'), findsOneWidget);
      expect(find.text('Coluna 3 de 3'), findsOneWidget);
      expect(find.text('Já está nesta posição.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_confirm).onPressed, isNull);
    });

    testWidgets('escolher uma posição livre move e o editor continua aberto', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Bola');
      await _tapMove(tester);

      await tester.tap(find.byTooltip('Linha anterior (para cima)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Linha anterior (para cima)'));
      await tester.pumpAndSettle();
      expect(find.text('Linha 1 de 3'), findsOneWidget);
      expect(find.text('Vai para a linha 1, coluna 3.'), findsOneWidget);
      await tester.tap(_confirm);
      await tester.pumpAndSettle();

      expect(await _placementOf(fixture, fixture.second), _at(2, 0));
      expect(find.text('Card movido.'), findsOneWidget);
      expect(find.byType(CardEditorPage), findsOneWidget);
    });

    testWidgets('escolher a posição de outro card troca os dois', (
      tester,
    ) async {
      final fixture = await _seedPair();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Um');
      await _tapMove(tester);

      await tester.tap(find.byTooltip('Próxima linha (para baixo)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Próxima coluna (para a direita)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Próxima coluna (para a direita)'));
      await tester.pumpAndSettle();
      expect(find.text('Troca de lugar com “Dois”.'), findsOneWidget);
      await tester.tap(_confirm);
      await tester.pumpAndSettle();

      expect(await _placementOf(fixture, fixture.first), _at(2, 1));
      expect(await _placementOf(fixture, fixture.second), _at(0, 0));
      expect(find.text('Cards trocados de lugar.'), findsOneWidget);
    });

    testWidgets('posição que não cabe: avisa e o botão fica desligado', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Brincar');
      await _tapMove(tester);

      await tester.tap(find.byTooltip('Próxima coluna (para a direita)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Próxima coluna (para a direita)'));
      await tester.pumpAndSettle();

      expect(find.text('Não cabe aí.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_confirm).onPressed, isNull);
    });

    testWidgets('cancelar não muda nada', (tester) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Bola');
      await _tapMove(tester);
      await tester.tap(find.byTooltip('Linha anterior (para cima)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Mover card'), findsNothing);
      expect(await _placementOf(fixture, fixture.second), _at(2, 2));
    });

    testWidgets('em edição o card oferece a ação "Mover…" ao leitor de tela', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.bySemanticsLabel('Bola'));
        final ids = node.getSemanticsData().customSemanticsActionIds ?? [];
        final labels = [
          for (final id in ids) CustomSemanticsAction.getAction(id)?.label,
        ];
        expect(labels, contains('Mover…'));

        // Disparar a ação abre o mesmo diálogo.
        tester.semantics.performAction(
          find.semantics.byLabel('Bola'),
          SemanticsAction.customAction,
          args: ids.first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Mover card'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('em uso o card não oferece a ação "Mover…"', (tester) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.bySemanticsLabel('Bola'));
        final ids = node.getSemanticsData().customSemanticsActionIds ?? [];
        expect(ids, isEmpty);
      } finally {
        handle.dispose();
      }
    });
  });
}
