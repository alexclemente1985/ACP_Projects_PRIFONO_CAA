import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/card_colors.dart';
import 'package:prifono_caa/features/boards/presentation/card_draft_controller.dart';
import 'package:prifono_caa/features/boards/presentation/card_label_rule.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_pick.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';
import 'package:prifono_caa/features/symbols/presentation/symbol_error_text.dart';
import 'package:prifono_caa/features/symbols/presentation/symbol_search_page.dart';

/// Editor de card em tela cheia (ADR-030). Com [initial], edita; sem, cria.
///
/// [onSave] e [onDelete] gravam de verdade (quem chama decide como). A tela
/// só fecha quando eles terminam sem erro; se falharem, ela continua aberta,
/// com tudo o que foi digitado, e avisa.
class CardEditorPage extends StatefulWidget {
  const CardEditorPage({
    required this.onSave,
    this.initial,
    this.onDelete,
    this.currentBoardId,
    super.key,
  });

  final CardContent? initial;

  /// Prancha onde o card está (ela não aparece como destino do link).
  final int? currentBoardId;
  final Future<void> Function(CardContent content) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<CardEditorPage> createState() => _CardEditorPageState();
}

class _CardEditorPageState extends State<CardEditorPage> {
  /// Largura (dp) a partir da qual o editor usa dois painéis (ADR-031).
  static const double _wideBreakpoint = 720;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final CardDraftController _draft = CardDraftController(
    images: AppScope.of(context).symbolImages,
    initial: widget.initial,
  );
  late final TextEditingController _label =
      TextEditingController(text: widget.initial?.label ?? '');
  late final TextEditingController _speech =
      TextEditingController(text: widget.initial?.speechText ?? '');
  bool _saving = false;

  /// Último rótulo preenchido por um pictograma (ver [labelAfterPick]).
  String? _autoLabel;

  @override
  void dispose() {
    _draft.dispose();
    _label.dispose();
    _speech.dispose();
    super.dispose();
  }

  Future<void> _pickSymbol() async {
    // Capturados ANTES do await.
    final navigator = Navigator.of(context);
    final provider = AppScope.of(context).symbols;
    final pick = await navigator.push<SymbolPick>(
      MaterialPageRoute<SymbolPick>(
        builder: (_) => SymbolSearchPage(provider: provider),
      ),
    );
    if (pick == null || !mounted) return;
    final label = labelAfterPick(
      current: _label.text,
      autoFilled: _autoLabel,
      pickLabel: pick.label,
    );
    if (label != _label.text) {
      _label.text = label;
      _autoLabel = label;
    }
    await _draft.selectSymbol(
      SymbolRef(source: SymbolRef.arasaac, id: pick.symbol.id),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_draft.canSave) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final content = _draft.buildContent(
      label: _label.text,
      speechText: _speech.text,
    );
    setState(() => _saving = true);
    try {
      await widget.onSave(content);
      if (!mounted) return;
      navigator.pop();
    } on BoardFullException catch (error) {
      _failed(messenger, l10n.boardFull(error.capacity));
    } on Exception {
      _failed(messenger, l10n.boardActionFailed);
    }
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _ConfirmDeleteCardDialog(label: widget.initial?.label ?? ''),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await onDelete();
      if (!mounted) return;
      navigator.pop();
    } on Exception {
      _failed(messenger, l10n.boardActionFailed);
    }
  }

  void _failed(ScaffoldMessengerState messenger, String message) {
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildFields(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _label,
          autofocus: widget.initial == null,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            labelText: l10n.cardLabelLabel,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.cardLabelRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _speech,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.cardSpeechLabel,
            helperText: l10n.cardSpeechHelper,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
          onFieldSubmitted: (_) => unawaited(_save()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.initial != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.cardEditorEditTitle : l10n.cardEditorNewTitle,
        ),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              tooltip: l10n.cardDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
          ListenableBuilder(
            listenable: _draft,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _draft.canSave && !_saving ? _save : null,
                child: Text(_saving ? l10n.cardSaving : l10n.commonSave),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _wideBreakpoint;
            final preview = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _CardPreview(draft: _draft, label: _label),
                ),
              ),
            );
            final symbol = _SymbolSection(draft: _draft, onChoose: _pickSymbol);
            final fields = _buildFields(l10n);
            final colors = _ColorSection(draft: _draft);
            final link = _LinkSection(
              draft: _draft,
              currentBoardId: widget.currentBoardId,
            );

            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Form(
                    key: _formKey,
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    preview,
                                    const SizedBox(height: 16),
                                    symbol,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    fields,
                                    const SizedBox(height: 24),
                                    colors,
                                    const SizedBox(height: 24),
                                    link,
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              preview,
                              const SizedBox(height: 16),
                              symbol,
                              const SizedBox(height: 24),
                              fields,
                              const SizedBox(height: 24),
                              colors,
                              const SizedBox(height: 24),
                              link,
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Escolha da prancha que o card abre ao ser tocado em modo de uso (E5-4).
/// Lista as OUTRAS pranchas; "Nenhuma" deixa o card só falar.
class _LinkSection extends StatefulWidget {
  const _LinkSection({required this.draft, required this.currentBoardId});

  final CardDraftController draft;
  final int? currentBoardId;

  @override
  State<_LinkSection> createState() => _LinkSectionState();
}

class _LinkSectionState extends State<_LinkSection> {
  late final Future<List<Board>> _boards =
      AppScope.of(context).boards.listBoards();

  Future<void> _choose(List<Board> boards) async {
    final l10n = AppLocalizations.of(context);
    final selected = widget.draft.linkBoardId;
    final choice = await showDialog<({int? id})>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.cardLinkTitle),
        children: [
          _LinkOption(
            label: l10n.cardLinkNone,
            selected: selected == null,
            onTap: () => Navigator.of(dialogContext).pop((id: null)),
          ),
          for (final board in boards)
            _LinkOption(
              label: board.name,
              selected: selected == board.id,
              onTap: () => Navigator.of(dialogContext).pop((id: board.id)),
            ),
        ],
      ),
    );
    if (choice == null) return; // fechou sem escolher
    widget.draft.setLinkBoardId(choice.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<List<Board>>(
      future: _boards,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final boards =
            data.where((b) => b.id != widget.currentBoardId).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.cardLinkTitle, style: textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            if (boards.isEmpty)
              Text(l10n.cardLinkEmpty, style: textTheme.bodyMedium)
            else
              ListenableBuilder(
                listenable: widget.draft,
                builder: (context, _) {
                  final selectedId = widget.draft.linkBoardId;
                  final match = boards.where((b) => b.id == selectedId);
                  final name =
                      match.isEmpty ? l10n.cardLinkNone : match.first.name;
                  return OutlinedButton(
                    onPressed: () => unawaited(_choose(boards)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _LinkOption extends StatelessWidget {
  const _LinkOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (selected) const Icon(Icons.check),
        ],
      ),
    );
  }
}

/// Prévia do card como vai aparecer na prancha (decorativa: os campos ao lado
/// já dizem tudo ao leitor de tela).
class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.draft, required this.label});

  final CardDraftController draft;
  final TextEditingController label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: ListenableBuilder(
        listenable: Listenable.merge([draft, label]),
        builder: (context, _) {
          final argb = draft.backgroundColor;
          final background =
              argb == null ? scheme.surface : CardColors.fromArgb(argb);
          final foreground = argb == null
              ? scheme.onSurface
              : CardColors.foregroundFor(background);
          final hasSymbol = draft.symbol != null;
          final style = Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              );

          return DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  if (hasSymbol)
                    Expanded(flex: 3, child: _PreviewImage(draft: draft)),
                  Expanded(
                    flex: hasSymbol ? 2 : 1,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label.text.trim(),
                          textAlign: TextAlign.center,
                          style: style,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.draft});

  final CardDraftController draft;

  @override
  Widget build(BuildContext context) {
    final file = draft.imageFile;
    final Widget child;
    switch (draft.symbolStatus) {
      case SymbolDownloadStatus.downloading:
        child = const Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        );
      case SymbolDownloadStatus.failed:
        child = const Center(
          child: Icon(Icons.cloud_off_outlined, color: BrandColors.tinta),
        );
      case SymbolDownloadStatus.none:
      case SymbolDownloadStatus.ready:
        child = file == null
            ? const SizedBox.shrink()
            : Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (context, _, _) => const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: BrandColors.tinta,
                  ),
                ),
              );
    }

    // Placa branca (ADR-029).
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.branco,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(4), child: child),
    );
  }
}

class _SymbolSection extends StatelessWidget {
  const _SymbolSection({required this.draft, required this.onChoose});

  final CardDraftController draft;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        final hasSymbol = draft.symbol != null;
        final status = draft.symbolStatus;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.cardSymbolSectionTitle,
                style: textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onChoose,
                  icon: const Icon(Icons.search),
                  label: Text(
                    hasSymbol ? l10n.cardSymbolChange : l10n.cardSymbolChoose,
                  ),
                ),
                if (hasSymbol)
                  TextButton.icon(
                    onPressed: draft.removeSymbol,
                    icon: const Icon(Icons.close),
                    label: Text(l10n.cardSymbolRemove),
                  ),
              ],
            ),
            if (status == SymbolDownloadStatus.downloading) ...[
              const SizedBox(height: 12),
              // liveRegion: o leitor de tela avisa quando o texto aparece.
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.cardSymbolDownloading,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (status == SymbolDownloadStatus.failed) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbolErrorText(l10n, draft.downloadError),
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.cardSymbolFailedHint,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonal(
                  onPressed: draft.retryDownload,
                  child: Text(l10n.searchRetry),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ColorSection extends StatelessWidget {
  const _ColorSection({required this.draft});

  final CardDraftController draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    // null = padrão do tema. Só as cores da marca: tons derivados ainda não
    // foram aprovados (ADR-007).
    final options = <(int?, String)>[
      (null, l10n.cardColorDefault),
      (BrandColors.rosa.toARGB32(), l10n.cardColorPink),
      (BrandColors.azul.toARGB32(), l10n.cardColorBlue),
      (BrandColors.bege.toARGB32(), l10n.cardColorBeige),
      (BrandColors.branco.toARGB32(), l10n.cardColorWhite),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.cardColorSectionTitle, style: textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: draft,
          builder: (context, _) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (argb, name) in options)
                  _ColorSwatch(
                    argb: argb,
                    name: name,
                    selected: draft.backgroundColor == argb,
                    onTap: () => draft.setBackgroundColor(argb),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.argb,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final int? argb;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = argb;
    final color = value == null ? scheme.surface : CardColors.fromArgb(value);
    final iconColor = CardColors.foregroundFor(color);

    return Tooltip(
      message: name,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: name,
        child: Material(
          color: color,
          clipBehavior: Clip.antiAlias,
          shape: CircleBorder(
            side: BorderSide(
              color: scheme.onSurface,
              width: selected ? 4 : 1.5,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: 56,
                child: Center(
                  child: selected
                      ? Icon(Icons.check, color: iconColor)
                      : (value == null
                          ? Icon(
                              Icons.format_color_reset_outlined,
                              color: iconColor,
                            )
                          : null),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmDeleteCardDialog extends StatelessWidget {
  const _ConfirmDeleteCardDialog({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.cardDeleteTitle),
      content: Text(l10n.cardDeleteMessage(label)),
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