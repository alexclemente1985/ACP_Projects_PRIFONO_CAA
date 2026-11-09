import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/boards/presentation/board_page.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_bar.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/splash/splash_page.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../support/unlock_edit_mode.dart';

// SEMÂNTICA PARA LEITOR DE TELA (E6-2, ADR-041).
//
// Confere o que TalkBack/VoiceOver recebem de cada tela: rótulo, valor, dica,
// grupo de escolha única, região viva e ações diretas. Complementa a auditoria
// (`accessibility_audit_test.dart`), que só mede alvo de toque, rótulo e
// contraste. Rode da RAIZ do projeto:
//
//   flutter test test/a11y/semantics_test.dart
//
// Convenção: `tester.getSemantics(find.text(...))` sobe da árvore de widgets
// até o nó de semântica que o contém, então serve mesmo quando o texto está
// dentro de um `ExcludeSemantics`.

const Size _phone = Size(390, 844);

Future<InMemoryBoardRepository> _seed([
  InMemoryBoardRepository? into,
]) async {
  final repository = into ?? InMemoryBoardRepository();
  final escola = await repository.createBoard(name: 'Escola');
  final casa = await repository.createBoard(
    name: 'Casa',
    gridColumns: 4,
    gridRows: 3,
  );
  await repository.addCard(
    casa.id,
    const CardContent(label: 'Água', wordClass: WordClass.noun),
  );
  await repository.addCard(casa.id, const CardContent(label: 'Sem classe'));
  await repository.addCard(
    casa.id,
    CardContent(label: 'Ir', linkBoardId: escola.id),
  );
  return repository;
}

Widget _buildApp(InMemoryBoardRepository boards) {
  // Rede, disco e banco falsos: os testes de widget nunca saem da máquina.
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('prifono_semantics_');
  addTearDown(() => root.deleteSync(recursive: true));
  return AppScope(
    settings: SettingsController(),
    boards: boards,
    symbols: provider,
    symbolImages: SymbolImageStore(root: root, provider: provider),
    child: const PrifonoApp(),
  );
}

/// Sobe o app, espera a splash e devolve na lista de pranchas.
Future<void> _pumpToBoards(
  WidgetTester tester, {
  bool tall = false,
  InMemoryBoardRepository? repository,
}) async {
  tester.view.physicalSize = tall ? const Size(390, 6000) : _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_buildApp(await _seed(repository)));
  await tester.pumpAndSettle();
}

/// Repositório cuja leitura dos cards fica PRESA até o teste soltar o
/// [gate]: deixa a prancha parada no estado "carregando" para o teste olhar.
class _SlowCardsRepository extends InMemoryBoardRepository {
  Completer<void>? gate;

  @override
  Future<List<BoardCard>> listCards(int boardId) async {
    final pending = gate;
    if (pending != null) await pending.future;
    return super.listCards(boardId);
  }
}

Future<void> _openBoard(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

/// O `SemanticsHandle` precisa ser liberado DENTRO do teste (o Flutter confere
/// isso antes de rodar os `addTearDown`).
Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

/// Liga "leitor de tela" para o app (`MediaQuery.accessibleNavigation`).
void _screenReaderOn(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(accessibleNavigation: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Ações de acessibilidade extras do nó (as "ações personalizadas" do menu do
/// leitor de tela), incluindo as dicas de toque e de toque longo.
List<CustomSemanticsAction> _actionsOf(SemanticsNode node) {
  final ids = node.getSemanticsData().customSemanticsActionIds ?? const <int>[];
  return [
    for (final id in ids) ?CustomSemanticsAction.getAction(id),
  ];
}

void main() {
  group('card da prancha', () {
    testWidgets('lê o rótulo e a classe gramatical como valor', (tester) async {
      await _pumpToBoards(tester);
      await _withSemantics(tester, () async {
        await _openBoard(tester, 'Casa');

        final noun = tester.getSemantics(find.text('Água'));
        expect(noun.label, 'Água');
        expect(noun.value, 'Substantivo');
        expect(noun, isSemantics(isButton: true, hasTapAction: true));

        // Sem classe, não há valor a ler.
        final plain = tester.getSemantics(find.text('Sem classe'));
        expect(plain.label, 'Sem classe');
        expect(plain.value, isEmpty);
      });
    });

    testWidgets('card com link avisa que abre outra prancha', (tester) async {
      await _pumpToBoards(tester);
      await _withSemantics(tester, () async {
        await _openBoard(tester, 'Casa');

        expect(tester.getSemantics(find.text('Ir')).hint, 'Abre outra prancha');
        expect(tester.getSemantics(find.text('Água')).hint, isEmpty);
      });
    });

    testWidgets('a mensagem de estado é região viva', (tester) async {
      await _pumpToBoards(tester);
      await _withSemantics(tester, () async {
        await _openBoard(tester, 'Casa');
        await unlockEditMode(tester);

        final message = tester.getSemantics(
          find.text('Modo de edição: toque num card para editar.'),
        );
        expect(message, isSemantics(isLiveRegion: true));
      });
    });

    testWidgets('o indicador de carregamento tem rótulo', (tester) async {
      final repository = _SlowCardsRepository();
      await _pumpToBoards(tester, repository: repository);

      // A partir daqui a leitura dos cards fica presa até soltarmos o gate.
      final gate = repository.gate = Completer<void>();
      await tester.tap(find.text('Casa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.semanticsLabel, 'Carregando');

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('cadeado', () {
    testWidgets('diz o que o toque e o toque longo fazem', (tester) async {
      await _pumpToBoards(tester);
      await _withSemantics(tester, () async {
        final lock = tester.getSemantics(find.byIcon(Icons.lock_outline));

        expect(lock, isSemantics(isButton: true));
        final actions = _actionsOf(lock);
        expect(
          actions.where(
            (a) =>
                a.action == SemanticsAction.longPress &&
                a.hint == 'destravar a edição',
          ),
          isNotEmpty,
          reason: 'toque longo sem dica',
        );
        expect(
          actions.where(
            (a) =>
                a.action == SemanticsAction.tap &&
                a.hint == 'ver como destravar',
          ),
          isNotEmpty,
          reason: 'toque sem dica',
        );
      });
    });

    testWidgets('com leitor de tela, anuncia entrar e sair da edição', (
      tester,
    ) async {
      _screenReaderOn(tester);
      await _pumpToBoards(tester);
      await _withSemantics(tester, () async {
        await unlockEditMode(tester);
        expect(find.text('Modo de edição ativado.'), findsOneWidget);

        await tester.tap(find.byTooltip('Sair do modo de edição'));
        await tester.pumpAndSettle();
        expect(find.text('Modo de edição desativado.'), findsOneWidget);
        expect(find.text('Modo de edição ativado.'), findsNothing);
      });
    });

    testWidgets('sem leitor de tela, não mostra o aviso', (tester) async {
      await _pumpToBoards(tester);
      await unlockEditMode(tester);

      expect(find.text('Modo de edição ativado.'), findsNothing);
    });
  });

  group('lista de pranchas', () {
    testWidgets('o menu de cada prancha leva o nome dela', (tester) async {
      await _pumpToBoards(tester);
      await unlockEditMode(tester);

      expect(find.byTooltip('Mais opções de Casa'), findsOneWidget);
      expect(find.byTooltip('Mais opções de Escola'), findsOneWidget);
    });
  });

  group('splash', () {
    testWidgets('é um nó só e tem a ação de pular', (tester) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_buildApp(await _seed()));
      await tester.pump(const Duration(milliseconds: 100));

      await _withSemantics(tester, () async {
        final node = tester.getSemantics(find.text('Privox'));
        expect(node.label, 'Privox');
        expect(node.hint, 'Toque para pular a abertura.');
        expect(node, isSemantics(isImage: true, hasTapAction: true));

        tester.semantics.tap(find.semantics.byLabel('Privox'));
        await tester.pumpAndSettle();
        expect(find.byType(SplashPage), findsNothing);
        expect(find.text('Casa'), findsOneWidget);
      });
    });
  });

  group('barra de frase', () {
    testWidgets('cada ficha oferece remover e mover para o leitor de tela', (
      tester,
    ) async {
      await _pumpToBoards(tester);
      await _withSemantics(tester, () async {
        await _openBoard(tester, 'Casa');
        final sentence = AppScope.of(tester.element(find.byType(BoardPage)))
            .sentence;
        sentence
          ..add(SentenceItem.fromContent(const CardContent(label: 'Primeiro')))
          ..add(SentenceItem.fromContent(const CardContent(label: 'Segundo')));
        await tester.pump();

        List<String> labelsOf(String word) => _actionsOf(
              tester.getSemantics(
                find.descendant(
                  of: find.byType(SentenceBar),
                  matching: find.text(word),
                ),
              ),
            ).map((a) => a.label).whereType<String>().toList();

        final first = labelsOf('Primeiro');
        expect(first, contains('Remover da frase'));
        expect(first, contains('Mover para a direita'));
        expect(first, isNot(contains('Mover para a esquerda')));

        final second = labelsOf('Segundo');
        expect(second, contains('Remover da frase'));
        expect(second, contains('Mover para a esquerda'));
        expect(second, isNot(contains('Mover para a direita')));
      });
    });
  });

  group('editor de card', () {
    Future<void> openEditor(WidgetTester tester) async {
      await _pumpToBoards(tester, tall: true);
      await _openBoard(tester, 'Casa');
      await unlockEditMode(tester);
      await tester.tap(find.text('Água'));
      await tester.pumpAndSettle();
    }

    testWidgets('as classes são um grupo de escolha única com "selecionado"', (
      tester,
    ) async {
      await openEditor(tester);
      await _withSemantics(tester, () async {
        final noun = tester.getSemantics(find.text('Substantivo'));
        expect(
          noun,
          isSemantics(
            isButton: true,
            isSelected: true,
            isInMutuallyExclusiveGroup: true,
          ),
        );

        final verb = tester.getSemantics(find.text('Verbo'));
        expect(
          verb,
          isSemantics(
            isButton: true,
            isSelected: false,
            isInMutuallyExclusiveGroup: true,
          ),
        );
      });
    });

    testWidgets('o botão do link lê o título e a escolha atual', (
      tester,
    ) async {
      await openEditor(tester);
      await _withSemantics(tester, () async {
        final button = tester.getSemantics(
          find.text('Nenhuma (o card só fala)'),
        );
        expect(button.label, 'Abrir outra prancha ao tocar');
        expect(button.value, 'Nenhuma (o card só fala)');
        expect(button, isSemantics(isButton: true, hasTapAction: true));
      });
    });

    testWidgets('as opções do link marcam a escolhida', (tester) async {
      await openEditor(tester);
      await _withSemantics(tester, () async {
        await tester.tap(find.text('Nenhuma (o card só fala)'));
        await tester.pumpAndSettle();

        final none = tester.getSemantics(
          find.descendant(
            of: find.byType(SimpleDialog),
            matching: find.text('Nenhuma (o card só fala)'),
          ),
        );
        expect(
          none,
          isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
        );

        final school = tester.getSemantics(
          find.descendant(
            of: find.byType(SimpleDialog),
            matching: find.text('Escola'),
          ),
        );
        expect(
          school,
          isSemantics(
            isSelected: false,
            isInMutuallyExclusiveGroup: true,
          ),
        );
      });
    });
  });
}