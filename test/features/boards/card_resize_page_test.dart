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
import 'package:prifono_caa/features/boards/presentation/board_page.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../../support/unlock_edit_mode.dart';

// Largura e altura do card no editor (ADR-042, E6b-4), pela BoardPage: o
// tamanho só é gravado ao SALVAR, o card novo já nasce com o tamanho escolhido
// e a regra (só cresce sobre posição em branco, dentro da grade) vale de ponta
// a ponta.

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

class _Fixture {
  _Fixture(this.repository, this.board, this.cards);

  final InMemoryBoardRepository repository;
  final Board board;
  final Map<String, BoardCard> cards;
}

/// "Casa" 3 × 2 com um card pequeno:
///
///     Um  .  .
///      .  .  .
Future<_Fixture> _seedSmall() async {
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
  return _Fixture(repository, board, {'Um': um});
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
  return _Fixture(repository, board, {'Brincar': brincar, 'Bola': bola});
}

Future<void> _openCasa(
  WidgetTester tester,
  InMemoryBoardRepository repository,
) async {
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_resize_');
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

Future<void> _openEditor(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  expect(find.byType(CardEditorPage), findsOneWidget);
}

Future<void> _tapStepper(WidgetTester tester, String tooltip) async {
  await tester.ensureVisible(find.byTooltip(tooltip));
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

IconButton _stepper(WidgetTester tester, String tooltip) {
  return tester.widget<IconButton>(
    find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)),
  );
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();
}

Future<List<BoardCard>> _cardsOf(_Fixture f) {
  return f.repository.listCards(f.board.id);
}

Future<CardPlacement> _placementOf(_Fixture f, BoardCard card) async {
  final cards = await _cardsOf(f);
  return cards.singleWhere((c) => c.id == card.id).placement;
}

void main() {
  group('tamanho do card pela BoardPage', () {
    testWidgets('aumentar a largura e salvar ocupa a posição em branco', (
      tester,
    ) async {
      final fixture = await _seedSmall();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Um');

      await _tapStepper(tester, 'Aumentar a largura');
      await _save(tester);

      expect(find.byType(CardEditorPage), findsNothing);
      expect(await _placementOf(fixture, fixture.cards['Um']!), _at(0, 0, 2));
      expect(_blank(1, 0), findsNothing); // a posição foi consumida
      expect(_blank(2, 0), findsOneWidget);
    });

    testWidgets('card novo já nasce com o tamanho escolhido', (tester) async {
      final fixture = await _seedSmall();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await tester.tap(_blank(1, 0));
      await tester.pumpAndSettle();
      expect(find.text('Novo card'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Dois');
      await _tapStepper(tester, 'Aumentar a largura');
      await _tapStepper(tester, 'Aumentar a altura');
      await _save(tester);

      final cards = await _cardsOf(fixture);
      expect(cards, hasLength(2));
      final dois = cards.singleWhere((c) => c.content.label == 'Dois');
      expect(dois.placement, _at(1, 0, 2, 2));
    });

    testWidgets('diminuir e salvar devolve posições em branco', (tester) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Brincar');

      await _tapStepper(tester, 'Diminuir a largura');
      await _tapStepper(tester, 'Diminuir a altura');
      await _save(tester);

      expect(
        await _placementOf(fixture, fixture.cards['Brincar']!),
        _at(0, 0),
      );
      expect(_blank(1, 0), findsOneWidget);
      expect(_blank(0, 1), findsOneWidget);
      expect(_blank(1, 1), findsOneWidget);
    });

    testWidgets('na borda da grade os dois "+" ficam desligados, com o motivo', (
      tester,
    ) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Bola'); // canto de baixo à direita

      expect(_stepper(tester, 'Aumentar a largura').onPressed, isNull);
      expect(_stepper(tester, 'Aumentar a altura').onPressed, isNull);
      expect(
        find.textContaining('Não há espaço para crescer à direita.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Não há espaço para crescer para baixo.'),
        findsOneWidget,
      );
    });

    testWidgets('mudar só o texto não mexe no tamanho', (tester) async {
      final fixture = await _seedBig();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Brincar');

      await tester.enterText(
        find.byType(TextFormField).first,
        'Brincar muito',
      );
      await _save(tester);

      final cards = await _cardsOf(fixture);
      final card = cards.singleWhere(
        (c) => c.id == fixture.cards['Brincar']!.id,
      );
      expect(card.content.label, 'Brincar muito');
      expect(card.placement, _at(0, 0, 2, 2));
    });

    testWidgets('voltar sem salvar não grava o tamanho', (tester) async {
      final fixture = await _seedSmall();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Um');

      await _tapStepper(tester, 'Aumentar a largura');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorPage), findsNothing);
      expect(await _placementOf(fixture, fixture.cards['Um']!), _at(0, 0));
      expect(_blank(1, 0), findsOneWidget);
    });

    testWidgets('posição ocupada no meio da edição: avisa e não grava nada', (
      tester,
    ) async {
      final fixture = await _seedSmall();
      await _openCasa(tester, fixture.repository);
      await unlockEditMode(tester);
      await _openEditor(tester, 'Um');
      await _tapStepper(tester, 'Aumentar a largura');

      // Outro card ocupa a posição por baixo do editor (a tela ainda não sabe).
      await fixture.repository.addCard(
        fixture.board.id,
        const CardContent(label: 'Intruso'),
        placement: _at(1, 0),
      );
      await tester.enterText(find.byType(TextFormField).first, 'Um novo');
      await _save(tester);

      expect(
        find.text('O tamanho escolhido não cabe mais. Ajuste e salve de novo.'),
        findsOneWidget,
      );
      expect(find.byType(CardEditorPage), findsOneWidget);
      final cards = await _cardsOf(fixture);
      final um = cards.singleWhere(
        (c) => c.id == fixture.cards['Um']!.id,
      );
      expect(um.placement, _at(0, 0));
      expect(um.content.label, 'Um'); // o conteúdo também não foi gravado
    });
  });
}
