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
  });
}
