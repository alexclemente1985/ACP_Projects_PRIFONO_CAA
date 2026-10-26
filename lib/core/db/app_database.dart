import 'package:path/path.dart' as p;
import 'package:prifono_caa/core/db/migrations.dart';
import 'package:sqflite/sqflite.dart';

/// Abre o banco SQLite do app e aplica as migrações pendentes.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const String fileName = 'prifono_caa.db';

  /// [factory], [path] e [migrations] existem para os testes
  /// (banco em memória, migrações customizadas). No app, use `open()`.
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
    List<List<String>> migrations = kMigrations,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);

    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: migrations.length,
        // Em SQLite, foreign keys vêm DESLIGADAS: precisa ligar a cada conexão.
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
        onCreate: (database, version) =>
            _migrate(database, migrations, from: 0, to: version),
        onUpgrade: (database, oldVersion, newVersion) =>
            _migrate(database, migrations, from: oldVersion, to: newVersion),
      ),
    );
    return AppDatabase._(db);
  }

  /// Executa as migrações [from] (inclusive) até [to] (exclusive).
  /// O sqflite já roda onCreate/onUpgrade dentro de uma transação.
  static Future<void> _migrate(
    Database db,
    List<List<String>> migrations, {
    required int from,
    required int to,
  }) async {
    for (var version = from; version < to; version++) {
      for (final statement in migrations[version]) {
        await db.execute(statement);
      }
    }
  }

  Future<void> close() => db.close();
}