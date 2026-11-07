import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/core/db/app_database.dart';
import 'package:prifono_caa/features/boards/data/sqlite_board_repository.dart';
import 'package:prifono_caa/features/settings/data/sqlite_settings_repository.dart';
import 'package:prifono_caa/features/settings/domain/app_language.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/speech/data/flutter_tts_speech_service.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.open();
  // Sem escolha gravada, o idioma segue o aparelho (ADR-034).
  final settings = SettingsController(
    repository: SqliteSettingsRepository(database.db),
    defaultLanguage: AppLanguage.system,
    deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
  );
  // Carregar antes do primeiro frame evita o tema "piscar" ao abrir.
  await settings.load();

  final supportDir = await getApplicationSupportDirectory();
  // Busca e voz leem o idioma em uso a cada uso: trocar nos Ajustes vale já.
  final symbols = ArasaacProvider(
    localeSource: () => settings.effectiveLanguage.arasaacCode,
  );
  final symbolImages = SymbolImageStore(
    root: Directory(p.join(supportDir.path, 'symbols')),
    provider: symbols,
  );

  final speech = FlutterTtsSpeechService(
    languageSource: () => settings.effectiveLanguage.ttsLanguage,
  );
  // Aquece a voz na abertura: o primeiro toque num card não espera o motor.
  unawaited(speech.warmUp());

  runApp(
    AppScope(
      settings: settings,
      boards: SqliteBoardRepository(database.db),
      symbols: symbols,
      symbolImages: symbolImages,
      speech: speech,
      child: const PrifonoApp(),
    ),
  );
}