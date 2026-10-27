import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/about/credits_page.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_pick.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_result.dart';
import 'package:prifono_caa/features/symbols/presentation/symbol_search_controller.dart';

/// Tela de busca de pictogramas. Ao tocar num resultado, fecha devolvendo
/// um [SymbolPick].
class SymbolSearchPage extends StatefulWidget {
  const SymbolSearchPage({required this.provider, super.key});

  final SymbolProvider provider;

  @override
  State<SymbolSearchPage> createState() => _SymbolSearchPageState();
}

class _SymbolSearchPageState extends State<SymbolSearchPage> {
  late final SymbolSearchController _controller =
      SymbolSearchController(widget.provider);
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _clear() {
    _textController.clear();
    _controller.onQueryChanged('');
  }

  void _pick(SymbolResult result) {
    Navigator.of(context).pop(
      SymbolPick(
        symbol: result,
        label: result.suggestedLabel(_controller.query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _controller.onQueryChanged,
                onSubmitted: (text) => unawaited(_controller.search(text)),
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        tooltip: l10n.searchClear,
                        icon: const Icon(Icons.close),
                        onPressed: _clear,
                      );
                    },
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _SearchBody(
                  controller: _controller,
                  provider: widget.provider,
                  onPick: _pick,
                ),
              ),
            ),
            const _AttributionFooter(),
          ],
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.controller,
    required this.provider,
    required this.onPick,
  });

  final SymbolSearchController controller;
  final SymbolProvider provider;
  final ValueChanged<SymbolResult> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (controller.status) {
      case SymbolSearchStatus.idle:
        return _Message(text: l10n.searchIdleMessage);
      case SymbolSearchStatus.loading:
        return Center(
          child: CircularProgressIndicator(semanticsLabel: l10n.searchLoading),
        );
      case SymbolSearchStatus.empty:
        return _Message(text: l10n.searchEmptyMessage(controller.query));
      case SymbolSearchStatus.error:
        return _Message(
          text: _errorText(l10n, controller.error),
          action: FilledButton(
            onPressed: controller.retry,
            child: Text(l10n.searchRetry),
          ),
        );
      case SymbolSearchStatus.results:
        return _ResultsGrid(
          results: controller.results,
          provider: provider,
          onPick: onPick,
        );
    }
  }

  String _errorText(AppLocalizations l10n, SymbolErrorKind? kind) {
    switch (kind) {
      case SymbolErrorKind.offline:
        return l10n.searchErrorOffline;
      case SymbolErrorKind.timeout:
        return l10n.searchErrorTimeout;
      case SymbolErrorKind.server:
        return l10n.searchErrorServer;
      case SymbolErrorKind.badResponse:
      case null:
        return l10n.searchErrorGeneric;
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
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

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({
    required this.results,
    required this.provider,
    required this.onPick,
  });

  final List<SymbolResult> results;
  final SymbolProvider provider;
  final ValueChanged<SymbolResult> onPick;

  @override
  Widget build(BuildContext context) {
    // A altura do rótulo acompanha o tamanho de texto escolhido pelo usuário.
    final labelHeight = MediaQuery.textScalerOf(context).scale(14) * 1.4 * 2 + 12;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 100 + labelHeight,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _ResultCell(
          result: result,
          imageUrl: provider
              .imageUri(result.id, size: SymbolImageSize.small)
              .toString(),
          onTap: () => onPick(result),
        );
      },
    );
  }
}

class _ResultCell extends StatelessWidget {
  const _ResultCell({
    required this.result,
    required this.imageUrl,
    required this.onTap,
  });

  final SymbolResult result;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: result.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    cacheWidth: 300,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        semanticLabel: l10n.imageUnavailable,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: Text(
                  result.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Atribuição sempre visível (exigência de licença) com atalho para Créditos.
class _AttributionFooter extends StatelessWidget {
  const _AttributionFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CreditsPage()),
        ),
        child: Text(l10n.attributionShort, textAlign: TextAlign.center),
      ),
    );
  }
}
