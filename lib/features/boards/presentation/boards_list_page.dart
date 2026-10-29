import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/presentation/board_form_dialog.dart';
import 'package:prifono_caa/features/boards/presentation/board_page.dart';
import 'package:prifono_caa/features/boards/presentation/boards_controller.dart';
import 'package:prifono_caa/features/editing/presentation/edit_lock_button.dart';
import 'package:prifono_caa/features/editing/presentation/edit_lock_on_background.dart';
import 'package:prifono_caa/features/settings/presentation/settings_page.dart';

enum _BoardAction { edit, delete }

/// Tela inicial: lista de pranchas.
class BoardsListPage extends StatefulWidget {
  const BoardsListPage({super.key});

  @override
  State<BoardsListPage> createState() => _BoardsListPageState();
}

class _BoardsListPageState extends State<BoardsListPage> {
  // getInheritedWidgetOfExactType (usado pelo AppScope.of) pode ser chamado
  // no initState; dependOn... não poderia.
  late final BoardsController _controller =
      BoardsController(AppScope.of(context).boards);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Executa uma operação de escrita e avisa o usuário se falhar.
  Future<void> _run(Future<void> Function() action) async {
    // Capturados ANTES do await (o context pode não valer depois dele).
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await action();
    } on BoardGridTooSmallException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.boardGridTooSmall(error.cardsToRemove))),
      );
    } on Exception {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.boardActionFailed)));
    }
  }

  Future<void> _create() async {
    final result = await showBoardFormDialog(context);
    if (result == null) return;
    await _run(
      () => _controller.create(
        name: result.name,
        columns: result.columns,
        rows: result.rows,
      ),
    );
  }

  Future<void> _edit(Board board) async {
    await _run(() async {
      final cardCount = await _controller.cardCount(board.id);
      if (!mounted) return;
      final result = await showBoardFormDialog(
        context,
        board: board,
        cardCount: cardCount,
      );
      if (result == null) return;
      await _controller.update(
        board.copyWith(
          name: result.name,
          gridColumns: result.columns,
          gridRows: result.rows,
        ),
      );
    });
  }

  Future<void> _delete(Board board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDeleteDialog(boardName: board.name),
    );
    if (confirmed != true) return;
    await _run(() => _controller.delete(board.id));
  }

  void _open(Board board) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BoardPage(board: board)),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editMode = AppScope.of(context).editMode;

    // O EditLockOnBackground fica aqui, na tela inicial (sempre na pilha),
    // para travar a edição quando o app vai para segundo plano.
    return EditLockOnBackground(
      child: ListenableBuilder(
        listenable: editMode,
        builder: (context, _) =>
            _buildScaffold(context, l10n, editing: editMode.isEditing),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppLocalizations l10n, {
    required bool editing,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.boardsTitle),
        actions: [
          const EditLockButton(),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      floatingActionButton: editing
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: Text(l10n.boardNew),
            )
          : null,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            switch (_controller.status) {
              case BoardsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case BoardsStatus.error:
                return _CenteredMessage(
                  title: l10n.boardsLoadError,
                  action: FilledButton(
                    onPressed: _controller.load,
                    child: Text(l10n.commonRetry),
                  ),
                );
              case BoardsStatus.ready:
                if (_controller.boards.isEmpty) {
                  return _CenteredMessage(
                    title: l10n.boardsEmptyTitle,
                    message: l10n.boardsEmptyMessage,
                    action: FilledButton(
                      onPressed: _create,
                      child: Text(l10n.boardsEmptyAction),
                    ),
                  );
                }
                return ListView.separated(
                  // Espaço no fim para o botão flutuante não cobrir o último item.
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: _controller.boards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final board = _controller.boards[index];
                    return _BoardTile(
                      board: board,
                      editing: editing,
                      onOpen: () => _open(board),
                      onEdit: () => _edit(board),
                      onDelete: () => _delete(board),
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({
    required this.board,
    required this.editing,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Board board;

  /// Só no modo de edição aparece o menu de editar e excluir.
  final bool editing;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        title: Text(board.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          l10n.boardGridSummary(board.gridColumns, board.gridRows),
        ),
        onTap: onOpen,
        trailing: editing
            ? PopupMenuButton<_BoardAction>(
                tooltip: l10n.boardMoreOptions,
                onSelected: (action) {
                  switch (action) {
                    case _BoardAction.edit:
                      onEdit();
                    case _BoardAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _BoardAction.edit,
                    child: Text(l10n.boardEdit),
                  ),
                  PopupMenuItem(
                    value: _BoardAction.delete,
                    child: Text(l10n.boardDelete),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({required this.boardName});

  final String boardName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.boardDeleteTitle),
      content: Text(l10n.boardDeleteMessage(boardName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.boardDelete),
        ),
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.title, this.message, this.action});

  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}