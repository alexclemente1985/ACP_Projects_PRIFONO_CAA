import 'package:flutter/material.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';

/// Tela da prancha. Na E4a mostra só a grade vazia no tamanho configurado;
/// os cards chegam na E4b.
class BoardPage extends StatelessWidget {
  const BoardPage({required this.board, super.key});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final border = Theme.of(context).colorScheme.outline;

    return Scaffold(
      appBar: AppBar(title: Text(board.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Antes da grade: um ListView só constrói o que está perto da
            // área visível, e a grade pode ocupar a tela inteira.
            Text(
              l10n.boardCardsComingSoon,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ExcludeSemantics(
              child: GridView.count(
                crossAxisCount: board.gridColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (var i = 0; i < board.gridColumns * board.gridRows; i++)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}