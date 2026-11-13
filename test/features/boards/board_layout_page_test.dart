import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_cell_size.dart';
import 'package:prifono_caa/features/boards/presentation/board_page.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../../support/unlock_edit_mode.dart';

// A prancha desenhada por COORDENADAS (ADR-042, E6b-2): cada card no retângulo
// da sua posição, posições em branco sempre visíveis e, em edição, um "+" em
// cada uma delas.

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

/// Prancha "Casa" 3 × 3 com um card grande e um pequeno:
///
///     Brincar Brincar  .
///     Brincar Brincar  .
///        .       .    Bola
class _Fixture {
  _Fixture(this.repository, this.board, this.brincar, this.bola);

  final InMemoryBoardRepository repository;
  final Board board;
  final BoardCard brincar;
  final BoardCard bola;
}

Future<_Fixture> _seed() async {
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

/// Sobe o app com [repository] e abre a prancha "Casa" (em modo de USO).
Future<void> _openCasa(
  WidgetTester tester,
  InMemoryBoardRepository repository,
) async {
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_layout_');
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

Finder get _plus => find.byTooltip('Adicionar card');

void main() {
  group('modo de uso', () {
    testWidgets('desenha o card grande e as posições em branco', (
      tester,
    ) async {
      final fixture = await _seed();
      await _openCasa(tester, fixture.repository);

      // Em branco: as 4 posições que nenhum card cobre.
      for (final (col, row) in [(2, 0), (2, 1), (0, 2), (1, 2)]) {
        expect(_blank(col, row), findsOneWidget, reason: 'branco $col,$row');
      }
      // Cobertas por card: não há posição em branco ali.
      for (final (col, row) in [(0, 0), (1, 0), (0, 1), (1, 1), (2, 2)]) {
        expect(_blank(col, row), findsNothing, reason: 'coberta $col,$row');
      }
      expect(find.text('Brincar'), findsOneWidget);
      expect(find.text('Bola'), findsOneWidget);
      expect(_plus, findsNothing);
    });

    testWidgets('o card 2×2 ocupa duas células e o espaço entre elas', (
      tester,
    ) async {
      final fixture = await _seed();
      await _openCasa(tester, fixture.repository);

      final big = tester.getRect(_card(fixture.brincar));
      final cell = tester.getRect(_blank(2, 0));
      const gap = BoardCellSize.gap;

      expect(big.top, closeTo(cell.top, 0.5));
      expect(big.right + gap, closeTo(cell.left, 0.5));
      expect(big.width, closeTo(2 * cell.width + gap, 0.5));
      expect(big.height, closeTo(2 * cell.height + gap, 0.5));
    });

    testWidgets('o card pequeno fica na posição certa, sob o grande', (
      tester,
    ) async {
      final fixture = await _seed();
      await _openCasa(tester, fixture.repository);

      final big = tester.getRect(_card(fixture.brincar));
      final small = tester.getRect(_card(fixture.bola));
      final upperRight = tester.getRect(_blank(2, 1));

      expect(small.left, closeTo(upperRight.left, 0.5));
      expect(small.top, greaterThan(upperRight.bottom));
      expect(small.top, greaterThan(big.bottom));
      expect(small.size.width, closeTo(upperRight.size.width, 0.5));
    });

    testWidgets('tocar numa posição em branco não abre nada', (tester) async {
      final fixture = await _seed();
      await _openCasa(tester, fixture.repository);

      await tester.tap(_blank(2, 0), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorPage), findsNothing);
      final cards = await fixture.repository.listCards(fixture.board.id);
      expect(cards, hasLength(2));
    });

    testWidgets('as posições em branco ficam fora da leitura de tela', (
      tester,
    ) async {
      final fixture = await _seed();
      await _openCasa(tester, fixture.repository);
      final handle = tester.ensureSemantics();
      try {
        expect(find.bySemanticsLabel(RegExp('Adicionar card')), findsNothing);
        expect(find.bySemanticsLabel('Brincar'), findsOneWidget);
        expect(find.bySemanticsLabel('Bola'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });

  group('modo de edição', () {
    testWidgets('um "+" em cada posição em branco, e só nelas', (
      tester,
    ) async {
      final fixture = await _seed();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);

      expect(_plus, findsNWidgets(4));
      for (final (col, row) in [(2, 0), (2, 1), (0, 2), (1, 2)]) {
        expect(
          find.descendant(of: _blank(col, row), matching: _plus),
          findsOneWidget,
          reason: '+ em $col,$row',
        );
      }
    });

    testWidgets('cada "+" diz a própria posição ao leitor de tela', (
      tester,
    ) async {
      final fixture = await _seed();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      final handle = tester.ensureSemantics();
      try {
        // A posição em branco (coluna 3, linha 2) conta a partir de 1.
        expect(
          find.bySemanticsLabel('Adicionar card na linha 2, coluna 3'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Adicionar card na linha 3, coluna 1'),
          findsOneWidget,
        );
        // Posição coberta por card não tem "+".
        expect(
          find.bySemanticsLabel('Adicionar card na linha 1, coluna 1'),
          findsNothing,
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('o "+" cria o card exatamente na posição tocada', (
      tester,
    ) async {
      final fixture = await _seed();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      final target = tester.getRect(_blank(2, 1));

      await tester.tap(_blank(2, 1));
      await tester.pumpAndSettle();
      expect(find.text('Novo card'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Água');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final cards = await fixture.repository.listCards(fixture.board.id);
      final created = cards.singleWhere((c) => c.content.label == 'Água');
      expect(created.placement, _at(2, 1));
      // Na tela: o card novo ocupa o lugar do "+" e só sobram 3 "+".
      final shown = tester.getRect(_card(created));
      expect(shown.topLeft, offsetMoreOrLessEquals(target.topLeft));
      expect(shown.width, moreOrLessEquals(target.width));
      expect(shown.height, moreOrLessEquals(target.height));
      expect(_blank(2, 1), findsNothing);
      expect(_plus, findsNWidgets(3));
    });

    testWidgets('excluir um card deixa a posição em branco e não move outros', (
      tester,
    ) async {
      final fixture = await _seed();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      final bolaBefore = tester.getRect(_card(fixture.bola));
      final bigRect = tester.getRect(_card(fixture.brincar));

      await tester.tap(find.text('Brincar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Excluir card'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Brincar'), findsNothing);
      expect(
        tester.getRect(_card(fixture.bola)).topLeft,
        offsetMoreOrLessEquals(bolaBefore.topLeft),
      );
      // As 4 células que o card cobria viram posições em branco com "+".
      for (final (col, row) in [(0, 0), (1, 0), (0, 1), (1, 1)]) {
        expect(_blank(col, row), findsOneWidget, reason: 'branco $col,$row');
      }
      expect(_plus, findsNWidgets(8));
      // O "+" da posição (0,0) volta a ocupar o canto do card excluído.
      expect(
        tester.getRect(_blank(0, 0)).topLeft,
        offsetMoreOrLessEquals(bigRect.topLeft),
      );
    });

    testWidgets('prancha totalmente ocupada: sem "+" e com aviso de cheia', (
      tester,
    ) async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 2,
        gridRows: 2,
      );
      // 1 card só, mas ele cobre as 4 posições.
      await repository.addCard(
        board.id,
        const CardContent(label: 'Tudo'),
        placement: _at(0, 0, 2, 2),
      );
      await _openCasa(tester, repository);
      await unlockEditMode(tester);

      expect(_plus, findsNothing);
      expect(
        find.textContaining('todas as 4 posições estão ocupadas'),
        findsOneWidget,
      );
    });
  });
}
