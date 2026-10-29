import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_bar.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

Future<void> _pumpBoard(WidgetTester tester) async {
  final repository = InMemoryBoardRepository();
  final board = await repository.createBoard(name: 'Casa');
  for (final card in const [
    CardContent(label: 'Comer', wordClass: WordClass.verb),
    CardContent(label: 'Mesa', wordClass: WordClass.noun),
    CardContent(label: 'Sim', backgroundColor: 0xFFFBB7C4), // cor livre antiga
    CardContent(label: 'Livro'),
  ]) {
    await repository.addCard(board.id, card);
  }
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_class_colors_');
  addTearDown(() => root.deleteSync(recursive: true));

  await tester.pumpWidget(
    AppScope(
      settings: SettingsController(),
      boards: repository,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Casa'));
  await tester.pumpAndSettle();
}

/// Material do card (o ancestral mais próximo do texto).
Material _tile(WidgetTester tester, String label) {
  return tester.widget<Material>(
    find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
  );
}

Color? _labelColor(WidgetTester tester, String label) {
  return tester.widget<Text>(find.text(label)).style?.color;
}

void main() {
  group('cores dos cards pela classe (E5-4b)', () {
    testWidgets('o card pinta com a cor da classe e o texto em tinta', (
      tester,
    ) async {
      await _pumpBoard(tester);

      expect(_tile(tester, 'Comer').color, const Color(0xFF7ED68B));
      expect(_tile(tester, 'Mesa').color, const Color(0xFFFFAE57));
      expect(_labelColor(tester, 'Comer'), BrandColors.tinta);
    });

    testWidgets('card antigo mantém a cor livre; sem nada usa o tema', (
      tester,
    ) async {
      await _pumpBoard(tester);

      expect(_tile(tester, 'Sim').color, const Color(0xFFFBB7C4));
      expect(
        _tile(tester, 'Livro').color,
        Theme.of(tester.element(find.text('Livro'))).colorScheme.surface,
      );
    });

    testWidgets('a ficha na barra de frase usa a mesma cor da classe', (
      tester,
    ) async {
      await _pumpBoard(tester);

      await tester.tap(find.text('Comer'));
      await tester.pumpAndSettle();

      final chip = find.descendant(
        of: find.byType(SentenceBar),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == const Color(0xFF7ED68B);
        }),
      );
      expect(chip, findsOneWidget);
    });
  });
}
