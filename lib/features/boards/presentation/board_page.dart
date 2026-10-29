import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/board_cards_controller.dart';
import 'package:prifono_caa/features/boards/presentation/card_colors.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_bar.dart';
import 'package:prifono_caa/features/speech/presentation/speak_with_feedback.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';

/// Tela da prancha: grade de cards em ordem de leitura (ADR-026), sem
/// rolagem (ADR-025). A grade ocupa toda a área livre da tela.
class BoardPage extends StatefulWidget {
  const BoardPage({required this.board, super.key});

  final Board board;

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  late final BoardCardsController _controller = BoardCardsController(
    AppScope.of(context).boards,
    board: widget.board,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Ações de EDIÇÃO (ADR-027): na E5 ficam atrás do PIN. ---

  Future<void> _addCard() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CardEditorPage(onSave: _controller.add),
      ),
    );
  }

  Future<void> _editCard(BoardCard card) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CardEditorPage(
          initial: card.content,
          onSave: (content) => _controller.update(card.id, content),
          onDelete: () => _controller.delete(card.id),
        ),
      ),
    );
  }

  // --- Ações de USO (ADR-027). ---

  /// Tocar no card FALA o texto dele (E5-1) e o ADICIONA à barra de frase
  /// (E5-2). A edição fica no toque longo até o modo de edição protegido
  /// chegar (E5-3).
  void _useCard(BoardCard card) {
    AppScope.of(context).sentence.add(SentenceItem.fromContent(card.content));
    unawaited(speakWithFeedback(context, card.content.textToSpeak));
  }

  String? _statusMessage(AppLocalizations l10n) {
    if (_controller.cards.isEmpty) return l10n.boardEmptyHint;
    if (!_controller.hasRoom) return l10n.boardFull(_controller.capacity);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.board.name)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            switch (_controller.status) {
              case CardsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case CardsStatus.error:
                return _LoadError(
                  title: l10n.boardCardsLoadError,
                  retryLabel: l10n.commonRetry,
                  onRetry: _controller.load,
                );
              case CardsStatus.ready:
                return _buildReady(context, l10n);
            }
          },
        ),
      ),
    );
  }

  Widget _buildReady(BuildContext context, AppLocalizations l10n) {
    final message = _statusMessage(l10n);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SentenceBar(controller: AppScope.of(context).sentence),
          const SizedBox(height: 12),
          // Texto ACIMA da grade (convenção do projeto para testes e leitura).
          if (message != null) ...[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: _BoardGrid(
              board: widget.board,
              cards: _controller.cards,
              onAdd: _addCard,
              onUse: _useCard,
              onEdit: _editCard,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grade colunas × linhas. Célula i recebe o card de índice i (ordem de
/// leitura); a primeira célula livre é o único "+" (ADR-026).
class _BoardGrid extends StatelessWidget {
  const _BoardGrid({
    required this.board,
    required this.cards,
    required this.onAdd,
    required this.onUse,
    required this.onEdit,
  });

  final Board board;
  final List<BoardCard> cards;
  final VoidCallback onAdd;
  final ValueChanged<BoardCard> onUse;
  final ValueChanged<BoardCard> onEdit;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).symbolImages;
    final columns = board.gridColumns;
    final rows = board.gridRows;

    Widget cellAt(int index) {
      if (index < cards.length) {
        final card = cards[index];
        final symbol = card.content.symbol;
        return _CardTile(
          card: card,
          imageFile: symbol == null
              ? null
              : store.fileFor(symbol, size: SymbolImageSize.medium),
          onUse: () => onUse(card),
          onEdit: () => onEdit(card),
        );
      }
      if (index == cards.length) return _AddTile(onPressed: onAdd);
      return const _EmptyCell();
    }

    return Column(
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: _gap),
                  Expanded(child: cellAt(r * columns + c)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.imageFile,
    required this.onUse,
    required this.onEdit,
  });

  final BoardCard card;
  final File? imageFile;
  final VoidCallback onUse;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final argb = card.content.backgroundColor;
    final background =
        argb == null ? scheme.surface : CardColors.fromArgb(argb);
    final foreground = argb == null
        ? scheme.onSurface
        : CardColors.foregroundFor(background);
    final label = card.content.label;
    final file = imageFile;

    // Semantics (label + button) e o gesto do InkWell viram UM nó: o leitor
    // de tela lê o rótulo uma vez, sem repetir o conteúdo visual.
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline, width: 1.5),
        ),
        child: InkWell(
          onTap: onUse,
          onLongPress: onEdit,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  if (file != null) Expanded(flex: 3, child: _CardImage(file: file)),
                  Expanded(
                    flex: file != null ? 2 : 1,
                    child: _CardLabel(label: label, color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pictograma sobre placa branca (ADR-029): contraste independe do tema.
class _CardImage extends StatelessWidget {
  const _CardImage({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.branco,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.file(
          file,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          errorBuilder: (context, _, _) => const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: BrandColors.tinta,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rótulo: quebra em linhas e só encolhe se não couber na célula.
class _CardLabel extends StatelessWidget {
  const _CardLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Text(label, textAlign: TextAlign.center, style: style),
            ),
          ),
        );
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: l10n.cardAdd,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: l10n.cardAdd,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.outline, width: 2),
          ),
          child: InkWell(
            onTap: onPressed,
            child: ExcludeSemantics(
              child: Center(
                child: Icon(Icons.add, size: 36, color: scheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Célula livre além do "+": só uma moldura discreta.
class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.title,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}