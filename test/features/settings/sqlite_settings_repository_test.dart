import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/core/db/app_database.dart';
import 'package:prifono_caa/features/settings/data/sqlite_settings_repository.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase database;
  late SqliteSettingsRepository repository;

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = SqliteSettingsRepository(database.db);
  });

  tearDown(() => database.close());

  test('devolve null para chave inexistente', () async {
    expect(await repository.read('nada'), isNull);
  });

  test('grava e sobrescreve o mesmo valor', () async {
    await repository.write('k', 'a');
    await repository.write('k', 'b');

    expect(await repository.read('k'), 'b');
  });

  test('o controller sobrevive a um "reinício" com o mesmo banco', () async {
    await SettingsController(repository: repository)
        .setThemeMode(ThemeMode.dark);

    final afterRestart = SettingsController(repository: repository);
    await afterRestart.load();

    expect(afterRestart.themeMode, ThemeMode.dark);
  });
}