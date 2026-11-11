import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/theme/app_theme.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

/// Monta uma tela com um botão "abrir" que empilha o editor (assim o
/// Navigator.pop do editor tem para onde voltar).
Widget _buildHost({
  required Future<void> Function(CardContent content) onSave,
  Future<void> Function()? onDelete,
  CardContent? initial,
}) {
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('prifono_editor_');
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
                    onSave: onSave,
                    onDelete: onDelete,
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
  required Future<void> Function(CardContent content) onSave,
  Future<void> Function()? onDelete,
  CardContent? initial,
}) async {
  await tester.pumpWidget(
    _buildHost(onSave: onSave, onDelete: onDelete, initial: initial),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

/// Nomes das fichas de classe, na ordem da tela: "Nenhuma" + as dez classes.
const List<String> _classChipNames = [
  'Nenhuma',
  'Pronome',
  'Verbo',
  'Substantivo',
  'Adjetivo',
  'Preposição ou palavra social',
  'Pergunta',
  'Negação ou urgência',
  'Advérbio',
  'Conjunção',
  'Determinante',
];

/// Espessura da borda da ficha [name]. A ficha é um `Material` com
/// `RoundedRectangleBorder`; o `Material` mais próximo do texto é o dela (o
/// `find.ancestor` devolve do pai para cima, então o `.first` é o mais perto).
double _borderOf(WidgetTester tester, String name) {
  final material = tester.widget<Material>(
    find.ancestor(of: find.text(name), matching: find.byType(Material)).first,
  );
  return (material.shape! as RoundedRectangleBorder).side.width;
}

/// Nomes das fichas hoje marcadas: as de borda grossa (ADR-041, E6-4.2).
List<String> _selectedChips(WidgetTester tester) => [
  for (final name in _classChipNames)
    if (_borderOf(tester, name) == kChipSelectedBorderWidth) name,
];

void main() {
  group('CardEditorPage', () {
    testWidgets('texto vazio mostra o erro e não salva', (tester) async {
      var saves = 0;
      await _openEditor(tester, onSave: (_) async => saves++);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Escreva o texto do card.'), findsOneWidget);
      expect(saves, 0);
      expect(find.byType(CardEditorPage), findsOneWidget);
    });

    testWidgets('salvar entrega o conteúdo normalizado e fecha', (tester) async {
      CardContent? saved;
      await _openEditor(
        tester,
        onSave: (content) async {
          saved = content;
        },
      );

      await tester.enterText(find.byType(TextFormField).first, '  Água  ');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.label, 'Água');
      expect(saved!.speechText, isNull);
      expect(saved!.symbol, isNull);
      expect(find.byType(CardEditorPage), findsNothing);
    });

    testWidgets('a classe escolhida vai no conteúdo salvo, sem cor livre', (
      tester,
    ) async {
      CardContent? saved;
      await _openEditor(
        tester,
        onSave: (content) async {
          saved = content;
        },
      );

      await tester.enterText(find.byType(TextFormField).first, 'Comer');
      await tester.ensureVisible(find.text('Verbo'));
      await tester.tap(find.text('Verbo'));
      await tester.pump();
      expect(_selectedChips(tester), ['Verbo']);
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(saved!.wordClass, WordClass.verb);
      expect(saved!.backgroundColor, isNull);
    });

    testWidgets('mostra as dez classes e "Nenhuma", cada uma com o nome', (
      tester,
    ) async {
      await _openEditor(tester, onSave: (_) async {});

      for (final name in _classChipNames) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // Card novo: só "Nenhuma" está marcada (borda grossa), as outras têm a
      // borda normal e a tela não tem nenhum visto (E6-4.2).
      expect(_selectedChips(tester), ['Nenhuma']);
      expect(_borderOf(tester, 'Nenhuma'), kChipSelectedBorderWidth);
      expect(_borderOf(tester, 'Verbo'), kChipBorderWidth);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('card com classe abre com ela marcada e mantém ao salvar', (
      tester,
    ) async {
      CardContent? saved;
      await _openEditor(
        tester,
        initial: const CardContent(label: 'Quem', wordClass: WordClass.question),
        onSave: (content) async {
          saved = content;
        },
      );

      // A marcada é a ficha "Pergunta" (borda grossa); nenhuma outra, e sem visto.
      expect(_selectedChips(tester), ['Pergunta']);
      expect(find.byIcon(Icons.check), findsNothing);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(saved!.wordClass, WordClass.question);
    });

    testWidgets('card antigo com cor livre: escolher "Nenhuma" descarta a cor', (
      tester,
    ) async {
      CardContent? saved;
      await _openEditor(
        tester,
        initial: const CardContent(label: 'Sim', backgroundColor: 0xFFFBB7C4),
        onSave: (content) async {
          saved = content;
        },
      );
      // Cor livre antiga: nenhuma ficha marcada ainda.
        expect(_selectedChips(tester), isEmpty);

      await tester.ensureVisible(find.text('Nenhuma'));
      await tester.tap(find.text('Nenhuma'));
      await tester.pump();
        expect(_selectedChips(tester), ['Nenhuma']);
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(saved!.backgroundColor, isNull);
      expect(saved!.wordClass, isNull);
    });

    testWidgets('falha ao salvar mantém a tela, o texto e avisa', (tester) async {
      await _openEditor(
        tester,
        onSave: (_) async {
          throw Exception('disco cheio');
        },
      );

      await tester.enterText(find.byType(TextFormField).first, 'Sim');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível concluir a ação. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.byType(CardEditorPage), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Sim'), findsOneWidget);
    });

    testWidgets('card novo não tem o botão de excluir', (tester) async {
      await _openEditor(tester, onSave: (_) async {});

      expect(find.byTooltip('Excluir card'), findsNothing);
    });

    testWidgets('excluir pede confirmação e só então exclui', (tester) async {
      var deletes = 0;
      await _openEditor(
        tester,
        initial: const CardContent(label: 'Água'),
        onSave: (_) async {},
        onDelete: () async {
          deletes++;
        },
      );
      expect(find.widgetWithText(TextFormField, 'Água'), findsOneWidget);

      await tester.tap(find.byTooltip('Excluir card'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir card?'), findsOneWidget);
      expect(deletes, 0);

      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(deletes, 1);
      expect(find.byType(CardEditorPage), findsNothing);
    });

    testWidgets('tablet 1280x800: dois painéis, sem estourar o layout', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _openEditor(tester, onSave: (_) async {});

      expect(tester.takeException(), isNull);
      expect(find.text('Classe gramatical'), findsOneWidget);
      final symbolButton = tester.getTopLeft(find.text('Escolher pictograma'));
      final labelField = tester.getTopLeft(find.byType(TextFormField).first);
      expect(symbolButton.dx, lessThan(labelField.dx)); // lado a lado
    });

    testWidgets('telefone com texto em 200%: uma coluna, sem estourar', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _openEditor(
        tester,
        initial: const CardContent(
          label: 'Quero beber água agora',
          backgroundColor: 0xFF122A30,
        ),
        onSave: (_) async {},
        onDelete: () async {},
      );

      expect(tester.takeException(), isNull);
      final symbolButton = tester.getTopLeft(find.text('Trocar pictograma').evaluate().isEmpty
          ? find.text('Escolher pictograma')
          : find.text('Trocar pictograma'));
      final labelField = tester.getTopLeft(find.byType(TextFormField).first);
      expect(symbolButton.dy, lessThan(labelField.dy)); // empilhado
    });
  });
}
