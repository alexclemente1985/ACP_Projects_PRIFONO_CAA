import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_layout.dart';

/// Tamanho de um card em posições da grade (colunas × linhas), do jeito que o
/// editor o entrega ao salvar (ADR-042, E6b-4).
typedef CardSize = ({int colSpan, int rowSpan});

/// Lado do card que o editor aumenta ou diminui.
enum CardAxis { width, height }

/// O que o editor precisa saber da grade para oferecer o tamanho do card.
///
/// É um retrato: o editor pede um novo a cada vez que desenha (e depois de um
/// "Mover…"), porque o card pode ter mudado de lugar com o editor aberto.
final class CardGridSpace {
  const CardGridSpace({
    required this.columns,
    required this.rows,
    required this.origin,
    required this.others,
  });

  final int columns;
  final int rows;

  /// Canto superior esquerdo do card e tamanho JÁ SALVO. Em card existente,
  /// a posição atual; em card novo, a posição em branco tocada (1×1).
  final CardPlacement origin;

  /// As posições dos OUTROS cards da prancha (o próprio card fica de fora).
  final List<CardPlacement> others;
}

/// Regras do tamanho do card no editor (ADR-042, regras c e d): o card cresce
/// só para a direita e para baixo, só sobre posições em branco, e nunca sai da
/// grade. Diminuir é sempre permitido, até 1×1.
///
/// Funções puras: a tela consulta antes de oferecer o "+"; o repositório
/// confere de novo ao gravar (`ArgumentError`).
abstract final class CardSizeRules {
  /// O card, com o tamanho [colSpan] × [rowSpan] a partir de `space.origin`,
  /// cabe na grade e não cobre nenhum outro card?
  static bool fits(
    CardGridSpace space, {
    required int colSpan,
    required int rowSpan,
  }) {
    return BoardLayout.canPlace(
      CardPlacement(
        col: space.origin.col,
        row: space.origin.row,
        colSpan: colSpan,
        rowSpan: rowSpan,
      ),
      columns: space.columns,
      rows: space.rows,
      others: space.others,
    );
  }

  /// Dá para aumentar [axis] em uma posição a partir do tamanho atual?
  static bool canGrow(
    CardGridSpace space,
    CardAxis axis, {
    required int colSpan,
    required int rowSpan,
  }) {
    return switch (axis) {
      CardAxis.width => fits(space, colSpan: colSpan + 1, rowSpan: rowSpan),
      CardAxis.height => fits(space, colSpan: colSpan, rowSpan: rowSpan + 1),
    };
  }

  /// Dá para diminuir [axis]? (Mínimo 1×1.)
  static bool canShrink(
    CardAxis axis, {
    required int colSpan,
    required int rowSpan,
  }) {
    return switch (axis) {
      CardAxis.width => colSpan > 1,
      CardAxis.height => rowSpan > 1,
    };
  }

  /// Máximo teórico de [axis] (a grade inteira). Serve só de referência para
  /// mostrar "2 de 4"; o que vale de verdade é [canGrow].
  static int maxFor(CardGridSpace space, CardAxis axis) {
    return switch (axis) {
      CardAxis.width => space.columns,
      CardAxis.height => space.rows,
    };
  }
}
