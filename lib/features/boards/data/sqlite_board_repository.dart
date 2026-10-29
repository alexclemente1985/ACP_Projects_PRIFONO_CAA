import 'package:prifono_caa/core/errors/not_found_exception.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
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
  Future<List<BoardCard>> listCards(int boardId) async {
    final rows = await _db.query(
      'cards',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'position ASC, id ASC',
    );
    return rows.map(_cardFromRow).toList();
  }

  @override
  Future<BoardCard> addCard(int boardId, CardContent content) {
    return _db.transaction<BoardCard>((txn) async {
      if (await _boardById(txn, boardId) == null) {
        throw NotFoundException('board', boardId);
      }
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
  Future<void> reorderCards(int boardId, List<int> orderedCardIds) {
    return _db.transaction<void>((txn) async {
      final rows = await txn.query(
        'cards',
        columns: ['id'],
        where: 'board_id = ?',
        whereArgs: [boardId],
      );
      final existing = rows.map((r) => r['id']! as int).toSet();
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

      // Batch: várias escritas enviadas juntas ao banco.
      final batch = txn.batch();
      for (var i = 0; i < orderedCardIds.length; i++) {
        batch.update(
          'cards',
          {'position': i},
          where: 'id = ? AND board_id = ?',
          whereArgs: [orderedCardIds[i], boardId],
        );
      }
      await batch.commit(noResult: true);
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
      position: row['position']! as int,
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
}