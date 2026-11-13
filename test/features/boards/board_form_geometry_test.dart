import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/board_form_dialog.dart';

// O formulário da prancha olha a GEOMETRIA dos cards, não só a quantidade
// (ADR-042, regra f): um card que ocupa a última coluna ou linha impede a
// redução, mesmo que sobrem células.

Board _board({int columns = 3, int rows = 3}) {
  return Board(
    id: 1,
    name: 'Casa',
    gridColumns: columns,
    gridRows: rows,
    position: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

/// Abre o formulário de edição de [board] com os cards em [placements].
Future<void> _openForm(
  WidgetTester tester, {
  required Board board,
  required List<CardPlacement> placements,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showBoardFormDialog(
                context,
                board: board,
                placements: placements,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

/// Botões "−": o primeiro é o das colunas, o último é o das linhas.
IconButton _decreaseColumns(WidgetTester tester) => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove).first,
    );

IconButton _decreaseRows(WidgetTester tester) => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove).last,
    );

void main() {
  group('formulário da prancha e a posição dos cards', () {
    testWidgets('sem cards, dá para reduzir até 1 × 1', (tester) async {
      await _openForm(tester, board: _board(), placements: const []);

      expect(_decreaseColumns(tester).onPressed, isNotNull);
      expect(_decreaseRows(tester).onPressed, isNotNull);
      expect(find.textContaining('na última coluna ou linha'), findsNothing);
    });

    testWidgets('card na última coluna trava só as colunas', (tester) async {
      await _openForm(
        tester,
        board: _board(),
        placements: const [CardPlacement(col: 2, row: 0)],
      );

      expect(_decreaseColumns(tester).onPressed, isNull);
      expect(_decreaseRows(tester).onPressed, isNotNull);
      expect(
        find.textContaining('Há 1 card na última coluna ou linha'),
        findsOneWidget,
      );
    });

    testWidgets('card na última linha trava só as linhas', (tester) async {
      await _openForm(
        tester,
        board: _board(),
        placements: const [CardPlacement(col: 0, row: 2)],
      );

      expect(_decreaseColumns(tester).onPressed, isNotNull);
      expect(_decreaseRows(tester).onPressed, isNull);
    });

    testWidgets('um card grande trava mesmo com muitas células sobrando', (
      tester,
    ) async {
      // 1 card só, 2×2, no canto inferior direito de uma grade 4 × 4: sobram
      // 12 células, mas tirar uma coluna ou linha cortaria o card.
      await _openForm(
        tester,
        board: _board(columns: 4, rows: 4),
        placements: const [
          CardPlacement(col: 2, row: 2, colSpan: 2, rowSpan: 2),
        ],
      );

      expect(_decreaseColumns(tester).onPressed, isNull);
      expect(_decreaseRows(tester).onPressed, isNull);
    });

    testWidgets('com mais de um card de fora, o aviso traz o maior número', (
      tester,
    ) async {
      await _openForm(
        tester,
        board: _board(),
        placements: const [
          CardPlacement(col: 2, row: 0),
          CardPlacement(col: 2, row: 1),
          CardPlacement(col: 0, row: 2),
        ],
      );

      // Tirar uma coluna deixa 2 de fora; tirar uma linha deixa 1.
      expect(_decreaseColumns(tester).onPressed, isNull);
      expect(_decreaseRows(tester).onPressed, isNull);
      expect(
        find.textContaining('Há 2 cards na última coluna ou linha'),
        findsOneWidget,
      );
    });

    testWidgets('aumentar a grade continua livre e destrava a redução', (
      tester,
    ) async {
      await _openForm(
        tester,
        board: _board(columns: 2, rows: 2),
        placements: const [CardPlacement(col: 1, row: 1)],
      );
      expect(_decreaseColumns(tester).onPressed, isNull);

      await tester.tap(find.byTooltip('Aumentar colunas'));
      await tester.pump();

      // 3 colunas: tirar uma volta a 2 colunas, onde o card ainda cabe.
      expect(_decreaseColumns(tester).onPressed, isNotNull);
    });
  });
}
