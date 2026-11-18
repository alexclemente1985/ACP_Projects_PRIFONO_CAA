import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/card_size_rules.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

const String _widthMore = 'Aumentar a largura';
const String _widthLess = 'Diminuir a largura';
const String _heightMore = 'Aumentar a altura';
const String _heightLess = 'Diminuir a altura';

/// Monta uma tela com um botão "abrir" que empilha o editor.
Widget _buildHost({
  required CardGridSpace Function() gridSpace,
  required Future<void> Function(CardContent content, CardSize size) onSave,
  Future<void> Function()? onMove,
  CardContent? initial,
}) {
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('prifono_editor_size_');
  addTearDown(() => root.deleteSync(recursive: true));
  return AppScope(
    settings: SettingsController(),
    boards: InMemoryBoardRepository(),
    symbols: provider,
    symbolImages: SymbolImageStore(root: root, provider: provider),
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CardEditorPage(
                    initial: initial,
                    gridSpace: gridSpace,
                    onSave: onSave,
                    onMove: onMove,
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openEditor(
  WidgetTester tester, {
  required CardGridSpace Function() gridSpace,
  required Future<void> Function(CardContent content, CardSize size) onSave,
  Future<void> Function()? onMove,
  CardContent? initial,
}) async {
  await tester.pumpWidget(
    _buildHost(
      gridSpace: gridSpace,
      onSave: onSave,
      onMove: onMove,
      initial: initial,
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

/// Grade 4×3 com o card em ([origin]) e os [others] ao redor.
CardGridSpace _space({
  CardPlacement? origin,
  List<CardPlacement> others = const [],
}) {
  return CardGridSpace(
    columns: 4,
    rows: 3,
    origin: origin ?? _at(0, 0),
    others: others,
  );
}

/// O botão de passo que tem [tooltip] (para ver se está ligado ou desligado).
IconButton _stepper(WidgetTester tester, String tooltip) {
  return tester.widget<IconButton>(
    find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)),
  );
}

Future<void> _tapStepper(WidgetTester tester, String tooltip) async {
  await tester.ensureVisible(find.byTooltip(tooltip));
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

void main() {
  group('Tamanho do card no editor', () {
    testWidgets('card novo abre 1×1: só os "+" estão ligados', (tester) async {
      await _openEditor(
        tester,
        gridSpace: _space,
        onSave: (_, _) async {},
      );

      expect(find.text('Tamanho do card'), findsOneWidget);
      expect(find.text('Largura: 1 de 4'), findsOneWidget);
      expect(find.text('Altura: 1 de 3'), findsOneWidget);
      expect(_stepper(tester, _widthLess).onPressed, isNull);
      expect(_stepper(tester, _heightLess).onPressed, isNull);
      expect(_stepper(tester, _widthMore).onPressed, isNotNull);
      expect(_stepper(tester, _heightMore).onPressed, isNotNull);
    });

    testWidgets('"+" aumenta e a região viva diz o novo tamanho', (tester) async {
      await _openEditor(
        tester,
        gridSpace: _space,
        onSave: (_, _) async {},
      );

      await _tapStepper(tester, _widthMore);

      expect(find.text('Largura: 2 de 4'), findsOneWidget);
      expect(
        find.text('Tamanho: 2 × 1 posições (largura × altura).'),
        findsOneWidget,
      );
      expect(_stepper(tester, _widthLess).onPressed, isNotNull);
    });

    testWidgets('salvar entrega o tamanho escolhido junto do conteúdo', (
      tester,
    ) async {
      CardContent? savedContent;
      CardSize? savedSize;
      await _openEditor(
        tester,
        gridSpace: _space,
        onSave: (content, size) async {
          savedContent = content;
          savedSize = size;
        },
      );

      await tester.enterText(find.byType(TextFormField).first, 'Casa');
      await _tapStepper(tester, _widthMore);
      await _tapStepper(tester, _heightMore);
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(savedContent!.label, 'Casa');
      expect(savedSize, (colSpan: 2, rowSpan: 2));
      expect(find.byType(CardEditorPage), findsNothing);
    });

    testWidgets('card existente abre com o tamanho que já tem', (tester) async {
      CardSize? savedSize;
      await _openEditor(
        tester,
        initial: const CardContent(label: 'Brincar'),
        gridSpace: () => _space(origin: _at(0, 0, 3, 2)),
        onSave: (_, size) async {
          savedSize = size;
        },
      );

      expect(find.text('Largura: 3 de 4'), findsOneWidget);
      expect(find.text('Altura: 2 de 3'), findsOneWidget);

      // Salvar sem mexer devolve o mesmo tamanho (quem grava decide se mudou).
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(savedSize, (colSpan: 3, rowSpan: 2));
    });

    testWidgets('"+" fica desligado onde há outro card e diz o motivo', (
      tester,
    ) async {
      await _openEditor(
        tester,
        gridSpace: () => _space(others: [_at(1, 0)]),
        onSave: (_, _) async {},
      );

      expect(_stepper(tester, _widthMore).onPressed, isNull);
      expect(_stepper(tester, _heightMore).onPressed, isNotNull);
      expect(
        find.textContaining('Não há espaço para crescer à direita.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Não há espaço para crescer para baixo.'),
        findsNothing,
      );
    });

    testWidgets('"−" diminui até 1 e depois desliga', (tester) async {
      await _openEditor(
        tester,
        initial: const CardContent(label: 'Brincar'),
        gridSpace: () => _space(origin: _at(0, 0, 3)),
        onSave: (_, _) async {},
      );

      await _tapStepper(tester, _widthLess);
      await _tapStepper(tester, _widthLess);

      expect(find.text('Largura: 1 de 4'), findsOneWidget);
      expect(_stepper(tester, _widthLess).onPressed, isNull);
    });

    testWidgets('voltar sem salvar descarta o tamanho', (tester) async {
      var saves = 0;
      await _openEditor(
        tester,
        gridSpace: _space,
        onSave: (_, _) async => saves++,
      );

      await _tapStepper(tester, _widthMore);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(saves, 0);
      expect(find.byType(CardEditorPage), findsNothing);
    });

    testWidgets('tamanho que não cabe mais ao gravar: avisa e continua aberto', (
      tester,
    ) async {
      await _openEditor(
        tester,
        gridSpace: _space,
        onSave: (_, _) async {
          throw ArgumentError('cobre outro card da prancha');
        },
      );

      await tester.enterText(find.byType(TextFormField).first, 'Casa');
      await _tapStepper(tester, _widthMore);
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(
        find.text('O tamanho escolhido não cabe mais. Ajuste e salve de novo.'),
        findsOneWidget,
      );
      expect(find.byType(CardEditorPage), findsOneWidget);
      expect(find.text('Largura: 2 de 4'), findsOneWidget);
    });

    testWidgets('"Mover…" muda o espaço: tamanho que já não cabe volta ao salvo', (
      tester,
    ) async {
      var others = <CardPlacement>[];
      await _openEditor(
        tester,
        initial: const CardContent(label: 'Casa'),
        gridSpace: () => _space(others: others),
        onMove: () async {
          // O card foi para um lugar onde a posição à direita está ocupada.
          others = [_at(1, 0)];
        },
        onSave: (_, _) async {},
      );

      await _tapStepper(tester, _widthMore);
      expect(find.text('Largura: 2 de 4'), findsOneWidget);

      await tester.ensureVisible(find.text('Mover…'));
      await tester.tap(find.text('Mover…'));
      await tester.pumpAndSettle();

      expect(find.text('Largura: 1 de 4'), findsOneWidget);
      expect(_stepper(tester, _widthMore).onPressed, isNull);
    });
  });
}
