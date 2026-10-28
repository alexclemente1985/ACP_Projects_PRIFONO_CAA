import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/core/db/app_database.dart';
import 'package:prifono_caa/features/boards/data/sqlite_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'board_repository_contract.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  group('SqliteBoardRepository', () {
    late AppDatabase database;
    late SqliteBoardRepository repository;

    runBoardRepositoryContract((now) async {
      database = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      repository = SqliteBoardRepository(database.db, now: now);
      return repository;
    });

    // Específico do SQLite: a cascata remove as LINHAS da tabela.
    test('apagar prancha remove as linhas dos cards no banco', () async {
      final board = await repository.createBoard(name: 'Casa');
      await repository.addCard(board.id, const CardContent(label: 'Beber'));

      await repository.deleteBoard(board.id);

      expect(await database.db.query('cards'), isEmpty);
    });
  });
}