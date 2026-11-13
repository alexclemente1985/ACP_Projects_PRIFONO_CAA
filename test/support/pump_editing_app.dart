import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/editing/presentation/edit_mode_controller.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_controller.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../features/speech/fake_speech_service.dart';

/// O app inteiro de pé, com as peças que os testes de edição precisam olhar.
class EditingApp {
  EditingApp({
    required this.settings,
    required this.editMode,
    required this.speech,
    required this.sentence,
  });

  final SettingsController settings;
  final EditModeController editMode;
  final FakeSpeechService speech;
  final SentenceController sentence;
}

/// Sobe o [PrifonoApp] na lista de pranchas, com as pranchas [boards] (nome →
/// cards). [pin] liga o PIN do modo de edição e [idleMinutes] escolhe o
/// bloqueio por inatividade (0 = desligado; sem informar vale o padrão, 5).
///
/// (O nome do arquivo não termina em `_test` de propósito: é só um apoio.)
Future<EditingApp> pumpEditingApp(
  WidgetTester tester, {
  Map<String, List<CardContent>> boards = const {},
  String? pin,
  int? idleMinutes,
}) async {
  final settings = SettingsController();
  if (pin != null) await settings.setPin(pin);
  if (idleMinutes != null) await settings.setEditIdleMinutes(idleMinutes);

  final speech = FakeSpeechService();
  final sentence = SentenceController();
  final editMode = EditModeController();
  final repository = InMemoryBoardRepository();
  for (final entry in boards.entries) {
    final board = await repository.createBoard(name: entry.key);
    for (final card in entry.value) {
      await repository.addCard(board.id, card);
    }
  }
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_idle_');
  addTearDown(() => root.deleteSync(recursive: true));

  await tester.pumpWidget(
    AppScope(
      settings: settings,
      boards: repository,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      speech: speech,
      sentence: sentence,
      editMode: editMode,
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return EditingApp(
    settings: settings,
    editMode: editMode,
    speech: speech,
    sentence: sentence,
  );
}
