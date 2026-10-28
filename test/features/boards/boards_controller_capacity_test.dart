import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/boards_controller.dart';

void main() {
  group('BoardsController e a capacidade da prancha', () {
    test('update bloqueia reduzir a grade abaixo da quantidade de cards', () async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 2,
        gridRows: 2,
      );
      for (final label in ['A', 'B', 'C', 'D']) {
        await repository.addCard(board.id, CardContent(label: label));
      }
      final controller = BoardsController(repository);
      addTearDown(controller.dispose);
      await controller.load();

      await expectLater(
        controller.update(board.copyWith(gridColumns: 1)),
        throwsA(
          isA<BoardGridTooSmallException>()
              .having((e) => e.cardsToRemove, 'cardsToRemove', 2),
        ),
      );

      final saved = (await repository.listBoards()).single;
      expect(saved.gridColumns, 2);
    });

    test('update permite mudar a grade quando os cards cabem', () async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 2,
        gridRows: 2,
      );
      for (final label in ['A', 'B', 'C', 'D']) {
        await repository.addCard(board.id, CardContent(label: label));
      }
      final controller = BoardsController(repository);
      addTearDown(controller.dispose);
      await controller.load();

      // 4 × 1 = 4 células: os 4 cards cabem.
      await controller.update(board.copyWith(gridColumns: 4, gridRows: 1));

      expect(controller.boards.single.gridColumns, 4);
      expect(controller.boards.single.gridRows, 1);
    });

    test('cardCount devolve quantos cards a prancha tem', () async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(name: 'Casa');
      await repository.addCard(board.id, const CardContent(label: 'A'));
      await repository.addCard(board.id, const CardContent(label: 'B'));
      final controller = BoardsController(repository);
      addTearDown(controller.dispose);

      expect(await controller.cardCount(board.id), 2);
    });
  });
}
