import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_cell_size.dart';

void main() {
  group('BoardCellSize', () {
    test('largura da célula num telefone de 390 dp (ADR-041)', () {
      double width(int columns) =>
          BoardCellSize.widthFor(screenWidth: 390, columns: columns);

      expect(width(6), closeTo(53, 0.1));
      expect(width(7), closeTo(44.3, 0.1));
      expect(width(8), closeTo(37.75, 0.1));
    });

    test('célula pequena demais = abaixo de 48 dp', () {
      bool tooSmall(double screenWidth, int columns) =>
          BoardCellSize.isTooSmall(screenWidth: screenWidth, columns: columns);

      expect(tooSmall(390, 6), isFalse);
      expect(tooSmall(390, 7), isTrue);
      expect(tooSmall(390, 8), isTrue);
      // Exatamente 48 dp ainda vale: (360 - 32 - 40) / 6 = 48.
      expect(tooSmall(360, 6), isFalse);
      // Tablet: o máximo de 10 colunas continua folgado.
      expect(tooSmall(1280, 10), isFalse);
    });

    test('maior número de colunas que mantém 48 dp', () {
      expect(BoardCellSize.maxColumnsFor(390), 6);
      expect(BoardCellSize.maxColumnsFor(360), 6);
      expect(BoardCellSize.maxColumnsFor(359), 5);
      expect(BoardCellSize.maxColumnsFor(1280), greaterThanOrEqualTo(10));
      // Nunca menos que 1, mesmo numa tela minúscula.
      expect(BoardCellSize.maxColumnsFor(50), 1);
    });

    test('o máximo calculado concorda com isTooSmall em todas as larguras', () {
      for (var width = 100; width <= 1400; width++) {
        final screenWidth = width.toDouble();
        final max = BoardCellSize.maxColumnsFor(screenWidth);

        expect(
          BoardCellSize.isTooSmall(screenWidth: screenWidth, columns: max),
          isFalse,
          reason: 'largura $width, $max colunas deveriam caber',
        );
        expect(
          BoardCellSize.isTooSmall(screenWidth: screenWidth, columns: max + 1),
          isTrue,
          reason: 'largura $width, ${max + 1} colunas não deveriam caber',
        );
      }
    });
  });
}