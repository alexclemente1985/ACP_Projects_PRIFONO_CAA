import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_layout.dart';

/// O que acontece quando um card é solto numa posição da prancha (ADR-042,
/// regras a e b).
enum MoveKind {
  /// Nada muda (o card foi solto onde já estava).
  unchanged,

  /// O card vai para uma posição livre.
  move,

  /// O card troca de lugar com outro.
  swap,

  /// Não cabe: o card fica onde está e a tela avisa "Não cabe aí".
  blocked,
}

/// Resultado de [BoardMove]: o que fazer e com quem. Objeto de valor.
@immutable
class MovePlan {
  const MovePlan.unchanged()
      : kind = MoveKind.unchanged,
        target = null,
        other = null;

  const MovePlan.blocked()
      : kind = MoveKind.blocked,
        target = null,
        other = null;

  /// Mover o card para [target] (mesmo tamanho, novo canto superior esquerdo).
  const MovePlan.move(CardPlacement this.target)
      : kind = MoveKind.move,
        other = null;

  /// Trocar o card de lugar com [other].
  const MovePlan.swap(BoardCard this.other)
      : kind = MoveKind.swap,
        target = null;

  final MoveKind kind;

  /// Só em [MoveKind.move]: a nova posição do card.
  final CardPlacement? target;

  /// Só em [MoveKind.swap]: o card que troca de lugar com o arrastado.
  final BoardCard? other;

  /// Dá para gravar (mover ou trocar)?
  bool get canApply => kind == MoveKind.move || kind == MoveKind.swap;
}

/// Decide o que fazer ao soltar um card (arrastar) ou ao escolher uma posição
/// no diálogo "Mover…" (ADR-042, E6b-3). Funções puras, sem estado: a tela
/// consulta aqui ANTES de gravar, para avisar "Não cabe aí" sem usar a exceção
/// do repositório como fluxo normal (E6b-1.3).
///
/// Em todas, [cards] são TODOS os cards da prancha (inclusive o que se move);
/// as contas tiram sozinhas o card movido e, na troca, o card de destino.
abstract final class BoardMove {
  /// Soltar [dragged] na célula ([col], [row]): o canto superior esquerdo do
  /// card vai para ela e o tamanho se mantém (regra b). As células que o card
  /// ocupa hoje não contam como obstáculo.
  static MovePlan toCell(
    BoardCard dragged, {
    required int col,
    required int row,
    required Iterable<BoardCard> cards,
    required int columns,
    required int rows,
  }) {
    final target = dragged.placement.copyWith(col: col, row: row);
    if (target == dragged.placement) return const MovePlan.unchanged();
    final others = [
      for (final card in cards)
        if (card.id != dragged.id) card.placement,
    ];
    final fits = BoardLayout.canPlace(
      target,
      columns: columns,
      rows: rows,
      others: others,
    );
    return fits ? MovePlan.move(target) : const MovePlan.blocked();
  }

  /// Soltar [dragged] sobre [target]: os dois trocam de lugar, cada um com o
  /// seu tamanho (regra a); sem espaço para os dois, bloqueia.
  static MovePlan onto(
    BoardCard dragged,
    BoardCard target, {
    required Iterable<BoardCard> cards,
    required int columns,
    required int rows,
  }) {
    if (dragged.id == target.id) return const MovePlan.unchanged();
    final others = [
      for (final card in cards)
        if (card.id != dragged.id && card.id != target.id) card.placement,
    ];
    final swapped = BoardLayout.swap(
      dragged.placement,
      target.placement,
      columns: columns,
      rows: rows,
      others: others,
    );
    return swapped == null ? const MovePlan.blocked() : MovePlan.swap(target);
  }

  /// Escolher a posição ([col], [row]) no diálogo "Mover…": se outro card
  /// cobre essa célula, troca com ele ([onto]); se não, move para lá
  /// ([toCell]).
  static MovePlan toPosition(
    BoardCard card, {
    required int col,
    required int row,
    required Iterable<BoardCard> cards,
    required int columns,
    required int rows,
  }) {
    final cell = CardPlacement(col: col, row: row);
    BoardCard? occupant;
    for (final other in cards) {
      if (other.id != card.id && other.placement.overlaps(cell)) {
        occupant = other;
        break;
      }
    }
    if (occupant != null) {
      return onto(
        card,
        occupant,
        cards: cards,
        columns: columns,
        rows: rows,
      );
    }
    return toCell(
      card,
      col: col,
      row: row,
      cards: cards,
      columns: columns,
      rows: rows,
    );
  }
}
