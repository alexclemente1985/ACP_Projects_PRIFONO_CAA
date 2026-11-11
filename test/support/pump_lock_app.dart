import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/editing/presentation/edit_mode_controller.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

/// Sobe o app inteiro com uma prancha "Casa" e, se [settle], espera a splash e
/// fica na lista de pranchas (em USO, com o cadeado fechado na AppBar).
///
/// Rede, disco e banco são falsos. [themeMode] fixa o tema (claro por padrão,
/// para o teste não depender da máquina). Com `settle: false` devolve logo
/// depois do primeiro quadro, ainda na splash.
Future<EditModeController> pumpLockApp(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(390, 844),
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final editMode = EditModeController();
  final settings = SettingsController();
  await settings.setThemeMode(themeMode);
  final repository = InMemoryBoardRepository();
  await repository.createBoard(name: 'Casa');
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_lock_');
  addTearDown(() => root.deleteSync(recursive: true));

  await tester.pumpWidget(
    AppScope(
      settings: settings,
      boards: repository,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      editMode: editMode,
      child: const PrifonoApp(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return editMode;
}