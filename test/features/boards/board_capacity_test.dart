import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';

void main() {
  group('BoardCapacity', () {
    test('of multiplica colunas por linhas', () {
      expect(BoardCapacity.of(4, 3), 12);
      expect(BoardCapacity.of(1, 1), 1);
    });

    test('hasRoom é verdadeiro só enquanto há célula livre', () {
      expect(BoardCapacity.hasRoom(cardCount: 0, columns: 2, rows: 2), isTrue);
      expect(BoardCapacity.hasRoom(cardCount: 3, columns: 2, rows: 2), isTrue);
      expect(BoardCapacity.hasRoom(cardCount: 4, columns: 2, rows: 2), isFalse);
      expect(BoardCapacity.hasRoom(cardCount: 5, columns: 2, rows: 2), isFalse);
    });

    test('freeCells nunca é negativo', () {
      expect(BoardCapacity.freeCells(cardCount: 1, columns: 2, rows: 2), 3);
      expect(BoardCapacity.freeCells(cardCount: 4, columns: 2, rows: 2), 0);
      expect(BoardCapacity.freeCells(cardCount: 9, columns: 2, rows: 2), 0);
    });

    test('overflowAfterResize conta os cards que não caberiam', () {
      // 6 cards numa grade que passa a ter 4 células: 2 ficariam de fora.
      expect(
        BoardCapacity.overflowAfterResize(cardCount: 6, columns: 2, rows: 2),
        2,
      );
      // Cabe exatamente: mudança permitida.
      expect(
        BoardCapacity.overflowAfterResize(cardCount: 4, columns: 2, rows: 2),
        0,
      );
      expect(
        BoardCapacity.overflowAfterResize(cardCount: 0, columns: 1, rows: 1),
        0,
      );
    });

    test('as exceções guardam os números que a tela vai mostrar', () {
      expect(const BoardFullException(12).capacity, 12);
      expect(const BoardGridTooSmallException(3).cardsToRemove, 3);
    });
  });
}
