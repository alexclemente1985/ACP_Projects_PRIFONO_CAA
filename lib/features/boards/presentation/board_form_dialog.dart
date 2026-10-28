import 'package:flutter/material.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';

/// Dados confirmados no formulário de prancha.
final class BoardFormResult {
  const BoardFormResult({
    required this.name,
    required this.columns,
    required this.rows,
  });

  final String name;
  final int columns;
  final int rows;
}

/// Abre o formulário de prancha. Com [board], edita; sem, cria.
/// [cardCount] é quantos cards a prancha já tem: a grade não pode ficar
/// menor que isso (ADR-025). Devolve null se o usuário cancelar.
Future<BoardFormResult?> showBoardFormDialog(
  BuildContext context, {
  Board? board,
  int cardCount = 0,
}) {
  return showDialog<BoardFormResult>(
    context: context,
    builder: (_) => _BoardFormDialog(board: board, cardCount: cardCount),
  );
}

class _BoardFormDialog extends StatefulWidget {
  const _BoardFormDialog({required this.cardCount, this.board});

  final Board? board;
  final int cardCount;

  @override
  State<_BoardFormDialog> createState() => _BoardFormDialogState();
}

class _BoardFormDialogState extends State<_BoardFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.board?.name ?? '');
  late int _columns = widget.board?.gridColumns ?? Board.defaultColumns;
  late int _rows = widget.board?.gridRows ?? Board.defaultRows;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Os cards atuais cabem numa grade de [columns] × [rows]?
  bool _fits(int columns, int rows) {
    return BoardCapacity.overflowAfterResize(
          cardCount: widget.cardCount,
          columns: columns,
          rows: rows,
        ) ==
        0;
  }

  bool get _canDecreaseColumns =>
      _columns > Board.minGrid && _fits(_columns - 1, _rows);

  bool get _canDecreaseRows =>
      _rows > Board.minGrid && _fits(_columns, _rows - 1);

  /// Algum "−" está desativado só por causa dos cards (não pelo mínimo)?
  bool get _shrinkBlocked =>
      (_columns > Board.minGrid && !_canDecreaseColumns) ||
      (_rows > Board.minGrid && !_canDecreaseRows);

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      BoardFormResult(name: _name.text.trim(), columns: _columns, rows: _rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.board != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.boardFormEditTitle : l10n.boardFormNewTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.boardFormNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.boardFormNameRequired;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              _StepperRow(
                label: l10n.boardFormColumns,
                value: _columns,
                decreaseTooltip: l10n.boardColumnsDecrease,
                increaseTooltip: l10n.boardColumnsIncrease,
                canDecrease: _canDecreaseColumns,
                onChanged: (value) => setState(() => _columns = value),
              ),
              const SizedBox(height: 8),
              _StepperRow(
                label: l10n.boardFormRows,
                value: _rows,
                decreaseTooltip: l10n.boardRowsDecrease,
                increaseTooltip: l10n.boardRowsIncrease,
                canDecrease: _canDecreaseRows,
                onChanged: (value) => setState(() => _rows = value),
              ),
              if (_shrinkBlocked) ...[
                const SizedBox(height: 12),
                // liveRegion: o leitor de tela avisa quando o texto aparece.
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.boardFormShrinkBlocked(widget.cardCount),
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.commonSave)),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.canDecrease,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String decreaseTooltip;
  final String increaseTooltip;
  final bool canDecrease;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyLarge)),
        IconButton.filledTonal(
          tooltip: decreaseTooltip,
          icon: const Icon(Icons.remove),
          onPressed: canDecrease ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
        ),
        IconButton.filledTonal(
          tooltip: increaseTooltip,
          icon: const Icon(Icons.add),
          onPressed: value < Board.maxGrid ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}