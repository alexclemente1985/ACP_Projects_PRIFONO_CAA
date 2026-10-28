import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_repository.dart';

enum BoardsStatus { loading, ready, error }

/// Estado da lista de pranchas. Cada operação grava e depois recarrega a lista.
class BoardsController extends ChangeNotifier {
  BoardsController(this._repository);

  final BoardRepository _repository;

  BoardsStatus _status = BoardsStatus.loading;
  List<Board> _boards = const [];
  bool _disposed = false;

  BoardsStatus get status => _status;
  List<Board> get boards => _boards;

  /// Carrega (ou recarrega, após erro) a lista de pranchas.
  Future<void> load() async {
    try {
      final loaded = await _repository.listBoards();
      if (_disposed) return;
      _boards = loaded;
      _status = BoardsStatus.ready;
    } on Exception {
      if (_disposed) return;
      _status = BoardsStatus.error;
    }
    notifyListeners();
  }

  /// Operações de escrita: erros (Exception) sobem para a tela avisar o
  /// usuário. Dados inválidos (ArgumentError) são bug de quem chamou.
  Future<Board> create({
    required String name,
    required int columns,
    required int rows,
  }) async {
    final board = await _repository.createBoard(
      name: name,
      gridColumns: columns,
      gridRows: rows,
    );
    await load();
    return board;
  }

  Future<void> update(Board board) async {
    await _repository.updateBoard(board);
    await load();
  }

  Future<void> delete(int id) async {
    await _repository.deleteBoard(id);
    await load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
