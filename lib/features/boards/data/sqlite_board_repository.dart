import 'package:prifono_caa/core/errors/not_found_exception.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_layout.dart';
import 'package:prifono_caa/features/boards/domain/board_repository.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';
import 'package:sqflite/sqflite.dart';

class SqliteBoardRepository implements BoardRepository {
  /// [now] permite fixar o relógio nos testes.
  SqliteBoardRepository(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Database _db;
  final DateTime Function() _now;

  int _stamp() => _now().millisecondsSinceEpoch;

  // ---------------------------------------------------------------- boards

  @override
  Future<List<Board>> listBoards() async {
    final rows = await _db.query('boards', orderBy: 'position ASC, id ASC');
    return rows.map(_boardFromRow).toList();
  }

  @override
  Future<Board?> getBoard(int id) => _boardById(_db, id);

  @override
  Future<Board> createBoard({
    required String name,
    int gridColumns = Board.defaultColumns,
    int gridRows = Board.defaultRows,
  }) async {
    final cleanName = Board.checkName(name);
    Board.checkGrid(gridColumns, gridRows);

    // Transação: ler a próxima posição e inserir é uma operação só.
    return _db.transaction<Board>((txn) async {
      final position = Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COALESCE(MAX(position), -1) + 1 FROM boards',
            ),
          ) ??
          0;
      final stamp = _stamp();
      final id = await txn.insert('boards', {
        'name': cleanName,
        'grid_columns': gridColumns,
        'grid_rows': gridRows,
        'position': position,
        'created_at': stamp,
        'updated_at': stamp,
      });
      return (await _boardById(txn, id))!;
    });
  }

  @override
  Future<Board> updateBoard(Board board) async {
    final cleanName = Board.checkName(board.name);
    Board.checkGrid(board.gridColumns, board.gridRows);

    final count = await _db.update(
      'boards',
      {
        'name': cleanName,
        'grid_columns': board.gridColumns,
        'grid_rows': board.gridRows,
        'updated_at': _stamp(),
      },
      where: 'id = ?',
      whereArgs: [board.id],
    );
    if (count == 0) throw NotFoundException('board', board.id);
    return (await _boardById(_db, board.id))!;
  }

  @override
  Future<void> deleteBoard(int id) async {
    // Os cards saem junto por ON DELETE CASCADE (foreign keys ligadas).
    await _db.delete('boards', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------------------------------------------------------- cards

  @override
  Future<List<BoardCard>> listCards(int boardId) => _cardsOf(_db, boardId);

  @override
  Future<BoardCard> addCard(
    int boardId,
    CardContent content, {
    CardPlacement? placement,
  }) {
    return _db.transaction<BoardCard>((txn) async {
      final board = await _boardById(txn, boardId);
      if (board == null) throw NotFoundException('board', boardId);

      final others = _placementsOf(await _cardsOf(txn, boardId));
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

      // `position` é LEGADO (ADR-042): o app não a lê mais, mas a coluna é
      // NOT NULL sem valor padrão, então segue recebendo um número sequencial.
      final position = Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COALESCE(MAX(position), -1) + 1 '
              'FROM cards WHERE board_id = ?',
              [boardId],
            ),
          ) ??
          0;
      final stamp = _stamp();
      final id = await txn.insert('cards', {
        ..._contentToRow(content),
        ..._placementToRow(target),
        'board_id': boardId,
        'position': position,
        'created_at': stamp,
        'updated_at': stamp,
      });
      return (await _cardById(txn, id))!;
    });
  }

  @override
  Future<BoardCard> updateCard(int cardId, CardContent content) async {
    final count = await _db.update(
      'cards',
      {..._contentToRow(content), 'updated_at': _stamp()},
      where: 'id = ?',
      whereArgs: [cardId],
    );
    if (count == 0) throw NotFoundException('card', cardId);
    return (await _cardById(_db, cardId))!;
  }

  @override
  Future<void> deleteCard(int cardId) async {
    await _db.delete('cards', where: 'id = ?', whereArgs: [cardId]);
  }

  @override
  Future<BoardCard> moveCard(
    int cardId, {
    required int col,
    required int row,
  }) {
    return _db.transaction<BoardCard>((txn) async {
      final card = await _cardById(txn, cardId);
      if (card == null) throw NotFoundException('card', cardId);
      // O card existe, então a prancha existe (FK com cascata).
      final board = (await _boardById(txn, card.boardId))!;
      final others = _placementsOf(
        await _cardsOf(txn, card.boardId),
        except: {cardId},
      );

      final target = card.placement.copyWith(col: col, row: row);
      BoardLayout.requirePlaceable(
        target,
        columns: board.gridColumns,
        rows: board.gridRows,
        others: others,
      );

      await _writePlacement(txn, cardId, target, _stamp());
      return (await _cardById(txn, cardId))!;
    });
  }

  @override
  Future<void> swapCards(int cardIdA, int cardIdB) {
    return _db.transaction<void>((txn) async {
      if (cardIdA == cardIdB) {
        throw ArgumentError.value(
          cardIdB,
          'cardIdB',
          'precisa ser outro card',
        );
      }
      final a = await _cardById(txn, cardIdA);
      if (a == null) throw NotFoundException('card', cardIdA);
      final b = await _cardById(txn, cardIdB);
      if (b == null) throw NotFoundException('card', cardIdB);
      if (a.boardId != b.boardId) {
        throw ArgumentError('os cards são de pranchas diferentes');
      }
      final board = (await _boardById(txn, a.boardId))!;
      final others = _placementsOf(
        await _cardsOf(txn, a.boardId),
        except: {cardIdA, cardIdB},
      );

      final swapped = BoardLayout.swap(
        a.placement,
        b.placement,
        columns: board.gridColumns,
        rows: board.gridRows,
        others: others,
      );
      if (swapped == null) {
        throw ArgumentError('os cards não cabem nas posições trocadas');
      }

      final stamp = _stamp();
      await _writePlacement(txn, cardIdA, swapped.$1, stamp);
      await _writePlacement(txn, cardIdB, swapped.$2, stamp);
    });
  }

  @override
  Future<BoardCard> resizeCard(
    int cardId, {
    required int colSpan,
    required int rowSpan,
  }) {
    return _db.transaction<BoardCard>((txn) async {
      final card = await _cardById(txn, cardId);
      if (card == null) throw NotFoundException('card', cardId);
      final board = (await _boardById(txn, card.boardId))!;
      final others = _placementsOf(
        await _cardsOf(txn, card.boardId),
        except: {cardId},
      );

      final target = card.placement.copyWith(
        colSpan: colSpan,
        rowSpan: rowSpan,
      );
      BoardLayout.requirePlaceable(
        target,
        columns: board.gridColumns,
        rows: board.gridRows,
        others: others,
      );

      await _writePlacement(txn, cardId, target, _stamp());
      return (await _cardById(txn, cardId))!;
    });
  }

  // --------------------------------------------------------------- helpers

  Future<Board?> _boardById(DatabaseExecutor executor, int id) async {
    final rows = await executor.query(
      'boards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _boardFromRow(rows.first);
  }

  Future<BoardCard?> _cardById(DatabaseExecutor executor, int id) async {
    final rows = await executor.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _cardFromRow(rows.first);
  }

  /// Cards da prancha em ordem de leitura (linha, coluna, id).
  Future<List<BoardCard>> _cardsOf(
    DatabaseExecutor executor,
    int boardId,
  ) async {
    final rows = await executor.query(
      'cards',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'grid_row ASC, grid_col ASC, id ASC',
    );
    return rows.map(_cardFromRow).toList();
  }

  /// Posições dos [cards], sem os ids de [except].
  static List<CardPlacement> _placementsOf(
    List<BoardCard> cards, {
    Set<int> except = const {},
  }) {
    return [
      for (final card in cards)
        if (!except.contains(card.id)) card.placement,
    ];
  }

  Future<void> _writePlacement(
    DatabaseExecutor executor,
    int cardId,
    CardPlacement placement,
    int stamp,
  ) async {
    await executor.update(
      'cards',
      {..._placementToRow(placement), 'updated_at': stamp},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  static DateTime _dateFromMs(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  static Board _boardFromRow(Map<String, Object?> row) {
    return Board(
      id: row['id']! as int,
      name: row['name']! as String,
      gridColumns: row['grid_columns']! as int,
      gridRows: row['grid_rows']! as int,
      position: row['position']! as int,
      createdAt: _dateFromMs(row['created_at']! as int),
      updatedAt: _dateFromMs(row['updated_at']! as int),
    );
  }

  static BoardCard _cardFromRow(Map<String, Object?> row) {
    final symbolSource = row['symbol_source'] as String?;
    final symbolId = row['symbol_id'] as String?;
    final symbol = (symbolSource != null && symbolId != null)
        ? SymbolRef(
            source: symbolSource,
            id: symbolId,
            locale: row['symbol_locale'] as String?,
          )
        : null;

    return BoardCard(
      id: row['id']! as int,
      boardId: row['board_id']! as int,
      placement: CardPlacement(
        col: row['grid_col']! as int,
        row: row['grid_row']! as int,
        colSpan: row['col_span']! as int,
        rowSpan: row['row_span']! as int,
      ),
      content: CardContent(
        label: row['label']! as String,
        speechText: row['speech_text'] as String?,
        symbol: symbol,
        imagePath: row['image_path'] as String?,
        backgroundColor: row['background_color'] as int?,
        linkBoardId: row['link_board_id'] as int?,
        wordClass: WordClass.fromKey(row['word_class'] as String?),
      ),
      createdAt: _dateFromMs(row['created_at']! as int),
      updatedAt: _dateFromMs(row['updated_at']! as int),
    );
  }

  static Map<String, Object?> _contentToRow(CardContent content) {
    return {
      'label': content.label,
      'speech_text': content.speechText,
      'symbol_source': content.symbol?.source,
      'symbol_id': content.symbol?.id,
      'symbol_locale': content.symbol?.locale,
      'image_path': content.imagePath,
      'background_color': content.backgroundColor,
      'link_board_id': content.linkBoardId,
      'word_class': content.wordClass?.key,
    };
  }

  static Map<String, Object?> _placementToRow(CardPlacement placement) {
    return {
      'grid_col': placement.col,
      'grid_row': placement.row,
      'col_span': placement.colSpan,
      'row_span': placement.rowSpan,
    };
  }
}
