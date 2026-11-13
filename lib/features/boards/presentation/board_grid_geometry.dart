import 'dart:math' as math;
import 'dart:ui';

import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_layout.dart';

/// Contas de posição da prancha na TELA (ADR-042): transformam o lugar de um
/// card na grade (coluna, linha, largura, altura) em um retângulo em pixels.
///
/// São funções puras, sem widget: a tela só desenha o que elas devolvem.
abstract final class BoardGridGeometry {
  /// Retângulo do [placement] numa área de [width] × [height] dividida em
  /// [columns] × [rows] células, com [gap] entre células vizinhas.
  ///
  /// Um card de várias células cobre também os espaços entre elas, então não
  /// fica nenhum "vão" dentro dele. Células nunca têm tamanho negativo.
  static Rect rectFor(
    CardPlacement placement, {
    required double width,
    required double height,
    required int columns,
    required int rows,
    required double gap,
  }) {
    final cellWidth = _cellSize(width, columns, gap);
    final cellHeight = _cellSize(height, rows, gap);
    return Rect.fromLTWH(
      placement.col * (cellWidth + gap),
      placement.row * (cellHeight + gap),
      placement.colSpan * cellWidth + (placement.colSpan - 1) * gap,
      placement.rowSpan * cellHeight + (placement.rowSpan - 1) * gap,
    );
  }

  static double _cellSize(double total, int count, double gap) {
    return math.max(0, (total - gap * (count - 1)) / count);
  }

  /// Posições em branco (células 1×1 que nenhum card cobre), em ordem de
  /// leitura: linha por linha, da esquerda para a direita.
  static List<CardPlacement> blankCells({
    required int columns,
    required int rows,
    required Iterable<CardPlacement> placements,
  }) {
    final taken = placements.toList();
    return [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < columns; col++)
          if (BoardLayout.isFree(CardPlacement(col: col, row: row), taken))
            CardPlacement(col: col, row: row),
    ];
  }
}
