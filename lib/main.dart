import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/core/db/app_database.dart';
import 'package:prifono_caa/features/settings/data/sqlite_settings_repository.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.open();
  final settings = SettingsController(
    repository: SqliteSettingsRepository(database.db),
  );
  // Carregar antes do primeiro frame evita o tema "piscar" ao abrir.
  await settings.load();

  runApp(
    AppScope(
      settings: settings,
      child: const PrifonoApp(),
    ),
  );
}