import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_layout.dart';

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

void main() {
  group('CardPlacement', () {
    test('overlaps: encostar nas bordas não é sobrepor', () {
      final big = _at(0, 0, 2, 2);

      expect(big.overlaps(_at(1, 1)), isTrue);
      expect(_at(1, 1).overlaps(big), isTrue); // simétrico
      expect(big.overlaps(_at(2, 0)), isFalse); // encosta à direita
      expect(big.overlaps(_at(0, 2)), isFalse); // encosta embaixo
      expect(big.overlaps(_at(5, 5)), isFalse);
    });

    test('igualdade por campos, endCol/endRow e copyWith', () {
      expect(_at(1, 2, 3, 4), _at(1, 2, 3, 4));
      expect(_at(1, 2, 3, 4).hashCode, _at(1, 2, 3, 4).hashCode);
      expect(_at(1, 2, 3, 4) == _at(1, 2, 3, 5), isFalse);
      expect(_at(1, 2, 3, 4).endCol, 4);
      expect(_at(1, 2, 3, 4).endRow, 6);
      expect(_at(1, 2).copyWith(col: 3), _at(3, 2));
      expect(_at(1, 2).copyWith(colSpan: 2, rowSpan: 3), _at(1, 2, 2, 3));
    });
  });

  group('BoardLayout.fits', () {
    test('aceita o que está inteiro dentro da grade', () {
      expect(BoardLayout.fits(_at(0, 0), columns: 1, rows: 1), isTrue);
      expect(BoardLayout.fits(_at(2, 1, 2, 2), columns: 4, rows: 3), isTrue);
    });

    test('recusa o que sai da grade ou tem tamanho inválido', () {
      expect(BoardLayout.fits(_at(3, 0, 2), columns: 4, rows: 3), isFalse);
      expect(BoardLayout.fits(_at(0, 2, 1, 2), columns: 4, rows: 3), isFalse);
      expect(BoardLayout.fits(_at(-1, 0), columns: 4, rows: 3), isFalse);
      expect(BoardLayout.fits(_at(0, -1), columns: 4, rows: 3), isFalse);
      expect(BoardLayout.fits(_at(0, 0, 0), columns: 4, rows: 3), isFalse);
      expect(BoardLayout.fits(_at(0, 0, 1, 0), columns: 4, rows: 3), isFalse);
    });
  });

  group('BoardLayout.isFree, canPlace e requirePlaceable', () {
    test('isFree e canPlace olham os outros cards e a grade', () {
      final others = [_at(1, 0)];

      expect(BoardLayout.isFree(_at(0, 0), others), isTrue);
      expect(BoardLayout.isFree(_at(0, 0, 2), others), isFalse);
      expect(
        BoardLayout.canPlace(_at(0, 1), columns: 2, rows: 2, others: others),
        isTrue,
      );
      expect(
        BoardLayout.canPlace(_at(1, 0), columns: 2, rows: 2, others: others),
        isFalse, // ocupada
      );
      expect(
        BoardLayout.canPlace(_at(2, 0), columns: 2, rows: 2, others: others),
        isFalse, // fora da grade
      );
    });

    test('requirePlaceable não lança quando cabe e está livre', () {
      expect(
        () => BoardLayout.requirePlaceable(
          _at(0, 1),
          columns: 2,
          rows: 2,
          others: [_at(1, 0)],
        ),
        returnsNormally,
      );
    });

    test('requirePlaceable lança ArgumentError fora da grade ou sobre card', () {
      expect(
        () => BoardLayout.requirePlaceable(
          _at(2, 0),
          columns: 2,
          rows: 2,
          others: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => BoardLayout.requirePlaceable(
          _at(1, 0),
          columns: 2,
          rows: 2,
          others: [_at(1, 0)],
        ),
        throwsArgumentError,
      );
    });
  });

  group('BoardLayout.firstFree', () {
    test('grade vazia: a primeira célula', () {
      expect(
        BoardLayout.firstFree(columns: 3, rows: 2, others: const []),
        _at(0, 0),
      );
    });

    test('segue a ordem de leitura: linha por linha, da esquerda para a direita',
        () {
      expect(
        BoardLayout.firstFree(
          columns: 3,
          rows: 2,
          others: [_at(0, 0), _at(1, 0)],
        ),
        _at(2, 0),
      );
      expect(
        BoardLayout.firstFree(
          columns: 3,
          rows: 2,
          others: [_at(0, 0), _at(1, 0), _at(2, 0)],
        ),
        _at(0, 1),
      );
    });

    test('um buraco no meio é reaproveitado antes do fim', () {
      expect(
        BoardLayout.firstFree(
          columns: 3,
          rows: 1,
          others: [_at(0, 0), _at(2, 0)],
        ),
        _at(1, 0),
      );
    });

    test('para um card maior, acha o primeiro lugar onde ele cabe inteiro', () {
      // Grade 3×2 com um card em (1,0): um 2×1 não cabe em (0,0) (cobriria o
      // card), nem em (2,0) (sairia da grade); o primeiro lugar é (0,1).
      expect(
        BoardLayout.firstFree(
          columns: 3,
          rows: 2,
          others: [_at(1, 0)],
          colSpan: 2,
        ),
        _at(0, 1, 2),
      );
    });

    test('devolve null quando não há lugar', () {
      expect(
        BoardLayout.firstFree(
          columns: 2,
          rows: 1,
          others: [_at(0, 0), _at(1, 0)],
        ),
        isNull,
      );
      expect(
        BoardLayout.firstFree(
          columns: 2,
          rows: 2,
          others: [_at(0, 0, 2, 2)],
        ),
        isNull,
      );
    });
  });

  group('BoardLayout.freeCells e hasRoom', () {
    test('contam células cobertas, não cards', () {
      // Um card 2×2 numa grade 3×2 cobre 4 das 6 células.
      final others = [_at(0, 0, 2, 2)];

      expect(
        BoardLayout.freeCells(columns: 3, rows: 2, others: others),
        2,
      );
      expect(BoardLayout.hasRoom(columns: 3, rows: 2, others: others), isTrue);
    });

    test('grade toda coberta: zero células e sem espaço; fora da grade ignora',
        () {
      expect(
        BoardLayout.freeCells(
          columns: 2,
          rows: 2,
          others: [_at(0, 0, 2, 2)],
        ),
        0,
      );
      expect(
        BoardLayout.hasRoom(columns: 2, rows: 2, others: [_at(0, 0, 2, 2)]),
        isFalse,
      );
      // Um card que está fora da grade não cobre célula nenhuma dela.
      expect(
        BoardLayout.freeCells(columns: 2, rows: 2, others: [_at(5, 5)]),
        4,
      );
    });
  });

  group('BoardLayout.swap', () {
    test('mesmo tamanho: cada um assume a posição do outro', () {
      final swapped = BoardLayout.swap(
        _at(0, 0),
        _at(2, 1),
        columns: 4,
        rows: 3,
        others: const [],
      );

      expect(swapped, isNotNull);
      expect(swapped!.$1, _at(2, 1));
      expect(swapped.$2, _at(0, 0));
    });

    test('tamanhos diferentes: cada um mantém o próprio tamanho', () {
      final swapped = BoardLayout.swap(
        _at(0, 0, 2),
        _at(2, 1),
        columns: 4,
        rows: 3,
        others: const [],
      );

      expect(swapped!.$1, _at(2, 1, 2));
      expect(swapped.$2, _at(0, 0));
    });

    test('devolve null quando um dos dois sairia da grade', () {
      // O card largo iria para a coluna 2 de uma grade de 3 colunas.
      expect(
        BoardLayout.swap(
          _at(0, 0, 2),
          _at(2, 0),
          columns: 3,
          rows: 1,
          others: const [],
        ),
        isNull,
      );
    });

    test('devolve null quando algum cobriria um terceiro card', () {
      expect(
        BoardLayout.swap(
          _at(0, 0, 2),
          _at(2, 1),
          columns: 4,
          rows: 3,
          others: [_at(3, 1)], // o card largo (2,1)-(3,1) bateria nele
        ),
        isNull,
      );
    });

    test('devolve null quando os dois se cobririam depois da troca', () {
      // 1×1 em (0,0) e 2×1 em (1,0): depois da troca o largo cobriria
      // (0,0)-(1,0) e o pequeno ficaria em (1,0).
      expect(
        BoardLayout.swap(
          _at(0, 0),
          _at(1, 0, 2),
          columns: 3,
          rows: 1,
          others: const [],
        ),
        isNull,
      );
    });
  });

  group('BoardLayout.cardsOutside', () {
    test('conta os cards que não ficariam inteiros na grade nova', () {
      // Os quatro cards de uma grade 2×2.
      final cards = [_at(0, 0), _at(1, 0), _at(0, 1), _at(1, 1)];

      expect(BoardLayout.cardsOutside(cards, columns: 1, rows: 2), 2);
      // 4 células sobram, mas dois cards estão na linha que sairia.
      expect(BoardLayout.cardsOutside(cards, columns: 4, rows: 1), 2);
      expect(BoardLayout.cardsOutside(cards, columns: 4, rows: 2), 0);
      expect(BoardLayout.cardsOutside(const [], columns: 1, rows: 1), 0);
      // Um card largo que passaria da borda também conta.
      expect(
        BoardLayout.cardsOutside([_at(1, 0, 2)], columns: 2, rows: 2),
        1,
      );
    });
  });
}
