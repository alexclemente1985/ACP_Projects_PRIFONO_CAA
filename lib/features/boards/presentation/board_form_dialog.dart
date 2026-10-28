import 'package:flutter/material.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';

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
/// Devolve null se o usuário cancelar.
Future<BoardFormResult?> showBoardFormDialog(
  BuildContext context, {
  Board? board,
}) {
  return showDialog<BoardFormResult>(
    context: context,
    builder: (_) => _BoardFormDialog(board: board),
  );
}

class _BoardFormDialog extends StatefulWidget {
  const _BoardFormDialog({this.board});

  final Board? board;

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      BoardFormResult(name: _name.text.trim(), columns: _columns, rows: _rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                onChanged: (value) => setState(() => _columns = value),
              ),
              const SizedBox(height: 8),
              _StepperRow(
                label: l10n.boardFormRows,
                value: _rows,
                decreaseTooltip: l10n.boardRowsDecrease,
                increaseTooltip: l10n.boardRowsIncrease,
                onChanged: (value) => setState(() => _rows = value),
              ),
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
    required this.onChanged,
  });

  final String label;
  final int value;
  final String decreaseTooltip;
  final String increaseTooltip;
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
          onPressed: value > Board.minGrid ? () => onChanged(value - 1) : null,
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
