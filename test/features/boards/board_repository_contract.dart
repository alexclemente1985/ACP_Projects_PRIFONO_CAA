import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/core/errors/not_found_exception.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_repository.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

/// Cria um repositório limpo que usa o relógio [now] informado.
typedef RepositoryFactory = Future<BoardRepository> Function(
  DateTime Function() now,
);

/// Testes de CONTRATO: qualquer implementação de [BoardRepository] precisa
/// passar em todos eles. Assim garantimos que a versão em memória (usada em
/// testes de widget) se comporta como a versão SQLite.
void runBoardRepositoryContract(RepositoryFactory create) {
  late BoardRepository repository;
  var now = DateTime.utc(2026, 10, 26, 12);

  setUp(() async {
    now = DateTime.utc(2026, 10, 26, 12);
    repository = await create(() => now);
  });

  group('pranchas', () {
    test('cria com posição sequencial e grade padrão', () async {
      final a = await repository.createBoard(name: '  Casa  ');
      final b = await repository.createBoard(
        name: 'Escola',
        gridColumns: 3,
        gridRows: 5,
      );

      expect(a.name, 'Casa'); // espaços removidos
      expect(a.gridColumns, Board.defaultColumns);
      expect(a.position, 0);
      expect(b.position, 1);
      expect(b.gridRows, 5);
      final names = (await repository.listBoards()).map((x) => x.name);
      expect(names, ['Casa', 'Escola']);
    });

    test('rejeita nome vazio e grade fora do limite', () async {
      await expectLater(
        repository.createBoard(name: '   '),
        throwsArgumentError,
      );
      await expectLater(
        repository.createBoard(name: 'X', gridColumns: 0),
        throwsRangeError,
      );
      await expectLater(
        repository.createBoard(name: 'X', gridRows: 11),
        throwsRangeError,
      );
    });

    test('atualiza nome e grade e avança updatedAt', () async {
      final created = await repository.createBoard(name: 'Casa');
      now = now.add(const Duration(minutes: 5));

      final updated = await repository.updateBoard(
        created.copyWith(name: 'Casa nova', gridColumns: 6),
      );

      expect(updated.name, 'Casa nova');
      expect(updated.gridColumns, 6);
      expect(updated.createdAt, created.createdAt);
      expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
    });

    test('atualizar prancha inexistente lança NotFoundException', () async {
      final ghost = Board(
        id: 999,
        name: 'x',
        gridColumns: 4,
        gridRows: 4,
        position: 0,
        createdAt: now,
        updatedAt: now,
      );

      await expectLater(
        repository.updateBoard(ghost),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('apagar prancha apaga seus cards (cascata)', () async {
      final board = await repository.createBoard(name: 'Casa');
      await repository.addCard(board.id, const CardContent(label: 'Beber'));

      await repository.deleteBoard(board.id);

      expect(await repository.getBoard(board.id), isNull);
      expect(await repository.listCards(board.id), isEmpty);
    });

    test('apagar prancha destino de link só zera o link', () async {
      final home = await repository.createBoard(name: 'Início');
      final target = await repository.createBoard(name: 'Comidas');
      final card = await repository.addCard(
        home.id,
        CardContent(label: 'Comer', linkBoardId: target.id),
      );
      expect(card.content.linkBoardId, target.id);

      await repository.deleteBoard(target.id);

      final cards = await repository.listCards(home.id);
      expect(cards.single.content.linkBoardId, isNull);
      expect(cards.single.content.label, 'Comer');
    });
  });

  group('cards', () {
    test('adiciona ao final e preserva o conteúdo completo', () async {
      final board = await repository.createBoard(name: 'Casa');
      const content = CardContent(
        label: 'Beber',
        speechText: 'Quero beber água',
        symbol: SymbolRef(source: SymbolRef.arasaac, id: '1234', locale: 'pt'),
        backgroundColor: 0xFFFBB7C4,
      );

      final first = await repository.addCard(board.id, content);
      final second =
          await repository.addCard(board.id, const CardContent(label: 'Comer'));

      expect(first.position, 0);
      expect(second.position, 1);
      expect(first.content, content);
      expect(first.content.textToSpeak, 'Quero beber água');
      expect(second.content.textToSpeak, 'Comer'); // sem speechText, fala o label
    });

    test('guarda, troca e remove a classe gramatical', () async {
      final board = await repository.createBoard(name: 'Casa');

      final verb = await repository.addCard(
        board.id,
        const CardContent(label: 'Comer', wordClass: WordClass.verb),
      );
      final plain = await repository.addCard(
        board.id,
        const CardContent(label: 'Mesa'),
      );

      expect(verb.content.wordClass, WordClass.verb);
      expect(plain.content.wordClass, isNull);

      final changed = await repository.updateCard(
        verb.id,
        const CardContent(label: 'Comer', wordClass: WordClass.noun),
      );
      expect(changed.content.wordClass, WordClass.noun);

      final cleared = await repository.updateCard(
        verb.id,
        const CardContent(label: 'Comer'),
      );
      expect(cleared.content.wordClass, isNull);
      final cards = await repository.listCards(board.id);
      expect(cards.map((c) => c.content.wordClass), [null, null]);
    });

    test('adicionar em prancha inexistente lança NotFoundException', () async {
      await expectLater(
        repository.addCard(999, const CardContent(label: 'x')),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('atualiza e apaga um card', () async {
      final board = await repository.createBoard(name: 'Casa');
      final card =
          await repository.addCard(board.id, const CardContent(label: 'Beber'));

      final updated = await repository.updateCard(
        card.id,
        const CardContent(label: 'Água'),
      );
      expect(updated.content.label, 'Água');

      await repository.deleteCard(card.id);
      expect(await repository.listCards(board.id), isEmpty);
      await repository.deleteCard(card.id); // idempotente, não lança
    });

    test('atualizar card inexistente lança NotFoundException', () async {
      await expectLater(
        repository.updateCard(999, const CardContent(label: 'x')),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('reordena os cards', () async {
      final board = await repository.createBoard(name: 'Casa');
      final a =
          await repository.addCard(board.id, const CardContent(label: 'A'));
      final b =
          await repository.addCard(board.id, const CardContent(label: 'B'));
      final c =
          await repository.addCard(board.id, const CardContent(label: 'C'));

      await repository.reorderCards(board.id, [c.id, a.id, b.id]);

      final labels = (await repository.listCards(board.id))
          .map((card) => card.content.label);
      expect(labels, ['C', 'A', 'B']);
    });

    test('reordenar com ids faltando, extras ou repetidos lança erro',
        () async {
      final board = await repository.createBoard(name: 'Casa');
      final a =
          await repository.addCard(board.id, const CardContent(label: 'A'));
      final b =
          await repository.addCard(board.id, const CardContent(label: 'B'));

      await expectLater(
        repository.reorderCards(board.id, [a.id]),
        throwsArgumentError,
      );
      await expectLater(
        repository.reorderCards(board.id, [a.id, b.id, 999]),
        throwsArgumentError,
      );
      await expectLater(
        repository.reorderCards(board.id, [a.id, a.id]),
        throwsArgumentError,
      );
    });
  });
}
