import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/card_size_rules.dart';

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

CardGridSpace _space({
  int columns = 4,
  int rows = 3,
  CardPlacement? origin,
  List<CardPlacement> others = const [],
}) {
  return CardGridSpace(
    columns: columns,
    rows: rows,
    origin: origin ?? _at(0, 0),
    others: others,
  );
}

void main() {
  group('CardSizeRules.canGrow', () {
    test('largura cresce quando a posição à direita está em branco', () {
      final space = _space();

      expect(
        CardSizeRules.canGrow(space, CardAxis.width, colSpan: 1, rowSpan: 1),
        isTrue,
      );
    });

    test('largura não cresce sobre outro card', () {
      final space = _space(others: [_at(1, 0)]);

      expect(
        CardSizeRules.canGrow(space, CardAxis.width, colSpan: 1, rowSpan: 1),
        isFalse,
      );
    });

    test('altura não cresce sobre outro card, mas a largura ainda cresce', () {
      final space = _space(others: [_at(0, 1)]);

      expect(
        CardSizeRules.canGrow(space, CardAxis.height, colSpan: 1, rowSpan: 1),
        isFalse,
      );
      expect(
        CardSizeRules.canGrow(space, CardAxis.width, colSpan: 1, rowSpan: 1),
        isTrue,
      );
    });

    test('não cresce além da borda da grade', () {
      final space = _space(origin: _at(3, 2));

      expect(
        CardSizeRules.canGrow(space, CardAxis.width, colSpan: 1, rowSpan: 1),
        isFalse,
      );
      expect(
        CardSizeRules.canGrow(space, CardAxis.height, colSpan: 1, rowSpan: 1),
        isFalse,
      );
    });

    test('card que já ocupa a grade inteira não cresce', () {
      final space = _space(columns: 2, rows: 2, origin: _at(0, 0, 2, 2));

      expect(
        CardSizeRules.canGrow(space, CardAxis.width, colSpan: 2, rowSpan: 2),
        isFalse,
      );
      expect(
        CardSizeRules.canGrow(space, CardAxis.height, colSpan: 2, rowSpan: 2),
        isFalse,
      );
    });

    test('só a coluna nova importa: o vizinho depois dela não atrapalha', () {
      final wide = _at(0, 0, 2);

      expect(
        CardSizeRules.canGrow(
          _space(origin: wide, others: [_at(2, 0)]),
          CardAxis.width,
          colSpan: 2,
          rowSpan: 1,
        ),
        isFalse,
      );
      expect(
        CardSizeRules.canGrow(
          _space(origin: wide, others: [_at(3, 0)]),
          CardAxis.width,
          colSpan: 2,
          rowSpan: 1,
        ),
        isTrue,
      );
    });

    test('a linha nova inteira precisa estar livre (qualquer célula barra)', () {
      // O card 2×1 quer a linha de baixo; só a célula (1, 1) está ocupada.
      final space = _space(origin: _at(0, 0, 2), others: [_at(1, 1)]);

      expect(
        CardSizeRules.canGrow(space, CardAxis.height, colSpan: 2, rowSpan: 1),
        isFalse,
      );
    });
  });

  group('CardSizeRules (demais regras)', () {
    test('canShrink: só acima de 1', () {
      expect(
        CardSizeRules.canShrink(CardAxis.width, colSpan: 2, rowSpan: 1),
        isTrue,
      );
      expect(
        CardSizeRules.canShrink(CardAxis.width, colSpan: 1, rowSpan: 3),
        isFalse,
      );
      expect(
        CardSizeRules.canShrink(CardAxis.height, colSpan: 1, rowSpan: 2),
        isTrue,
      );
      expect(
        CardSizeRules.canShrink(CardAxis.height, colSpan: 3, rowSpan: 1),
        isFalse,
      );
    });

    test('fits e maxFor seguem a grade e os outros cards', () {
      final space = _space(others: [_at(2, 0)]);

      expect(CardSizeRules.fits(space, colSpan: 2, rowSpan: 3), isTrue);
      expect(CardSizeRules.fits(space, colSpan: 3, rowSpan: 1), isFalse);
      expect(CardSizeRules.fits(space, colSpan: 5, rowSpan: 1), isFalse);
      expect(CardSizeRules.maxFor(space, CardAxis.width), 4);
      expect(CardSizeRules.maxFor(space, CardAxis.height), 3);
    });
  });
}
