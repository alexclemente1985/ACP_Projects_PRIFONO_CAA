import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prifono_caa/core/db/app_database.dart';
import 'package:prifono_caa/core/db/migrations.dart';
import 'package:prifono_caa/features/boards/data/sqlite_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('cria o esquema completo e grava a versão', () async {
    final database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(database.close);

    expect(await database.db.getVersion(), kMigrations.length);

    final rows = await database.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = rows.map((r) => r['name']! as String).toSet();
    expect(names, containsAll(<String>['boards', 'cards', 'app_settings']));
  });

  test('foreign keys estão ligadas', () async {
    final database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(database.close);

    final rows = await database.db.rawQuery('PRAGMA foreign_keys');

    expect(rows.single['foreign_keys'], 1);
  });

  test('migra de uma versão anterior preservando os dados', () async {
    final dir = Directory.systemTemp.createTempSync('prifono_db_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = p.join(dir.path, 'test.db');

    // "App antigo": só a migração 1.
    final oldApp = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: path,
      migrations: [kMigrations.first],
    );
    await oldApp.db.insert('boards', {
      'name': 'Casa',
      'created_at': 1,
      'updated_at': 1,
    });
    await oldApp.close();

    // "App novo": migração 1 + uma migração 2 inventada para o teste.
    final newApp = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: path,
      migrations: [
        kMigrations.first,
        ['ALTER TABLE boards ADD COLUMN color INTEGER'],
      ],
    );
    addTearDown(newApp.close);

    expect(await newApp.db.getVersion(), 2);
    final rows = await newApp.db.query('boards');
    expect(rows.single['name'], 'Casa'); // dado antigo preservado
    expect(rows.single['color'], isNull); // coluna nova existe
  });

  test('migração real v1 → v2 mantém os cards e cria a coluna word_class', () async {
    final dir = Directory.systemTemp.createTempSync('privox_db_v2_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = p.join(dir.path, 'test.db');

    // "App antigo": só a migração 1, com um card de cor livre.
    final oldApp = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: path,
      migrations: [kMigrations.first],
    );
    final boardId = await oldApp.db.insert('boards', {
      'name': 'Casa',
      'created_at': 1,
      'updated_at': 1,
    });
    await oldApp.db.insert('cards', {
      'board_id': boardId,
      'position': 0,
      'label': 'Sim',
      'background_color': 0xFFFBB7C4,
      'created_at': 1,
      'updated_at': 1,
    });
    await oldApp.close();

    // "App novo": todas as migrações de verdade.
    final newApp = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    addTearDown(newApp.close);

    expect(await newApp.db.getVersion(), kMigrations.length);
    expect(kMigrations.length, greaterThanOrEqualTo(2));
    final repository = SqliteBoardRepository(newApp.db);
    final cards = await repository.listCards(boardId);
    expect(cards.single.content.label, 'Sim'); // dado antigo preservado
    expect(cards.single.content.backgroundColor, 0xFFFBB7C4);
    expect(cards.single.content.wordClass, isNull); // card antigo: sem classe

    final updated = await repository.updateCard(
      cards.single.id,
      const CardContent(label: 'Sim', wordClass: WordClass.adverb),
    );
    expect(updated.content.wordClass, WordClass.adverb);
  });
}
