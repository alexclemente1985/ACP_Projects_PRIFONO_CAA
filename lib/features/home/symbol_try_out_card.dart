import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_pick.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';
import 'package:prifono_caa/features/symbols/presentation/symbol_search_page.dart';

/// Provisório: exercita o fluxo buscar -> escolher -> baixar -> exibir.
/// Será substituído pelo editor de cards na E4.
class SymbolTryOutCard extends StatefulWidget {
  const SymbolTryOutCard({super.key});

  @override
  State<SymbolTryOutCard> createState() => _SymbolTryOutCardState();
}

class _SymbolTryOutCardState extends State<SymbolTryOutCard> {
  SymbolPick? _pick;
  File? _file;
  bool _busy = false;

  Future<void> _choose() async {
    // Tudo o que depende do context é capturado ANTES do await.
    final scope = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final pick = await navigator.push<SymbolPick>(
      MaterialPageRoute(
        builder: (_) => SymbolSearchPage(provider: scope.symbols),
      ),
    );
    if (pick == null || !mounted) return;

    setState(() {
      _pick = pick;
      _file = null;
      _busy = true;
    });

    try {
      final file = await scope.symbolImages.ensure(
        SymbolRef(source: scope.symbols.sourceId, id: pick.symbol.id),
      );
      if (!mounted) return;
      setState(() {
        _file = file;
        _busy = false;
      });
    } on SymbolProviderException {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.tryOutDownloadFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final file = _file;
    final pick = _pick;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _busy ? null : _choose,
              child: Text(l10n.tryOutButton),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              Center(
                child: CircularProgressIndicator(
                  semanticsLabel: l10n.tryOutDownloading,
                ),
              ),
            ],
            if (file != null && pick != null) ...[
              const SizedBox(height: 16),
              Semantics(
                label: pick.label,
                image: true,
                excludeSemantics: true,
                child: Image.file(file, height: 160, fit: BoxFit.contain),
              ),
              const SizedBox(height: 8),
              Text(
                pick.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
