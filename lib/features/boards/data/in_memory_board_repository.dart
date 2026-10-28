import 'dart:math' as math;

import 'package:prifono_caa/core/errors/not_found_exception.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_repository.dart';

/// Implementação em memória do [BoardRepository]. Serve para testes de widget
/// (que não esperam um banco real). Os testes de contrato garantem que ela se
/// comporta como a versão SQLite.
class InMemoryBoardRepository implements BoardRepository {
  InMemoryBoardRepository({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final List<Board> _boards = [];
  final List<BoardCard> _cards = [];
  int _nextBoardId = 1;
  int _nextCardId = 1;

  /// Mesmo critério do SQLite: milissegundos, em UTC.
  DateTime _stamp() => DateTime.fromMillisecondsSinceEpoch(
        _now().millisecondsSinceEpoch,
        isUtc: true,
      );

  @override
  Future<List<Board>> listBoards() async {
    return List.of(_boards)
      ..sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        return byPosition != 0 ? byPosition : a.id.compareTo(b.id);
      });
  }

  @override
  Future<Board?> getBoard(int id) async {
    for (final board in _boards) {
      if (board.id == id) return board;
    }
    return null;
  }

  @override
  Future<Board> createBoard({
    required String name,
    int gridColumns = Board.defaultColumns,
    int gridRows = Board.defaultRows,
  }) async {
    final cleanName = Board.checkName(name);
    Board.checkGrid(gridColumns, gridRows);

    final position = _boards.isEmpty
        ? 0
        : _boards.map((b) => b.position).reduce(math.max) + 1;
    final stamp = _stamp();
    final board = Board(
      id: _nextBoardId++,
      name: cleanName,
      gridColumns: gridColumns,
      gridRows: gridRows,
      position: position,
      createdAt: stamp,
      updatedAt: stamp,
    );
    _boards.add(board);
    return board;
  }

  @override
  Future<Board> updateBoard(Board board) async {
    final cleanName = Board.checkName(board.name);
    Board.checkGrid(board.gridColumns, board.gridRows);

    final index = _boards.indexWhere((b) => b.id == board.id);
    if (index < 0) throw NotFoundException('board', board.id);

    final current = _boards[index];
    final updated = Board(
      id: current.id,
      name: cleanName,
      gridColumns: board.gridColumns,
      gridRows: board.gridRows,
      position: current.position,
      createdAt: current.createdAt,
      updatedAt: _stamp(),
    );
    _boards[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteBoard(int id) async {
    _boards.removeWhere((b) => b.id == id);
    _cards.removeWhere((c) => c.boardId == id); // cascata
    for (var i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      if (card.content.linkBoardId == id) {
        _cards[i] = _copyCard(card, content: card.content.withoutLink());
      }
    }
  }

  @override
  Future<List<BoardCard>> listCards(int boardId) async {
    return _cards.where((c) => c.boardId == boardId).toList()
      ..sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        return byPosition != 0 ? byPosition : a.id.compareTo(b.id);
      });
  }

  @override
  Future<BoardCard> addCard(int boardId, CardContent content) async {
    if (await getBoard(boardId) == null) {
      throw NotFoundException('board', boardId);
    }
    final positions =
        _cards.where((c) => c.boardId == boardId).map((c) => c.position);
    final position = positions.isEmpty ? 0 : positions.reduce(math.max) + 1;
    final stamp = _stamp();
    final card = BoardCard(
      id: _nextCardId++,
      boardId: boardId,
      position: position,
      content: content,
      createdAt: stamp,
      updatedAt: stamp,
    );
    _cards.add(card);
    return card;
  }

  @override
  Future<BoardCard> updateCard(int cardId, CardContent content) async {
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index < 0) throw NotFoundException('card', cardId);
    final updated =
        _copyCard(_cards[index], content: content, updatedAt: _stamp());
    _cards[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCard(int cardId) async {
    _cards.removeWhere((c) => c.id == cardId);
  }

  @override
  Future<void> reorderCards(int boardId, List<int> orderedCardIds) async {
    final existing =
        _cards.where((c) => c.boardId == boardId).map((c) => c.id).toSet();
    final requested = orderedCardIds.toSet();
    if (requested.length != orderedCardIds.length ||
        requested.length != existing.length ||
        !existing.containsAll(requested)) {
      throw ArgumentError.value(
        orderedCardIds,
        'orderedCardIds',
        'deve conter exatamente os cards da prancha $boardId, sem repetir',
      );
    }
    for (var position = 0; position < orderedCardIds.length; position++) {
      final index = _cards.indexWhere((c) => c.id == orderedCardIds[position]);
      _cards[index] = _copyCard(_cards[index], position: position);
    }
  }

  BoardCard _copyCard(
    BoardCard card, {
    int? position,
    CardContent? content,
    DateTime? updatedAt,
  }) {
    return BoardCard(
      id: card.id,
      boardId: card.boardId,
      position: position ?? card.position,
      content: content ?? card.content,
      createdAt: card.createdAt,
      updatedAt: updatedAt ?? card.updatedAt,
    );
  }
}
