import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/speech/domain/speech_service.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../speech/fake_speech_service.dart';

/// Sobe o app com uma prancha "Casa" com os [cards] e abre a prancha.
Future<FakeSpeechService> _openBoard(
  WidgetTester tester,
  List<CardContent> cards, {
  SpeechException? failure,
}) async {
  final speech = FakeSpeechService()..failure = failure;
  final repository = InMemoryBoardRepository();
  final board = await repository.createBoard(name: 'Casa');
  for (final card in cards) {
    await repository.addCard(board.id, card);
  }
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_speech_');
  addTearDown(() => root.deleteSync(recursive: true));

  await tester.pumpWidget(
    AppScope(
      settings: SettingsController(),
      boards: repository,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      speech: speech,
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Casa'));
  await tester.pumpAndSettle();
  return speech;
}

void main() {
  group('tocar num card (E5-1)', () {
    testWidgets('fala o texto falado, ou o rótulo quando não há', (
      tester,
    ) async {
      final speech = await _openBoard(tester, const [
        CardContent(label: 'Água', speechText: 'Quero beber água'),
        CardContent(label: 'Sim'),
      ]);

      await tester.tap(find.text('Água'));
      await tester.pump();
      await tester.tap(find.text('Sim'));
      await tester.pump();

      expect(speech.spoken, ['Quero beber água', 'Sim']);
      expect(find.byType(CardEditorPage), findsNothing);
    });

    testWidgets('toque longo abre o editor e não fala', (tester) async {
      final speech = await _openBoard(tester, const [
        CardContent(label: 'Água'),
      ]);

      await tester.longPress(find.text('Água'));
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorPage), findsOneWidget);
      expect(speech.spoken, isEmpty);
    });

    testWidgets('sem voz em português mostra o aviso', (tester) async {
      await _openBoard(
        tester,
        const [CardContent(label: 'Água')],
        failure: const SpeechException(SpeechErrorKind.voiceUnavailable),
      );

      await tester.tap(find.text('Água'));
      await tester.pump();

      expect(find.textContaining('voz em português do Brasil'), findsOneWidget);
    });

    testWidgets('falha ao falar mostra o aviso geral', (tester) async {
      await _openBoard(
        tester,
        const [CardContent(label: 'Água')],
        failure: const SpeechException(SpeechErrorKind.failed),
      );

      await tester.tap(find.text('Água'));
      await tester.pump();

      expect(find.textContaining('Não foi possível falar'), findsOneWidget);
    });
  });
}
