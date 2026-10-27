import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/core/db/app_database.dart';
import 'package:prifono_caa/features/settings/data/sqlite_settings_repository.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.open();
  final settings = SettingsController(
    repository: SqliteSettingsRepository(database.db),
  );
  // Carregar antes do primeiro frame evita o tema "piscar" ao abrir.
  await settings.load();

  final supportDir = await getApplicationSupportDirectory();
  final symbols = ArasaacProvider();
  final symbolImages = SymbolImageStore(
    root: Directory(p.join(supportDir.path, 'symbols')),
    provider: symbols,
  );

  runApp(
    AppScope(
      settings: settings,
      symbols: symbols,
      symbolImages: symbolImages,
      child: const PrifonoApp(),
    ),
  );
}