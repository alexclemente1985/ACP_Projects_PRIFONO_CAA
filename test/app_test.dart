import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_repository.dart';
import 'package:prifono_caa/features/boards/presentation/board_page.dart';
import 'package:prifono_caa/features/boards/presentation/boards_list_page.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/splash/splash_page.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

Widget _buildApp({SettingsController? settings, BoardRepository? boards}) {
  // Rede, disco e banco falsos: os testes de widget nunca saem da máquina.
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('prifono_symbols_');
  addTearDown(() => root.deleteSync(recursive: true));
  return AppScope(
    settings: settings ?? SettingsController(),
    boards: boards ?? InMemoryBoardRepository(),
    symbols: provider,
    symbolImages: SymbolImageStore(root: root, provider: provider),
    child: const PrifonoApp(),
  );
}

/// Sobe o app e espera a splash terminar.
Future<void> _pumpToBoards(
  WidgetTester tester, {
  SettingsController? settings,
  BoardRepository? boards,
}) async {
  await tester.pumpWidget(_buildApp(settings: settings, boards: boards));
  await tester.pumpAndSettle();
}

void main() {
  group('splash', () {
    testWidgets('começa na splash e termina na lista de pranchas', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(SplashPage), findsNothing);
      expect(find.byType(BoardsListPage), findsOneWidget);
    });

    testWidgets('tocar na tela pula a splash', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(SplashPage));
      await tester.pumpAndSettle();

      expect(find.byType(BoardsListPage), findsOneWidget);
    });

    testWidgets('com "reduzir movimento" a splash é curta', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 850)); // > 800 ms
      await tester.pump(const Duration(milliseconds: 500)); // transição

      expect(find.byType(BoardsListPage), findsOneWidget);
    });
  });

  group('pranchas', () {
    testWidgets('sem pranchas mostra o estado vazio', (tester) async {
      await _pumpToBoards(tester);

      expect(find.text('Nenhuma prancha ainda'), findsOneWidget);
      expect(find.text('Criar primeira prancha'), findsOneWidget);
    });

    testWidgets('cria uma prancha com nome e grade', (tester) async {
      await _pumpToBoards(tester);

      await tester.tap(find.text('Nova prancha'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Casa');
      await tester.tap(find.byTooltip('Aumentar colunas'));
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('5 colunas × 4 linhas'), findsOneWidget);
    });

    testWidgets('nome vazio mostra erro e mantém o formulário aberto', (
      tester,
    ) async {
      await _pumpToBoards(tester);

      await tester.tap(find.text('Nova prancha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Dê um nome à prancha.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('edita o nome de uma prancha', (tester) async {
      final repository = InMemoryBoardRepository();
      await repository.createBoard(name: 'Casa');
      await _pumpToBoards(tester, boards: repository);

      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Casa'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Casa nova');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Casa nova'), findsOneWidget);
    });

    testWidgets('excluir pede confirmação e remove a prancha', (tester) async {
      final repository = InMemoryBoardRepository();
      await repository.createBoard(name: 'Casa');
      await _pumpToBoards(tester, boards: repository);

      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir prancha?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Casa'), findsNothing);
      expect(find.text('Nenhuma prancha ainda'), findsOneWidget);
    });

    testWidgets('cancelar a exclusão mantém a prancha', (tester) async {
      final repository = InMemoryBoardRepository();
      await repository.createBoard(name: 'Casa');
      await _pumpToBoards(tester, boards: repository);

      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Casa'), findsOneWidget);
    });

    testWidgets('tocar numa prancha abre a tela da prancha', (tester) async {
      final repository = InMemoryBoardRepository();
      await repository.createBoard(name: 'Casa');
      await _pumpToBoards(tester, boards: repository);

      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();

      expect(find.byType(BoardPage), findsOneWidget);
      expect(
        find.text('Toque no + para adicionar o primeiro card.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Adicionar card'), findsOneWidget);
    });

    testWidgets('não deixa reduzir a grade abaixo da quantidade de cards', (
      tester,
    ) async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 2,
        gridRows: 2,
      );
      for (final label in ['A', 'B', 'C', 'D']) {
        await repository.addCard(board.id, CardContent(label: label));
      }
      await _pumpToBoards(tester, boards: repository);

      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      final decreaseColumns = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove).first,
      );
      expect(decreaseColumns.onPressed, isNull);
      expect(find.textContaining('Esta prancha tem 4 cards'), findsOneWidget);
    });

    testWidgets('permite reduzir até o limite dos cards e salva', (
      tester,
    ) async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 3,
        gridRows: 2,
      );
      for (final label in ['A', 'B', 'C', 'D']) {
        await repository.addCard(board.id, CardContent(label: label));
      }
      await _pumpToBoards(tester, boards: repository);

      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      // 3 → 2 colunas dá 2 × 2 = 4 células: ainda cabe. O passo seguinte não.
      await tester.tap(find.byTooltip('Diminuir colunas'));
      await tester.pump();
      final decreaseColumns = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove).first,
      );
      expect(decreaseColumns.onPressed, isNull);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('2 colunas × 2 linhas'), findsOneWidget);
    });
  });

  group('cards na prancha', () {
    testWidgets('mostra os cards em ordem de leitura e um único "+"', (
      tester,
    ) async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 3,
        gridRows: 2,
      );
      await repository.addCard(board.id, const CardContent(label: 'Água'));
      await repository.addCard(board.id, const CardContent(label: 'Comer'));
      await _pumpToBoards(tester, boards: repository);

      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();

      expect(find.text('Água'), findsOneWidget);
      expect(find.text('Comer'), findsOneWidget);
      expect(find.byTooltip('Adicionar card'), findsOneWidget);
      final agua = tester.getTopLeft(find.text('Água'));
      final comer = tester.getTopLeft(find.text('Comer'));
      expect(agua.dx, lessThan(comer.dx));
      expect(agua.dy, closeTo(comer.dy, 1));
    });

    testWidgets('prancha cheia não mostra "+" e avisa', (tester) async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 2,
        gridRows: 1,
      );
      await repository.addCard(board.id, const CardContent(label: 'Sim'));
      await repository.addCard(board.id, const CardContent(label: 'Não'));
      await _pumpToBoards(tester, boards: repository);

      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Adicionar card'), findsNothing);
      expect(find.textContaining('Prancha cheia'), findsOneWidget);
    });

    testWidgets('cards com imagem e cor não estouram o layout em 200%', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(name: 'Casa');
      await repository.addCard(
        board.id,
        const CardContent(
          label: 'Quero beber água agora',
          symbol: SymbolRef(source: SymbolRef.arasaac, id: '2265'),
          backgroundColor: 0xFFFBB7C4,
        ),
      );
      await repository.addCard(
        board.id,
        const CardContent(label: 'Sim', backgroundColor: 0xFF122A30),
      );
      await _pumpToBoards(tester, boards: repository);

      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sim'), findsOneWidget);
    });

    testWidgets('cria um card pelo + e ele aparece na grade', (tester) async {
      final repository = InMemoryBoardRepository();
      await repository.createBoard(name: 'Casa');
      await _pumpToBoards(tester, boards: repository);
      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Adicionar card'));
      await tester.pumpAndSettle();
      expect(find.text('Novo card'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Água');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorPage), findsNothing);
      expect(find.text('Água'), findsOneWidget);
    });

    testWidgets('tocar num card abre o editor e permite excluir', (
      tester,
    ) async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(name: 'Casa');
      await repository.addCard(board.id, const CardContent(label: 'Água'));
      await _pumpToBoards(tester, boards: repository);
      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Água'));
      await tester.pumpAndSettle();
      expect(find.text('Editar card'), findsOneWidget);

      await tester.tap(find.byTooltip('Excluir card'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorPage), findsNothing);
      expect(find.text('Água'), findsNothing);
      expect(
        find.text('Toque no + para adicionar o primeiro card.'),
        findsOneWidget,
      );
    });
  });

  group('ajustes', () {
    testWidgets('escolher "Escuro" muda o themeMode do app', (tester) async {
      final settings = SettingsController();
      await _pumpToBoards(tester, settings: settings);

      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.dark);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });
  });

  testWidgets('não estoura layout com texto em 200%', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = InMemoryBoardRepository();
    await repository.createBoard(name: 'Prancha com um nome bem comprido');

    await tester.pumpWidget(_buildApp(boards: repository));
    expect(tester.takeException(), isNull); // splash em 200%

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // lista em 200%

    await tester.tap(find.text('Nova prancha'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // formulário em 200%
  });

  testWidgets('abre a tela Sobre e créditos', (tester) async {
    await _pumpToBoards(tester);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(find.text('Quem faz o Privox'), findsOneWidget);
  });
}
