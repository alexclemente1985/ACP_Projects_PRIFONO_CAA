import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/boards_controller.dart';

void main() {
  group('BoardsController e as posições dos cards (ADR-042)', () {
    test('cardPlacements devolve as posições em ordem de leitura', () async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(name: 'Casa');
      await repository.addCard(
        board.id,
        const CardContent(label: 'B'),
        placement: const CardPlacement(col: 2, row: 1),
      );
      await repository.addCard(
        board.id,
        const CardContent(label: 'A'),
        placement: const CardPlacement(col: 1, row: 0, colSpan: 2),
      );
      final controller = BoardsController(repository);
      addTearDown(controller.dispose);

      expect(await controller.cardPlacements(board.id), const [
        CardPlacement(col: 1, row: 0, colSpan: 2),
        CardPlacement(col: 2, row: 1),
      ]);
    });

    test('cardPlacements de prancha sem cards é lista vazia', () async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(name: 'Casa');
      final controller = BoardsController(repository);
      addTearDown(controller.dispose);

      expect(await controller.cardPlacements(board.id), isEmpty);
    });

    test('update bloqueia se um card grande deixaria de caber inteiro',
        () async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 4,
        gridRows: 4,
      );
      // Só 1 card, mas ele ocupa as colunas 2–3 e as linhas 2–3.
      await repository.addCard(
        board.id,
        const CardContent(label: 'Grande'),
        placement: const CardPlacement(col: 2, row: 2, colSpan: 2, rowSpan: 2),
      );
      final controller = BoardsController(repository);
      addTearDown(controller.dispose);
      await controller.load();

      // 3 × 3 = 9 células para 1 card, mas o card sairia pela direita.
      await expectLater(
        controller.update(board.copyWith(gridColumns: 3, gridRows: 3)),
        throwsA(
          isA<BoardGridTooSmallException>()
              .having((e) => e.cardsToRemove, 'cardsToRemove', 1),
        ),
      );
      expect((await repository.listBoards()).single.gridColumns, 4);
    });

    test('update permite reduzir a grade quando só há buracos nas bordas',
        () async {
      final repository = InMemoryBoardRepository();
      final board = await repository.createBoard(
        name: 'Casa',
        gridColumns: 4,
        gridRows: 4,
      );
      await repository.addCard(
        board.id,
        const CardContent(label: 'Canto'),
        placement: const CardPlacement(col: 1, row: 1),
      );
      final controller = BoardsController(repository);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.update(board.copyWith(gridColumns: 2, gridRows: 2));

      expect(controller.boards.single.gridColumns, 2);
      expect(controller.boards.single.gridRows, 2);
      // Os cards não foram reorganizados.
      expect(
        await controller.cardPlacements(board.id),
        const [CardPlacement(col: 1, row: 1)],
      );
    });
  });
}
