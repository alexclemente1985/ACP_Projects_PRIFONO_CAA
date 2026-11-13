import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/core/errors/not_found_exception.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_repository.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

/// Cria um repositório limpo que usa o relógio [now] informado.
typedef RepositoryFactory = Future<BoardRepository> Function(
  DateTime Function() now,
);

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

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
    test('adiciona na primeira célula livre e preserva o conteúdo completo',
        () async {
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

      expect(first.placement, _at(0, 0));
      expect(second.placement, _at(1, 0));
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
      expect(updated.placement, card.placement); // atualizar não move

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
  });

  group('layout dos cards (ADR-042)', () {
    test('adiciona na primeira célula livre, em ordem de leitura', () async {
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 2,
        gridRows: 2,
      );

      final a = await repository.addCard(board.id, const CardContent(label: 'A'));
      final b = await repository.addCard(board.id, const CardContent(label: 'B'));
      final c = await repository.addCard(board.id, const CardContent(label: 'C'));

      expect(a.placement, _at(0, 0));
      expect(b.placement, _at(1, 0));
      expect(c.placement, _at(0, 1));
    });

    test('excluir deixa a posição em branco; o próximo card ocupa o buraco',
        () async {
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 2,
        gridRows: 2,
      );
      await repository.addCard(board.id, const CardContent(label: 'A'));
      final b = await repository.addCard(board.id, const CardContent(label: 'B'));
      await repository.addCard(board.id, const CardContent(label: 'C'));

      await repository.deleteCard(b.id);

      // Os outros NÃO sobem: C continua em (0,1).
      var cards = await repository.listCards(board.id);
      expect(cards.map((c) => c.content.label), ['A', 'C']);
      expect(cards.map((c) => c.placement), [_at(0, 0), _at(0, 1)]);

      final d = await repository.addCard(board.id, const CardContent(label: 'D'));

      expect(d.placement, _at(1, 0)); // o buraco deixado por B
      cards = await repository.listCards(board.id);
      expect(cards.map((c) => c.content.label), ['A', 'D', 'C']);
    });

    test('adiciona com posição e tamanho explícitos', () async {
      final board = await repository.createBoard(name: 'Casa'); // 4×4

      final card = await repository.addCard(
        board.id,
        const CardContent(label: 'Grande'),
        placement: _at(1, 1, 2, 3),
      );

      expect(card.placement, _at(1, 1, 2, 3));
      final cards = await repository.listCards(board.id);
      expect(cards.single.placement, _at(1, 1, 2, 3));
    });

    test('sem posição e sem célula livre lança BoardFullException', () async {
      final board = await repository.createBoard(
        name: 'Mini',
        gridColumns: 2,
        gridRows: 1,
      );
      // Um único card 2×1 cobre a grade inteira (1 card < 2 células).
      await repository.addCard(
        board.id,
        const CardContent(label: 'A'),
        placement: _at(0, 0, 2),
      );

      await expectLater(
        repository.addCard(board.id, const CardContent(label: 'B')),
        throwsA(
          isA<BoardFullException>().having((e) => e.capacity, 'capacity', 2),
        ),
      );
      expect(await repository.listCards(board.id), hasLength(1));
    });

    test('posição ocupada, fora da grade ou inválida lança ArgumentError',
        () async {
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 2,
        gridRows: 2,
      );
      await repository.addCard(board.id, const CardContent(label: 'A'));
      const content = CardContent(label: 'B');

      await expectLater(
        repository.addCard(board.id, content, placement: _at(0, 0)),
        throwsArgumentError, // ocupada
      );
      await expectLater(
        repository.addCard(board.id, content, placement: _at(2, 0)),
        throwsArgumentError, // fora da grade
      );
      await expectLater(
        repository.addCard(board.id, content, placement: _at(1, 0, 2)),
        throwsArgumentError, // passaria da borda
      );
      await expectLater(
        repository.addCard(board.id, content, placement: _at(-1, 0)),
        throwsArgumentError,
      );
      await expectLater(
        repository.addCard(board.id, content, placement: _at(1, 1, 1, 0)),
        throwsArgumentError, // altura 0
      );
      expect(await repository.listCards(board.id), hasLength(1));
    });

    test('move para célula livre, mantém o tamanho e avança updatedAt',
        () async {
      final board = await repository.createBoard(name: 'Casa'); // 4×4
      final card = await repository.addCard(
        board.id,
        const CardContent(label: 'A'),
        placement: _at(0, 0, 2),
      );
      now = now.add(const Duration(minutes: 5));

      final moved = await repository.moveCard(card.id, col: 1, row: 2);

      expect(moved.placement, _at(1, 2, 2));
      expect(moved.content, card.content);
      expect(moved.createdAt, card.createdAt);
      expect(moved.updatedAt.isAfter(card.updatedAt), isTrue);
      final cards = await repository.listCards(board.id);
      expect(cards.single.placement, _at(1, 2, 2));
    });

    test('mover pode deslizar sobre a própria área antiga', () async {
      final board = await repository.createBoard(name: 'Casa'); // 4×4
      final card = await repository.addCard(
        board.id,
        const CardContent(label: 'A'),
        placement: _at(0, 0, 2),
      );

      final moved = await repository.moveCard(card.id, col: 1, row: 0);

      expect(moved.placement, _at(1, 0, 2));
    });

    test('mover para lugar ocupado, fora da grade ou card inexistente falha',
        () async {
      final board = await repository.createBoard(name: 'Casa'); // 4×4
      final a = await repository.addCard(board.id, const CardContent(label: 'A'));
      await repository.addCard(
        board.id,
        const CardContent(label: 'B'),
        placement: _at(1, 1),
      );

      await expectLater(
        repository.moveCard(a.id, col: 1, row: 1),
        throwsArgumentError, // ocupado por B
      );
      await expectLater(
        repository.moveCard(a.id, col: 4, row: 0),
        throwsArgumentError, // fora da grade
      );
      await expectLater(
        repository.moveCard(a.id, col: -1, row: 0),
        throwsArgumentError,
      );
      await expectLater(
        repository.moveCard(999, col: 0, row: 0),
        throwsA(isA<NotFoundException>()),
      );
      final cards = await repository.listCards(board.id);
      expect(cards.map((c) => c.placement), [_at(0, 0), _at(1, 1)]);
    });

    test('trocar: cada card assume a posição do outro e mantém o tamanho',
        () async {
      final board = await repository.createBoard(name: 'Casa'); // 4×4
      final a = await repository.addCard(
        board.id,
        const CardContent(label: 'A'),
        placement: _at(0, 0, 2),
      );
      final b = await repository.addCard(
        board.id,
        const CardContent(label: 'B'),
        placement: _at(2, 1),
      );
      now = now.add(const Duration(minutes: 5));

      await repository.swapCards(a.id, b.id);

      final cards = await repository.listCards(board.id);
      expect(cards.map((c) => c.content.label), ['B', 'A']);
      expect(cards.map((c) => c.placement), [_at(0, 0), _at(2, 1, 2)]);
      for (final card in cards) {
        expect(card.updatedAt.isAfter(a.updatedAt), isTrue);
      }
    });

    test('trocar quando não cabe lança ArgumentError e não muda nada',
        () async {
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 3,
        gridRows: 1,
      );
      final a = await repository.addCard(
        board.id,
        const CardContent(label: 'A'),
        placement: _at(0, 0, 2),
      );
      final b = await repository.addCard(
        board.id,
        const CardContent(label: 'B'),
        placement: _at(2, 0),
      );

      // O card largo iria para a coluna 2 e passaria da borda.
      await expectLater(repository.swapCards(a.id, b.id), throwsArgumentError);

      final cards = await repository.listCards(board.id);
      expect(cards.map((c) => c.placement), [_at(0, 0, 2), _at(2, 0)]);
    });

    test('trocar com ids iguais, de pranchas diferentes ou inexistentes falha',
        () async {
      final home = await repository.createBoard(name: 'Casa');
      final school = await repository.createBoard(name: 'Escola');
      final a = await repository.addCard(home.id, const CardContent(label: 'A'));
      final c =
          await repository.addCard(school.id, const CardContent(label: 'C'));

      await expectLater(repository.swapCards(a.id, a.id), throwsArgumentError);
      await expectLater(repository.swapCards(a.id, c.id), throwsArgumentError);
      await expectLater(
        repository.swapCards(a.id, 999),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        repository.swapCards(999, a.id),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('redimensionar só consome posições em branco', () async {
      final board = await repository.createBoard(name: 'Casa'); // 4×4
      final a = await repository.addCard(board.id, const CardContent(label: 'A'));
      await repository.addCard(
        board.id,
        const CardContent(label: 'B'),
        placement: _at(2, 0),
      );

      final grown = await repository.resizeCard(a.id, colSpan: 2, rowSpan: 2);
      expect(grown.placement, _at(0, 0, 2, 2));

      await expectLater(
        repository.resizeCard(a.id, colSpan: 3, rowSpan: 2),
        throwsArgumentError, // cobriria o B
      );
      await expectLater(
        repository.resizeCard(a.id, colSpan: 5, rowSpan: 1),
        throwsArgumentError, // passaria da grade
      );
      await expectLater(
        repository.resizeCard(a.id, colSpan: 0, rowSpan: 1),
        throwsArgumentError, // menor que 1×1
      );
      await expectLater(
        repository.resizeCard(999, colSpan: 1, rowSpan: 1),
        throwsA(isA<NotFoundException>()),
      );
      var cards = await repository.listCards(board.id);
      expect(cards.first.placement, _at(0, 0, 2, 2)); // falhas não mudam nada

      final shrunk = await repository.resizeCard(a.id, colSpan: 1, rowSpan: 1);
      expect(shrunk.placement, _at(0, 0));
      cards = await repository.listCards(board.id);
      expect(cards.map((c) => c.placement), [_at(0, 0), _at(2, 0)]);
    });

    test('listCards devolve em ordem de leitura: linha e depois coluna',
        () async {
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 3,
        gridRows: 3,
      );
      await repository.addCard(
        board.id,
        const CardContent(label: 'A'),
        placement: _at(2, 0),
      );
      await repository.addCard(
        board.id,
        const CardContent(label: 'B'),
        placement: _at(0, 1),
      );
      await repository.addCard(
        board.id,
        const CardContent(label: 'C'),
        placement: _at(1, 0),
      );

      final labels = (await repository.listCards(board.id))
          .map((card) => card.content.label);

      expect(labels, ['C', 'A', 'B']);
    });
  });
}
