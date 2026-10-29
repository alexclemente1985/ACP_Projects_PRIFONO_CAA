import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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
class SentenceBar extends StatefulWidget {
  const SentenceBar({required this.controller, super.key});

  final SentenceController controller;

  @override
  State<SentenceBar> createState() => _SentenceBarState();
}

class _SentenceBarState extends State<SentenceBar> {
  static const double _wideBreakpoint = 720;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrollToEnd);
    // A barra pode nascer com a frase pronta (ao abrir outra prancha): já
    // começa mostrando a palavra mais recente.
    _scrollToEnd();
  }

  @override
  void didUpdateWidget(SentenceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_scrollToEnd);
      widget.controller.addListener(_scrollToEnd);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollToEnd);
    _scroll.dispose();
    super.dispose();
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

/// Faixa com as palavras (rola na horizontal) ou a dica, se estiver vazia.
class _SentenceStrip extends StatelessWidget {
  const _SentenceStrip({
    required this.controller,
    required this.scroll,
    required this.minHeight,
  });

  final SentenceController controller;
  final ScrollController scroll;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final items = controller.items;

    return Semantics(
      container: true,
      label: l10n.sentenceBarLabel,
      value: items.isEmpty ? l10n.sentenceHint : controller.text,
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline, width: 1.5),
          ),
          alignment: Alignment.centerLeft,
          child: items.isEmpty
              ? Text(
                  l10n.sentenceHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : SingleChildScrollView(
                  controller: scroll,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _SentenceChip(item: items[i]),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Uma palavra na barra: mesma cor do card e, se houver, o pictograma
/// sobre placa branca (ADR-029).
class _SentenceChip extends StatelessWidget {
  const _SentenceChip({required this.item});

  final SentenceItem item;

  static const double _imageSize = 36;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final argb = item.backgroundColor;
    final background =
        argb == null ? scheme.surface : CardColors.fromArgb(argb);
    final foreground = argb == null
        ? scheme.onSurface
        : CardColors.foregroundFor(background);
    final symbol = item.symbol;
    final File? file = symbol == null
        ? null
        : AppScope.of(context)
            .symbolImages
            .fileFor(symbol, size: SymbolImageSize.medium);

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline),
      ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}