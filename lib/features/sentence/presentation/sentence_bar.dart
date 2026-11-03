import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/features/boards/presentation/card_colors.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_controller.dart';
import 'package:prifono_caa/features/speech/presentation/speak_with_feedback.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';

/// Barra de frase: mostra as palavras tocadas e tem os botões Falar, Apagar
/// (última palavra) e Limpar (tudo).
///
/// As fichas podem ser reorganizadas (segurar e arrastar) e removidas de
/// qualquer posição (tocar na ficha abre um menu), ADR-039.
class SentenceBar extends StatefulWidget {
  const SentenceBar({required this.controller, super.key});

  final SentenceController controller;

  @override
  State<SentenceBar> createState() => _SentenceBarState();
}

class _SentenceBarState extends State<SentenceBar> {
  static const double _wideBreakpoint = 720;

  final ScrollController _scroll = ScrollController();
  late int _knownLength = widget.controller.length;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSentenceChanged);
    // A barra pode nascer com a frase pronta (ao abrir outra prancha): já
    // começa mostrando a palavra mais recente.
    _scrollToEnd();
  }

  @override
  void didUpdateWidget(SentenceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onSentenceChanged);
      widget.controller.addListener(_onSentenceChanged);
      _knownLength = widget.controller.length;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSentenceChanged);
    _scroll.dispose();
    super.dispose();
  }

  /// Só vai para o fim quando uma palavra ENTRA. Ao remover ou reorganizar, a
  /// barra fica onde a pessoa estava olhando.
  void _onSentenceChanged() {
    final length = widget.controller.length;
    final grew = length > _knownLength;
    _knownLength = length;
    if (grew) _scrollToEnd();
  }

  /// Depois de montar o quadro, mostra sempre a palavra mais recente.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    final buttonSize =
        MediaQuery.sizeOf(context).width >= _wideBreakpoint ? 56.0 : 48.0;
    // Altura das fichas: cabe uma linha do texto ampliado (a lista de fichas
    // precisa de altura definida) e nunca fica menor que o alvo de toque.
    final chipHeight = math.max(
      buttonSize,
      MediaQuery.textScalerOf(context).scale(24) + 12,
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final empty = controller.isEmpty;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _SentenceStrip(
                controller: controller,
                scroll: _scroll,
                minHeight: buttonSize + 8,
                chipHeight: chipHeight,
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              tooltip: l10n.sentenceSpeak,
              icon: const Icon(Icons.volume_up),
              iconSize: 28,
              style: IconButton.styleFrom(fixedSize: Size.square(buttonSize)),
              onPressed: controller.canSpeak
                  ? () => unawaited(speakWithFeedback(context, controller.text))
                  : null,
            ),
            IconButton.outlined(
              tooltip: l10n.sentenceDeleteLast,
              icon: const Icon(Icons.backspace_outlined),
              iconSize: 26,
              style: IconButton.styleFrom(fixedSize: Size.square(buttonSize)),
              onPressed: empty ? null : controller.removeLast,
            ),
            IconButton.outlined(
              tooltip: l10n.sentenceClear,
              icon: const Icon(Icons.clear_all),
              iconSize: 28,
              style: IconButton.styleFrom(fixedSize: Size.square(buttonSize)),
              onPressed: empty ? null : controller.clear,
            ),
          ],
        );
      },
    );
  }
}

/// Faixa com as palavras (rola na horizontal; segurar uma ficha e arrastar a
/// reorganiza) ou a dica, se estiver vazia.
class _SentenceStrip extends StatelessWidget {
  const _SentenceStrip({
    required this.controller,
    required this.scroll,
    required this.minHeight,
    required this.chipHeight,
  });

  final SentenceController controller;
  final ScrollController scroll;
  final double minHeight;
  final double chipHeight;

  /// Fichas até este alcance (dp) já nascem montadas: a lista sabe o tamanho
  /// total e "ir para o fim" cai exatamente na última palavra.
  static const double _cacheExtent = 4000;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final entries = controller.entries;

    return Semantics(
      container: true,
      label: l10n.sentenceBarLabel,
      value: entries.isEmpty ? l10n.sentenceHint : controller.text,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline, width: 1.5),
        ),
        alignment: Alignment.centerLeft,
        child: entries.isEmpty
            ? ExcludeSemantics(
                child: Text(
                  l10n.sentenceHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            : SizedBox(
                height: chipHeight,
                child: ReorderableListView.builder(
                  scrollController: scroll,
                  scrollDirection: Axis.horizontal,
                  // Sem alças: o arraste começa segurando a própria ficha.
                  buildDefaultDragHandles: false,
                  scrollCacheExtent: const ScrollCacheExtent.pixels(_cacheExtent),
                  itemCount: entries.length,
                  // `onReorderItem` já entrega a posição FINAL do item.
                  onReorderItem: controller.move,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey<int>(entry.id),
                      index: index,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: index == entries.length - 1 ? 0 : 6,
                          ),
                          child: _SentenceChip(
                            item: entry.item,
                            onTap: () => unawaited(
                              _showChipOptions(context, controller, index),
                            ),
                            onRemove: () => controller.removeAt(index),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// O que se pode fazer com uma ficha da frase.
enum _ChipAction { remove, moveLeft, moveRight }

/// Mini-menu da ficha: remover e mover um passo. Os "mover" são a alternativa
/// ao arrastar para quem não consegue segurar e arrastar (ADR-039).
Future<void> _showChipOptions(
  BuildContext context,
  SentenceController controller,
  int index,
) async {
  final l10n = AppLocalizations.of(context);
  final entries = controller.entries;
  if (index < 0 || index >= entries.length) return;
  final item = entries[index].item;
  final last = entries.length - 1;

  final action = await showDialog<_ChipAction>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(
        item.label.isEmpty ? l10n.sentenceChipUntitled : item.label,
      ),
      children: [
        _ChipOption(
          icon: Icons.delete_outline,
          label: l10n.sentenceRemoveWord,
          onTap: () => Navigator.of(dialogContext).pop(_ChipAction.remove),
        ),
        if (index > 0)
          _ChipOption(
            icon: Icons.arrow_back,
            label: l10n.sentenceMoveLeft,
            onTap: () => Navigator.of(dialogContext).pop(_ChipAction.moveLeft),
          ),
        if (index < last)
          _ChipOption(
            icon: Icons.arrow_forward,
            label: l10n.sentenceMoveRight,
            onTap: () =>
                Navigator.of(dialogContext).pop(_ChipAction.moveRight),
          ),
      ],
    ),
  );

  switch (action) {
    case null:
      return;
    case _ChipAction.remove:
      controller.removeAt(index);
    case _ChipAction.moveLeft:
      controller.move(index, index - 1);
    case _ChipAction.moveRight:
      controller.move(index, index + 1);
  }
}

class _ChipOption extends StatelessWidget {
  const _ChipOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

/// Uma palavra na barra: mesma cor do card (classe gramatical, ADR-038) e, se
/// houver, o pictograma sobre placa branca (ADR-029). Tocar abre o menu.
class _SentenceChip extends StatelessWidget {
  const _SentenceChip({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  final SentenceItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  static const double _imageSize = 36;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final palette = CardColors.resolve(
      wordClass: item.wordClass,
      legacyArgb: item.backgroundColor,
      themeBackground: scheme.surface,
      themeForeground: scheme.onSurface,
    );
    final background = palette.background;
    final foreground = palette.foreground;
    final symbol = item.symbol;
    final File? file = symbol == null
        ? null
        : AppScope.of(context)
            .symbolImages
            .fileFor(symbol, size: SymbolImageSize.medium);

    // Semantics (rótulo + botão) e o gesto do InkWell viram UM nó, como no
    // card da prancha. "Remover" também é uma ação de acessibilidade direta.
    return Semantics(
      button: true,
      label: item.label.isEmpty ? l10n.sentenceChipUntitled : item.label,
      hint: l10n.sentenceChipHint,
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.sentenceRemoveWord): onRemove,
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
          maxWidth: 180,
        ),
        child: Material(
          color: background,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: scheme.outline),
          ),
          child: InkWell(
            onTap: onTap,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Center(
                  widthFactor: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (file != null) ...[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: BrandColors.branco,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Image.file(
                              file,
                              width: _imageSize,
                              height: _imageSize,
                              cacheWidth: 96,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                              errorBuilder: (context, _, _) =>
                                  const SizedBox.square(dimension: _imageSize),
                            ),
                          ),
                        ),
                        if (item.label.isNotEmpty) const SizedBox(width: 6),
                      ],
                      if (item.label.isNotEmpty)
                        Flexible(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: foreground,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}