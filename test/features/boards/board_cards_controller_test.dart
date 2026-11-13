import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/board_cards_controller.dart';

/// Repositório em memória que pode ser mandado falhar, para testar os erros.
class _FlakyRepository extends InMemoryBoardRepository {
  bool failListCards = false;
  bool failDeleteCard = false;

  @override
  Future<List<BoardCard>> listCards(int boardId) async {
    if (failListCards) throw Exception('falha ao listar');
    return super.listCards(boardId);
  }

  @override
  Future<void> deleteCard(int cardId) async {
    if (failDeleteCard) throw Exception('falha ao excluir');
    await super.deleteCard(cardId);
  }
}

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

Future<(_FlakyRepository, Board)> _setup({
  int columns = 2,
  int rows = 2,
}) async {
  final repository = _FlakyRepository();
  await repository.createBoard(
    name: 'Casa',
    gridColumns: columns,
    gridRows: rows,
  );
  final board = (await repository.listBoards()).single;
  return (repository, board);
}

void main() {
  group('BoardCardsController', () {
    test('load sai de loading e entrega os cards em ordem', () async {
      final (repository, board) = await _setup();
      await repository.addCard(board.id, const CardContent(label: 'A'));
      await repository.addCard(board.id, const CardContent(label: 'B'));
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);

      expect(controller.status, CardsStatus.loading);
      await controller.load();

      expect(controller.status, CardsStatus.ready);
      expect(controller.cards.map((c) => c.content.label), ['A', 'B']);
    });

    test('add insere ao final, atualiza a lista e fecha o espaço', () async {
      final (repository, board) = await _setup(rows: 1); // capacidade 2
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.capacity, 2);
      expect(controller.hasRoom, isTrue);
      expect(controller.freeCells, 2);

      await controller.add(const CardContent(label: 'A'));
      await controller.add(const CardContent(label: 'B'));

      expect(controller.cards.map((c) => c.content.label), ['A', 'B']);
      expect(controller.hasRoom, isFalse);
      expect(controller.freeCells, 0);
    });

    test('add numa prancha cheia lança BoardFullException e não grava', () async {
      final (repository, board) = await _setup(rows: 1); // capacidade 2
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();
      await controller.add(const CardContent(label: 'A'));
      await controller.add(const CardContent(label: 'B'));

      await expectLater(
        controller.add(const CardContent(label: 'C')),
        throwsA(isA<BoardFullException>()),
      );

      expect(controller.cards, hasLength(2));
      expect(await repository.listCards(board.id), hasLength(2));
    });

    test('update troca o conteúdo do card', () async {
      final (repository, board) = await _setup();
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();
      await controller.add(const CardContent(label: 'A'));
      final id = controller.cards.single.id;

      await controller.update(
        id,
        const CardContent(label: 'Água', backgroundColor: 0xFFFBB7C4),
      );

      expect(controller.cards.single.content.label, 'Água');
      expect(controller.cards.single.content.backgroundColor, 0xFFFBB7C4);
    });

    test('delete remove o card, mantém a ordem dos demais e libera espaço', () async {
      final (repository, board) = await _setup(rows: 2); // capacidade 4
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();
      for (final label in ['A', 'B', 'C', 'D']) {
        await controller.add(CardContent(label: label));
      }
      expect(controller.hasRoom, isFalse);
      final idOfB = controller.cards[1].id;

      await controller.delete(idOfB);

      expect(controller.cards.map((c) => c.content.label), ['A', 'C', 'D']);
      expect(controller.hasRoom, isTrue);
    });

    test('falha ao listar vira status error e load de novo recupera', () async {
      final (repository, board) = await _setup();
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);

      repository.failListCards = true;
      await controller.load();
      expect(controller.status, CardsStatus.error);

      repository.failListCards = false;
      await controller.load();
      expect(controller.status, CardsStatus.ready);
    });

    test('escrita que falha propaga a exceção e não muda o estado', () async {
      final (repository, board) = await _setup();
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();
      await controller.add(const CardContent(label: 'A'));
      final id = controller.cards.single.id;

      repository.failDeleteCard = true;
      await expectLater(controller.delete(id), throwsA(isA<Exception>()));

      expect(controller.status, CardsStatus.ready);
      expect(controller.cards, hasLength(1));
    });

    test('escrita ok mas releitura falha: status error, load recupera', () async {
      final (repository, board) = await _setup();
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();
      await controller.add(const CardContent(label: 'A'));
      final id = controller.cards.single.id;

      repository.failListCards = true;
      await controller.delete(id); // apagou, mas não conseguiu reler
      expect(controller.status, CardsStatus.error);

      repository.failListCards = false;
      await controller.load();
      expect(controller.status, CardsStatus.ready);
      expect(controller.cards, isEmpty);
    });

    test('dispose no meio de uma leitura não lança', () async {
      final (repository, board) = await _setup();
      final controller = BoardCardsController(repository, board: board);

      final pending = controller.load();
      controller.dispose();

      await pending; // não deve lançar nem notificar depois do dispose
    });

    test('add sem posição ocupa o buraco deixado por um card excluído',
        () async {
      final (repository, board) = await _setup(); // 2×2
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();
      for (final label in ['A', 'B', 'C']) {
        await controller.add(CardContent(label: label));
      }
      await controller.delete(controller.cards[1].id); // B sai: buraco (1,0)

      await controller.add(const CardContent(label: 'D'));

      expect(controller.cards.map((c) => c.content.label), ['A', 'D', 'C']);
      expect(controller.cards[1].placement, _at(1, 0));
    });

    test('hasRoom e freeCells contam células livres, não cards', () async {
      final (repository, board) = await _setup(); // 2×2, capacidade 4
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();

      // Um card 2×1 cobre 2 das 4 células.
      await controller.add(
        const CardContent(label: 'Grande'),
        placement: _at(0, 0, 2),
      );
      expect(controller.freeCells, 2);
      expect(controller.hasRoom, isTrue);

      await controller.add(const CardContent(label: 'B'));
      await controller.add(const CardContent(label: 'C'));

      // Só 3 cards (< capacidade 4), mas não há célula livre.
      expect(controller.cards, hasLength(3));
      expect(controller.freeCells, 0);
      expect(controller.hasRoom, isFalse);
      await expectLater(
        controller.add(const CardContent(label: 'D')),
        throwsA(isA<BoardFullException>()),
      );
    });

    test('move, swap e resize gravam e relêem a lista', () async {
      final (repository, board) = await _setup(columns: 3, rows: 3);
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();
      await controller.add(const CardContent(label: 'A'));
      await controller.add(const CardContent(label: 'B'));
      BoardCard byLabel(String label) =>
          controller.cards.firstWhere((c) => c.content.label == label);

      await controller.move(byLabel('A').id, col: 2, row: 2);
      expect(byLabel('A').placement, _at(2, 2));
      expect(byLabel('B').placement, _at(1, 0));

      await controller.swap(byLabel('A').id, byLabel('B').id);
      expect(byLabel('A').placement, _at(1, 0));
      expect(byLabel('B').placement, _at(2, 2));

      await controller.resize(byLabel('A').id, colSpan: 2, rowSpan: 1);
      expect(byLabel('A').placement, _at(1, 0, 2));
    });

    test('mover para um lugar impossível propaga ArgumentError e mantém o estado',
        () async {
      final (repository, board) = await _setup(); // 2×2
      final controller = BoardCardsController(repository, board: board);
      addTearDown(controller.dispose);
      await controller.load();
      await controller.add(const CardContent(label: 'A'));
      await controller.add(const CardContent(label: 'B'));

      await expectLater(
        controller.move(controller.cards.first.id, col: 1, row: 0), // B está lá
        throwsArgumentError,
      );

      expect(controller.status, CardsStatus.ready);
      expect(controller.cards.map((c) => c.placement), [_at(0, 0), _at(1, 0)]);
    });
  });
}
