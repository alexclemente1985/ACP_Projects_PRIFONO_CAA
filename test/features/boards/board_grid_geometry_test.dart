import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/board_grid_geometry.dart';

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

void main() {
  group('BoardGridGeometry.rectFor', () {
    // 4 colunas × 2 linhas em 430 × 210, com 10 de espaço: cada célula
    // mede 100 × 100.
    Rect rect(CardPlacement placement) {
      return BoardGridGeometry.rectFor(
        placement,
        width: 430,
        height: 210,
        columns: 4,
        rows: 2,
        gap: 10,
      );
    }

    test('célula 1×1 na origem e em outras posições', () {
      expect(rect(_at(0, 0)), const Rect.fromLTWH(0, 0, 100, 100));
      expect(rect(_at(1, 0)), const Rect.fromLTWH(110, 0, 100, 100));
      expect(rect(_at(3, 1)), const Rect.fromLTWH(330, 110, 100, 100));
    });

    test('card de várias células cobre também os espaços entre elas', () {
      // 2 colunas: 100 + 10 + 100. 2 linhas: 100 + 10 + 100.
      expect(rect(_at(2, 0, 2, 2)), const Rect.fromLTWH(220, 0, 210, 210));
      expect(rect(_at(0, 0, 4, 1)), const Rect.fromLTWH(0, 0, 430, 100));
    });

    test('a última célula termina exatamente na borda da área', () {
      final last = rect(_at(3, 1));
      expect(last.right, 430);
      expect(last.bottom, 210);
    });

    test('área menor que os espaços: células com tamanho zero, nunca negativo',
        () {
      final tiny = BoardGridGeometry.rectFor(
        _at(1, 1),
        width: 5,
        height: 5,
        columns: 4,
        rows: 4,
        gap: 10,
      );

      expect(tiny.width, 0);
      expect(tiny.height, 0);
    });
  });

  group('BoardGridGeometry.blankCells', () {
    test('prancha vazia: todas as posições, em ordem de leitura', () {
      final blanks = BoardGridGeometry.blankCells(
        columns: 3,
        rows: 2,
        placements: const [],
      );

      expect(blanks, [
        _at(0, 0),
        _at(1, 0),
        _at(2, 0),
        _at(0, 1),
        _at(1, 1),
        _at(2, 1),
      ]);
    });

    test('card grande tira todas as células que cobre', () {
      final blanks = BoardGridGeometry.blankCells(
        columns: 3,
        rows: 2,
        placements: [_at(0, 0, 2, 2)],
      );

      expect(blanks, [_at(2, 0), _at(2, 1)]);
    });

    test('card excluído deixa buraco; os outros não se mexem', () {
      final blanks = BoardGridGeometry.blankCells(
        columns: 2,
        rows: 2,
        placements: [_at(0, 0), _at(1, 1)],
      );

      expect(blanks, [_at(1, 0), _at(0, 1)]);
    });

    test('prancha totalmente ocupada não tem posição em branco', () {
      final blanks = BoardGridGeometry.blankCells(
        columns: 2,
        rows: 1,
        placements: [_at(0, 0), _at(1, 0)],
      );

      expect(blanks, isEmpty);
    });

    test('card fora da grade é ignorado (só as células de dentro contam)', () {
      final blanks = BoardGridGeometry.blankCells(
        columns: 2,
        rows: 1,
        placements: [_at(5, 5)],
      );

      expect(blanks, [_at(0, 0), _at(1, 0)]);
    });
  });
}
