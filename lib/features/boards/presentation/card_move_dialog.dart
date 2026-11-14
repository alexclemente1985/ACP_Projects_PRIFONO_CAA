import 'package:flutter/material.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_move.dart';

/// Diálogo "Mover…" (ADR-042, E6b-3): a alternativa ao arrastar para quem usa
/// leitor de tela, Switch Access ou simplesmente prefere tocar.
///
/// A pessoa escolhe a linha e a coluna do canto superior esquerdo do card. Uma
/// mensagem (região viva) diz o que vai acontecer: ir para a posição, trocar
/// de lugar com outro card, ou "Não cabe aí". Devolve o [MovePlan] escolhido
/// ou `null` (cancelou). Quem chama grava; o diálogo não toca no banco.
Future<MovePlan?> showCardMoveDialog(
  BuildContext context, {
  required BoardCard card,
  required List<BoardCard> cards,
  required int columns,
  required int rows,
}) {
  return showDialog<MovePlan>(
    context: context,
    builder: (_) => _CardMoveDialog(
      card: card,
      cards: cards,
      columns: columns,
      rows: rows,
    ),
  );
}

class _CardMoveDialog extends StatefulWidget {
  const _CardMoveDialog({
    required this.card,
    required this.cards,
    required this.columns,
    required this.rows,
  });

  final BoardCard card;
  final List<BoardCard> cards;
  final int columns;
  final int rows;

  @override
  State<_CardMoveDialog> createState() => _CardMoveDialogState();
}

class _CardMoveDialogState extends State<_CardMoveDialog> {
  // Começa na posição atual do card (0-based; a tela mostra de 1 em diante).
  late int _col = widget.card.placement.col;
  late int _row = widget.card.placement.row;

  MovePlan _plan() {
    return BoardMove.toPosition(
      widget.card,
      col: _col,
      row: _row,
      cards: widget.cards,
      columns: widget.columns,
      rows: widget.rows,
    );
  }

  String _message(AppLocalizations l10n, MovePlan plan) {
    final target = plan.target;
    final other = plan.other;
    if (plan.kind == MoveKind.move && target != null) {
      return l10n.cardMoveWillMove(target.row + 1, target.col + 1);
    }
    if (plan.kind == MoveKind.swap && other != null) {
      return l10n.cardMoveWillSwap(other.content.label);
    }
    if (plan.kind == MoveKind.blocked) return l10n.cardMoveBlocked;
    return l10n.cardMoveUnchanged;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final plan = _plan();

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.cardMoveTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PositionStepper(
            text: l10n.cardMoveRowOf(_row + 1, widget.rows),
            previousTooltip: l10n.cardMoveRowPrev,
            nextTooltip: l10n.cardMoveRowNext,
            canDecrease: _row > 0,
            canIncrease: _row < widget.rows - 1,
            onDecrease: () => setState(() => _row--),
            onIncrease: () => setState(() => _row++),
          ),
          const SizedBox(height: 8),
          _PositionStepper(
            text: l10n.cardMoveColumnOf(_col + 1, widget.columns),
            previousTooltip: l10n.cardMoveColumnPrev,
            nextTooltip: l10n.cardMoveColumnNext,
            canDecrease: _col > 0,
            canIncrease: _col < widget.columns - 1,
            onDecrease: () => setState(() => _col--),
            onIncrease: () => setState(() => _col++),
          ),
          const SizedBox(height: 16),
          // Região viva: o leitor de tela avisa o que vai acontecer a cada
          // passo, sem a pessoa precisar sair do botão.
          Semantics(
            liveRegion: true,
            child: Text(
              _message(l10n, plan),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed:
              plan.canApply ? () => Navigator.of(context).pop(plan) : null,
          child: Text(l10n.cardMoveConfirm),
        ),
      ],
    );
  }
}

/// Linha "− Linha 2 de 4 +": o texto é região viva (o valor novo é anunciado)
/// e os dois botões têm tooltip, que também é o rótulo para o leitor de tela.
class _PositionStepper extends StatelessWidget {
  const _PositionStepper({
    required this.text,
    required this.previousTooltip,
    required this.nextTooltip,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String text;
  final String previousTooltip;
  final String nextTooltip;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: previousTooltip,
          icon: const Icon(Icons.remove),
          onPressed: canDecrease ? onDecrease : null,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: nextTooltip,
          icon: const Icon(Icons.add),
          onPressed: canIncrease ? onIncrease : null,
        ),
      ],
    );
  }
}
