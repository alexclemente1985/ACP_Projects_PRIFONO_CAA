import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/presentation/boards_controller.dart';

/// Repositório que falha ao listar, para testar o estado de erro.
class _FailingRepository extends InMemoryBoardRepository {
  bool fail = true;

  @override
  Future<List<Board>> listBoards() async {
    if (fail) throw Exception('banco indisponível');
    return super.listBoards();
  }
}

void main() {
  test('load: loading -> ready, com a lista vazia', () async {
    final controller = BoardsController(InMemoryBoardRepository());
    addTearDown(controller.dispose);
    expect(controller.status, BoardsStatus.loading);

    await controller.load();

    expect(controller.status, BoardsStatus.ready);
    expect(controller.boards, isEmpty);
  });

  test('create, update e delete atualizam a lista e notificam', () async {
    final controller = BoardsController(InMemoryBoardRepository());
    addTearDown(controller.dispose);
    await controller.load();
    var notifications = 0;
    controller.addListener(() => notifications++);

    final board = await controller.create(name: 'Casa', columns: 3, rows: 2);
    expect(controller.boards.map((b) => b.name), ['Casa']);

    await controller.update(board.copyWith(name: 'Casa nova'));
    expect(controller.boards.single.name, 'Casa nova');

    await controller.delete(board.id);
    expect(controller.boards, isEmpty);
    expect(notifications, 3);
  });

  test('erro ao carregar vira status error e dá para tentar de novo', () async {
    final repository = _FailingRepository();
    final controller = BoardsController(repository);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.status, BoardsStatus.error);

    repository.fail = false;
    await controller.load();
    expect(controller.status, BoardsStatus.ready);
  });
}
