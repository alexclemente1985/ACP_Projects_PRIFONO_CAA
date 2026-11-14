import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_cell_size.dart';
import 'package:prifono_caa/features/boards/domain/board_move.dart';
import 'package:prifono_caa/features/boards/presentation/board_cards_controller.dart';
import 'package:prifono_caa/features/boards/presentation/board_grid_geometry.dart';
import 'package:prifono_caa/features/boards/presentation/card_colors.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/boards/presentation/card_label_fit.dart';
import 'package:prifono_caa/features/boards/presentation/card_move_dialog.dart';
import 'package:prifono_caa/features/boards/presentation/word_class_text.dart';
import 'package:prifono_caa/features/editing/presentation/edit_lock_button.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_bar.dart';
import 'package:prifono_caa/features/speech/presentation/speak_with_feedback.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';

/// Tela da prancha: cards em posições da grade (ADR-042), sem rolagem
/// (ADR-025). A grade ocupa toda a área livre da tela e toda posição sem card
/// continua visível: em uso fica apagada; em edição vira um "+".
class BoardPage extends StatefulWidget {
  const BoardPage({required this.board, super.key});

  final Board board;

  /// Chave da posição em branco ([col], [row]) (para testes).
  static Key blankCellKey(int col, int row) => ValueKey('blank-$col-$row');

  /// Chave do card de id [cardId] (para testes).
  static Key cardKey(int cardId) => ValueKey('card-$cardId');

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  /// A mensagem de estado ocupa no máximo esta fração da área útil; passando
  /// disso (texto ampliado), ela rola por dentro (ADR-041, A6).
  static const double _messageMaxHeightFactor = 0.2;

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

  // --- Ações de EDIÇÃO (ADR-027): só no modo de edição (E5-3). ---

  /// Abre o editor para um card novo EXATAMENTE na posição em branco
  /// [placement] (a que o usuário tocou).
  Future<void> _addCard(CardPlacement placement) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CardEditorPage(
          currentBoardId: widget.board.id,
          onSave: (content) => _controller.add(content, placement: placement),
        ),
      ),
    );
  }

  Future<void> _editCard(BoardCard card) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CardEditorPage(
          currentBoardId: widget.board.id,
          initial: card.content,
          onSave: (content) => _controller.update(card.id, content),
          onDelete: () => _controller.delete(card.id),
          onMove: () => _moveWithDialog(card.id),
        ),
      ),
    );
  }

  // --- Ações de USO (ADR-027). ---

  /// Modo de USO: tocar no card FALA o texto dele (E5-1) e o ADICIONA à barra
  /// de frase (E5-2). Não há toque longo: editar é só no modo de edição.
  ///
  /// Card com link para outra prancha (E5-4) faz o mesmo e, em seguida, ABRE a
  /// prancha de destino (ADR-039, pedido da fonoaudióloga). Se a prancha de
  /// destino não existir mais, o card age como comum: fala, entra na frase e
  /// não navega.
  void _useCard(BoardCard card) {
    _speakAndAdd(card);
    final linkId = card.content.linkBoardId;
    if (linkId != null) unawaited(_openLinkedBoard(linkId));
  }

  void _speakAndAdd(BoardCard card) {
    AppScope.of(context).sentence.add(SentenceItem.fromContent(card.content));
    unawaited(speakWithFeedback(context, card.content.textToSpeak));
  }

  Future<void> _openLinkedBoard(int boardId) async {
    // Capturados ANTES do await.
    final navigator = Navigator.of(context);
    final repository = AppScope.of(context).boards;
    Board? found;
    try {
      found = await repository.getBoard(boardId);
    } on Exception {
      found = null;
    }
    if (!mounted) return;
    final destination = found;
    if (destination == null) return;
    await navigator.push<void>(
      MaterialPageRoute<void>(builder: (_) => BoardPage(board: destination)),
    );
  }

  // --- Mover cards (ADR-042, E6b-3): só no modo de edição. ---

  BoardCard? _cardById(int id) {
    for (final card in _controller.cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  /// "Mover…" (editor e ação de leitor de tela): escolhe a posição num diálogo
  /// e aplica na hora. O card é relido pelo id porque ele pode ter mudado de
  /// lugar desde que o editor abriu.
  Future<void> _moveWithDialog(int cardId) async {
    final card = _cardById(cardId);
    if (card == null) return;
    final plan = await showCardMoveDialog(
      context,
      card: card,
      cards: _controller.cards,
      columns: widget.board.gridColumns,
      rows: widget.board.gridRows,
    );
    if (plan == null || !mounted) return;
    await _applyMove(card, plan, announce: true);
  }

  /// Um card foi SOLTO numa posição em branco (arrastar).
  void _dropOnCell(int draggedId, CardPlacement blank) {
    final dragged = _cardById(draggedId);
    if (dragged == null) return;
    final plan = BoardMove.toCell(
      dragged,
      col: blank.col,
      row: blank.row,
      cards: _controller.cards,
      columns: widget.board.gridColumns,
      rows: widget.board.gridRows,
    );
    unawaited(_applyMove(dragged, plan));
  }

  /// Um card foi SOLTO sobre outro (arrastar): os dois trocam de lugar.
  void _dropOnCard(int draggedId, BoardCard target) {
    final dragged = _cardById(draggedId);
    if (dragged == null) return;
    final plan = BoardMove.onto(
      dragged,
      target,
      cards: _controller.cards,
      columns: widget.board.gridColumns,
      rows: widget.board.gridRows,
    );
    unawaited(_applyMove(dragged, plan));
  }

  /// Grava o [plan]. A tela já consultou o `BoardMove`, então o repositório
  /// não deve recusar; se recusar (estado mudou no meio), avisa em vez de
  /// quebrar. [announce]: confirma por escrito (o diálogo não mostra o
  /// resultado na grade para quem usa leitor de tela); no arrastar, o próprio
  /// card em outro lugar já é a confirmação.
  Future<void> _applyMove(
    BoardCard card,
    MovePlan plan, {
    bool announce = false,
  }) async {
    // Capturados ANTES do await.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (plan.kind == MoveKind.unchanged) return;
    if (plan.kind == MoveKind.blocked) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cardMoveBlocked)));
      return;
    }
    final target = plan.target;
    final other = plan.other;
    try {
      if (plan.kind == MoveKind.move && target != null) {
        await _controller.move(card.id, col: target.col, row: target.row);
        if (announce) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.cardMoveDone)));
        }
      } else if (plan.kind == MoveKind.swap && other != null) {
        await _controller.swap(card.id, other.id);
        if (announce) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.cardSwapDone)));
        }
      }
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.boardActionFailed)));
    } on ArgumentError {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cardMoveBlocked)));
    }
  }

  String? _statusMessage(AppLocalizations l10n, {required bool editing}) {
    if (editing) {
      if (_controller.cards.isEmpty) return l10n.boardEmptyHint;
      if (!_controller.hasRoom) return l10n.boardFull(_controller.capacity);
      return l10n.editModeHint;
    }
    if (_controller.cards.isEmpty) return l10n.boardEmptyUseHint;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editMode = AppScope.of(context).editMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.board.name),
        actions: const [EditLockButton()],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_controller, editMode]),
          builder: (context, _) {
            switch (_controller.status) {
              case CardsStatus.loading:
                return Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: l10n.commonLoading,
                  ),
                );
              case CardsStatus.error:
                return _LoadError(
                  title: l10n.boardCardsLoadError,
                  retryLabel: l10n.commonRetry,
                  onRetry: _controller.load,
                );
              case CardsStatus.ready:
                return _buildReady(context, l10n, editing: editMode.isEditing);
            }
          },
        ),
      ),
    );
  }

  Widget _buildReady(
    BuildContext context,
    AppLocalizations l10n, {
    required bool editing,
  }) {
    final message = _statusMessage(l10n, editing: editing);
    return Padding(
      padding: const EdgeInsets.all(BoardCellSize.pagePadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              SentenceBar(controller: AppScope.of(context).sentence),
              const SizedBox(height: 12),
              // Texto ACIMA da grade (convenção do projeto para testes e
              // leitura).
              if (message != null) ...[
                _StatusMessage(
                  message: message,
                  maxHeight: constraints.maxHeight * _messageMaxHeightFactor,
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: _BoardGrid(
                  board: widget.board,
                  cards: _controller.cards,
                  editing: editing,
                  onAdd: _addCard,
                  onUse: _useCard,
                  onEdit: _editCard,
                  onMove: (card) => unawaited(_moveWithDialog(card.id)),
                  onDropOnCell: _dropOnCell,
                  onDropOnCard: _dropOnCard,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Mensagem de estado acima da grade. Com texto ampliado ela pode ficar longa:
/// a altura é limitada e o que passar disso rola por dentro (a grade não
/// perde linhas). Região viva: o leitor de tela avisa quando a mensagem
/// aparece ou muda (entrar na edição, prancha cheia, prancha vazia). A região
/// viva fica DENTRO da rolagem, junto do texto, para o aviso levar a frase.
class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.maxHeight});

  final String message;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        primary: false,
        child: SizedBox(
          width: double.infinity,
          child: Semantics(
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}

/// Grade colunas × linhas desenhada por COORDENADAS (ADR-042): cada card fica
/// no retângulo da sua posição e as posições sem card são sempre desenhadas
/// (em edição, cada uma é um "+" que cria o card ali).
///
/// Em EDIÇÃO (E6b-3) cada card pode ser arrastado (segurar e arrastar) e cada
/// card e cada posição em branco recebe o que for solto: numa posição em
/// branco o card MOVE; sobre outro card os dois TROCAM de lugar. A decisão (e
/// o "Não cabe aí") vem do `BoardMove`; aqui só se desenha o contorno que
/// mostra o que vai acontecer.
///
/// Acessibilidade: a grade é UM grupo, lido em ordem de leitura (linha e,
/// dentro da linha, coluna), inclusive com cards que ocupam várias células. O
/// arrastar não tem equivalente para leitor de tela: a alternativa é a ação
/// "Mover…" do card (e o botão do editor).
class _BoardGrid extends StatelessWidget {
  const _BoardGrid({
    required this.board,
    required this.cards,
    required this.editing,
    required this.onAdd,
    required this.onUse,
    required this.onEdit,
    required this.onMove,
    required this.onDropOnCell,
    required this.onDropOnCard,
  });

  final Board board;
  final List<BoardCard> cards;

  /// Modo de edição: as posições em branco viram "+", tocar no card abre o
  /// editor e os cards podem ser arrastados.
  final bool editing;
  final ValueChanged<CardPlacement> onAdd;
  final ValueChanged<BoardCard> onUse;
  final ValueChanged<BoardCard> onEdit;

  /// Ação "Mover…" do card (leitor de tela e Switch Access), só em edição.
  final ValueChanged<BoardCard> onMove;

  /// O card de id `draggedId` foi solto numa posição em branco.
  final void Function(int draggedId, CardPlacement blank) onDropOnCell;

  /// O card de id `draggedId` foi solto sobre `target`.
  final void Function(int draggedId, BoardCard target) onDropOnCard;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).symbolImages;
    final columns = board.gridColumns;
    final rows = board.gridRows;
    final blanks = BoardGridGeometry.blankCells(
      columns: columns,
      rows: rows,
      placements: [for (final card in cards) card.placement],
    );

    File? imageOf(BoardCard card) {
      final symbol = card.content.symbol;
      if (symbol == null) return null;
      return store.fileFor(symbol, size: SymbolImageSize.medium);
    }

    BoardCard? cardById(int id) {
      for (final card in cards) {
        if (card.id == id) return card;
      }
      return null;
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          Rect rectOf(CardPlacement placement) {
            return BoardGridGeometry.rectFor(
              placement,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              columns: columns,
              rows: rows,
              gap: BoardCellSize.gap,
            );
          }

          /// O que acontece se o card que está sendo arrastado (o primeiro de
          /// [candidates]) for solto aqui; `null` = nada passando por cima.
          MoveKind? hoverKind(
            List<int?> candidates,
            MovePlan Function(BoardCard dragged) planFor,
          ) {
            if (candidates.isEmpty) return null;
            final id = candidates.first;
            if (id == null) return null;
            final dragged = cardById(id);
            if (dragged == null) return null;
            return planFor(dragged).kind;
          }

          Widget blankCell(CardPlacement blank) {
            if (!editing) return const _BlankCell();
            final tile = _AddTile(
              placement: blank,
              order: blank.row * columns + blank.col,
              onPressed: () => onAdd(blank),
            );
            // O DragTarget não tem gesto próprio: o toque no "+" continua
            // indo para o InkWell dele.
            return DragTarget<int>(
              onAcceptWithDetails: (details) =>
                  onDropOnCell(details.data, blank),
              builder: (context, candidates, rejected) {
                return _DropHighlight(
                  kind: hoverKind(
                    candidates,
                    (dragged) => BoardMove.toCell(
                      dragged,
                      col: blank.col,
                      row: blank.row,
                      cards: cards,
                      columns: columns,
                      rows: rows,
                    ),
                  ),
                  child: tile,
                );
              },
            );
          }

          Widget cardCell(BoardCard card) {
            final tile = _CardTile(
              card: card,
              order: card.placement.row * columns + card.placement.col,
              imageFile: imageOf(card),
              linked: card.content.linkBoardId != null,
              onTap: () => editing ? onEdit(card) : onUse(card),
              onMove: editing ? () => onMove(card) : null,
            );
            if (!editing) return tile;
            final rect = rectOf(card.placement);
            // Segurar ~0,5 s e arrastar; um toque curto continua abrindo o
            // editor. O "fantasma" que acompanha o dedo tem o tamanho do
            // card e fica fora da leitura de tela.
            final draggable = LongPressDraggable<int>(
              data: card.id,
              feedback: ExcludeSemantics(
                child: SizedBox(
                  width: rect.width,
                  height: rect.height,
                  child: Opacity(opacity: 0.9, child: tile),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: tile),
              child: tile,
            );
            return DragTarget<int>(
              // Soltar o card em cima dele mesmo não é um alvo.
              onWillAcceptWithDetails: (details) => details.data != card.id,
              onAcceptWithDetails: (details) =>
                  onDropOnCard(details.data, card),
              builder: (context, candidates, rejected) {
                return _DropHighlight(
                  kind: hoverKind(
                    candidates,
                    (dragged) => BoardMove.onto(
                      dragged,
                      card,
                      cards: cards,
                      columns: columns,
                      rows: rows,
                    ),
                  ),
                  child: draggable,
                );
              },
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              for (final blank in blanks)
                Positioned.fromRect(
                  key: BoardPage.blankCellKey(blank.col, blank.row),
                  rect: rectOf(blank),
                  child: blankCell(blank),
                ),
              for (final card in cards)
                Positioned.fromRect(
                  key: BoardPage.cardKey(card.id),
                  rect: rectOf(card.placement),
                  child: cardCell(card),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Contorno que mostra, DURANTE o arrasto, o que acontece se o card for solto
/// aqui: contorno grosso na cor do texto = vai mover ou trocar; na cor de erro
/// = "Não cabe aí". Sem nada passando por cima (ou soltando no mesmo lugar),
/// não desenha nada. Decorativo: não pega toque e fica fora da leitura.
class _DropHighlight extends StatelessWidget {
  const _DropHighlight({required this.kind, required this.child});

  final MoveKind? kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showing = kind == MoveKind.move ||
        kind == MoveKind.swap ||
        kind == MoveKind.blocked;
    final color = kind == MoveKind.blocked ? scheme.error : scheme.onSurface;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (showing)
          IgnorePointer(
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.order,
    required this.imageFile,
    required this.linked,
    required this.onTap,
    this.onMove,
  });

  final BoardCard card;

  /// Posição na ordem de leitura da grade (linha × colunas + coluna): é a
  /// ordem em que o leitor de tela percorre os cards.
  final int order;
  final File? imageFile;

  /// O card abre outra prancha: mostra um ícone de pasta (E5-4).
  final bool linked;

  /// Em uso: fala e adiciona à frase. Em edição: abre o editor.
  final VoidCallback onTap;

  /// Só em edição: ação "Mover…" para leitor de tela e Switch Access (a
  /// alternativa ao arrastar, ADR-042).
  final VoidCallback? onMove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = CardColors.resolve(
      wordClass: card.content.wordClass,
      legacyArgb: card.content.backgroundColor,
      themeBackground: scheme.surface,
      themeForeground: scheme.onSurface,
    );
    final background = palette.background;
    final foreground = palette.foreground;
    final label = card.content.label;
    final l10n = AppLocalizations.of(context);
    final wordClass = card.content.wordClass;
    final move = onMove;

    // Semantics (label + button) e o gesto do InkWell viram UM nó: o leitor
    // de tela lê o rótulo uma vez, sem repetir o conteúdo visual. A classe
    // gramatical entra como VALOR ("Água, Substantivo"): a cor sozinha não
    // diz nada a quem não enxerga (ADR-041).
    return Semantics(
      sortKey: OrdinalSortKey(order.toDouble()),
      button: true,
      label: label,
      value: wordClass == null ? null : wordClassName(l10n, wordClass),
      hint: linked ? l10n.cardOpensBoardHint : null,
      customSemanticsActions: move == null
          ? null
          : {CustomSemanticsAction(label: l10n.cardMove): move},
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: _CardContent(
              label: label,
              foreground: foreground,
              imageFile: imageFile,
              linked: linked,
            ),
          ),
        ),
      ),
    );
  }
}

/// Estilo do rótulo do card, já mesclado com o estilo padrão do Material (a
/// medição do `CardLabelFit` e o `Text` usam exatamente o mesmo estilo).
TextStyle _cardLabelStyle(BuildContext context, Color color) {
  final title = Theme.of(context).textTheme.titleMedium;
  return DefaultTextStyle.of(context).style.merge(
        title?.copyWith(color: color, fontWeight: FontWeight.w600),
      );
}

/// Miolo do card: imagem (se houver) e rótulo. O tamanho-base do rótulo vem
/// da célula (cresce no tablet) e o rótulo nunca fica sem espaço para duas
/// linhas no piso (ADR-041, decisão 2).
class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.label,
    required this.foreground,
    required this.imageFile,
    required this.linked,
  });

  final String label;
  final Color foreground;
  final File? imageFile;
  final bool linked;

  static const double _padding = 6;

  /// Com imagem, o rótulo ganha pelo menos esta fração da altura útil e no
  /// máximo [_labelMaxShare].
  static const double _labelMinShare = 0.4;
  static const double _labelMaxShare = 0.6;

  @override
  Widget build(BuildContext context) {
    final style = _cardLabelStyle(context, foreground);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final image = imageFile;

    return LayoutBuilder(
      builder: (context, box) {
        final baseSize = CardLabelFit.baseSizeFor(
          math.min(box.maxWidth, box.maxHeight),
        );
        final innerHeight = math.max(0.0, box.maxHeight - 2 * _padding);

        final Widget body;
        if (image == null) {
          body = _CardLabel(label: label, style: style, baseSize: baseSize);
        } else {
          final twoLines = CardLabelFit.twoLinesHeight(
            style: style,
            baseSize: baseSize,
            textScaler: scaler,
            textDirection: direction,
          );
          final labelHeight = math.max(
            innerHeight * _labelMinShare,
            math.min(twoLines, innerHeight * _labelMaxShare),
          );
          body = Column(
            children: [
              Expanded(child: _CardImage(file: image)),
              SizedBox(
                height: labelHeight,
                child: _CardLabel(
                  label: label,
                  style: style,
                  baseSize: baseSize,
                ),
              ),
            ],
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(padding: const EdgeInsets.all(_padding), child: body),
            if (linked)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.folder_outlined,
                  size: 22,
                  color: foreground,
                ),
              ),
          ],
        );
      },
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

/// Rótulo: acompanha a escala de fonte; encolhe só até o piso (75% do
/// tamanho-base), sem quebrar palavras antes disso; no piso quebra em até duas
/// linhas e termina com reticências (`CardLabelFit`).
class _CardLabel extends StatelessWidget {
  const _CardLabel({
    required this.label,
    required this.style,
    required this.baseSize,
  });

  final String label;
  final TextStyle style;
  final double baseSize;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = CardLabelFit.fitSize(
          label: label,
          style: style,
          textScaler: scaler,
          textDirection: direction,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          baseSize: baseSize,
        );
        return Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: CardLabelFit.maxLines,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(fontSize: size),
          ),
        );
      },
    );
  }
}

/// "+" de UMA posição em branco (só no modo de edição). O texto visível do
/// tooltip é o mesmo em todas ("Adicionar card"); para quem usa leitor de
/// tela, cada "+" diz a própria posição ("linha 2, coluna 3").
class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.placement,
    required this.order,
    required this.onPressed,
  });

  final CardPlacement placement;

  /// Posição na ordem de leitura da grade (ver [_CardTile.order]).
  final int order;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: l10n.cardAdd,
      excludeFromSemantics: true,
      child: Semantics(
        sortKey: OrdinalSortKey(order.toDouble()),
        button: true,
        label: l10n.cardAddAt(placement.row + 1, placement.col + 1),
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

/// Posição em branco no modo de USO: apagada, sem toque e fora da leitura de
/// tela (não há nada a dizer sobre um espaço vazio).
class _BlankCell extends StatelessWidget {
  const _BlankCell();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
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