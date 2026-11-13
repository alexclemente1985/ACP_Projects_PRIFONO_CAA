import 'dart:math' as math;

import 'package:prifono_caa/core/errors/not_found_exception.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_layout.dart';
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
        final byRow = a.placement.row.compareTo(b.placement.row);
        if (byRow != 0) return byRow;
        final byCol = a.placement.col.compareTo(b.placement.col);
        return byCol != 0 ? byCol : a.id.compareTo(b.id);
      });
  }

  @override
  Future<BoardCard> addCard(
    int boardId,
    CardContent content, {
    CardPlacement? placement,
  }) async {
    final board = await getBoard(boardId);
    if (board == null) throw NotFoundException('board', boardId);

    final others = _placementsOf(boardId);
    final CardPlacement target;
    if (placement == null) {
      final free = BoardLayout.firstFree(
        columns: board.gridColumns,
        rows: board.gridRows,
        others: others,
      );
      if (free == null) {
        throw BoardFullException(
          BoardCapacity.of(board.gridColumns, board.gridRows),
        );
      }
      target = free;
    } else {
      BoardLayout.requirePlaceable(
        placement,
        columns: board.gridColumns,
        rows: board.gridRows,
        others: others,
      );
      target = placement;
    }

    final stamp = _stamp();
    final card = BoardCard(
      id: _nextCardId++,
      boardId: boardId,
      placement: target,
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
  Future<BoardCard> moveCard(
    int cardId, {
    required int col,
    required int row,
  }) async {
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index < 0) throw NotFoundException('card', cardId);
    final card = _cards[index];
    final board = _boardOf(card.boardId);

    final target = card.placement.copyWith(col: col, row: row);
    BoardLayout.requirePlaceable(
      target,
      columns: board.gridColumns,
      rows: board.gridRows,
      others: _placementsOf(card.boardId, except: {cardId}),
    );

    final updated = _copyCard(card, placement: target, updatedAt: _stamp());
    _cards[index] = updated;
    return updated;
  }

  @override
  Future<void> swapCards(int cardIdA, int cardIdB) async {
    if (cardIdA == cardIdB) {
      throw ArgumentError.value(cardIdB, 'cardIdB', 'precisa ser outro card');
    }
    final indexA = _cards.indexWhere((c) => c.id == cardIdA);
    if (indexA < 0) throw NotFoundException('card', cardIdA);
    final indexB = _cards.indexWhere((c) => c.id == cardIdB);
    if (indexB < 0) throw NotFoundException('card', cardIdB);
    final a = _cards[indexA];
    final b = _cards[indexB];
    if (a.boardId != b.boardId) {
      throw ArgumentError('os cards são de pranchas diferentes');
    }
    final board = _boardOf(a.boardId);

    final swapped = BoardLayout.swap(
      a.placement,
      b.placement,
      columns: board.gridColumns,
      rows: board.gridRows,
      others: _placementsOf(a.boardId, except: {cardIdA, cardIdB}),
    );
    if (swapped == null) {
      throw ArgumentError('os cards não cabem nas posições trocadas');
    }

    final stamp = _stamp();
    _cards[indexA] = _copyCard(a, placement: swapped.$1, updatedAt: stamp);
    _cards[indexB] = _copyCard(b, placement: swapped.$2, updatedAt: stamp);
  }

  @override
  Future<BoardCard> resizeCard(
    int cardId, {
    required int colSpan,
    required int rowSpan,
  }) async {
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index < 0) throw NotFoundException('card', cardId);
    final card = _cards[index];
    final board = _boardOf(card.boardId);

    final target = card.placement.copyWith(colSpan: colSpan, rowSpan: rowSpan);
    BoardLayout.requirePlaceable(
      target,
      columns: board.gridColumns,
      rows: board.gridRows,
      others: _placementsOf(card.boardId, except: {cardId}),
    );

    final updated = _copyCard(card, placement: target, updatedAt: _stamp());
    _cards[index] = updated;
    return updated;
  }

  /// A prancha de um card que existe sempre existe (a exclusão é em cascata).
  Board _boardOf(int boardId) => _boards.firstWhere((b) => b.id == boardId);

  /// Posições dos cards da prancha, sem os ids de [except].
  List<CardPlacement> _placementsOf(
    int boardId, {
    Set<int> except = const {},
  }) {
    return [
      for (final card in _cards)
        if (card.boardId == boardId && !except.contains(card.id))
          card.placement,
    ];
  }

  BoardCard _copyCard(
    BoardCard card, {
    CardPlacement? placement,
    CardContent? content,
    DateTime? updatedAt,
  }) {
    return BoardCard(
      id: card.id,
      boardId: card.boardId,
      placement: placement ?? card.placement,
      content: content ?? card.content,
      createdAt: card.createdAt,
      updatedAt: updatedAt ?? card.updatedAt,
    );
  }
}
