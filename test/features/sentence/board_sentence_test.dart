import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_bar.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_controller.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/speech/domain/speech_service.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../speech/fake_speech_service.dart';

/// O que os testes precisam para olhar e mexer no app.
class _App {
  _App(this.speech, this.sentence);

  final FakeSpeechService speech;
  final SentenceController sentence;
}

/// Sobe o app com as pranchas [boards] (nome → cards) e fica na lista.
Future<_App> _pumpApp(
  WidgetTester tester,
  Map<String, List<CardContent>> boards, {
  SpeechException? failure,
  SentenceController? sentence,
}) async {
  final speech = FakeSpeechService()..failure = failure;
  final sentenceController = sentence ?? SentenceController();
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
  final root = Directory.systemTemp.createTempSync('privox_sentence_');
  addTearDown(() => root.deleteSync(recursive: true));

  await tester.pumpWidget(
    AppScope(
      settings: SettingsController(),
      boards: repository,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      speech: speech,
      sentence: sentenceController,
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return _App(speech, sentenceController);
}

Future<void> _openBoard(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

/// Texto DENTRO da barra de frase (os mesmos rótulos também estão na grade).
Finder _inBar(String text) {
  return find.descendant(of: find.byType(SentenceBar), matching: find.text(text));
}

void _setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

IconButton _button(WidgetTester tester, IconData icon) {
  return tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon));
}

void main() {
  group('barra de frase (E5-2)', () {
    testWidgets('vazia: mostra a dica e os botões ficam desativados', (
      tester,
    ) async {
      await _pumpApp(tester, {
        'Casa': [const CardContent(label: 'Água')],
      });
      await _openBoard(tester, 'Casa');

      expect(find.text('Toque nos cards para montar uma frase.'), findsOneWidget);
      expect(_button(tester, Icons.volume_up).onPressed, isNull);
      expect(_button(tester, Icons.backspace_outlined).onPressed, isNull);
      expect(_button(tester, Icons.clear_all).onPressed, isNull);
    });

    testWidgets('tocar nos cards fala cada um e monta a frase na barra', (
      tester,
    ) async {
      final app = await _pumpApp(tester, {
        'Casa': [
          const CardContent(label: 'Eu', speechText: 'Eu quero'),
          const CardContent(label: 'Água'),
        ],
      });
      await _openBoard(tester, 'Casa');

      await tester.tap(find.text('Eu'));
      await tester.pump();
      await tester.tap(find.text('Água'));
      await tester.pump();

      expect(app.speech.spoken, ['Eu quero', 'Água']);
      expect(_inBar('Eu'), findsOneWidget);
      expect(_inBar('Água'), findsOneWidget);
      expect(
        tester.getTopLeft(_inBar('Eu')).dx,
        lessThan(tester.getTopLeft(_inBar('Água')).dx),
      );
      expect(
        find.text('Toque nos cards para montar uma frase.'),
        findsNothing,
      );
    });

    testWidgets('Falar fala a frase inteira, com os textos falados', (
      tester,
    ) async {
      final app = await _pumpApp(tester, {
        'Casa': [
          const CardContent(label: 'Eu', speechText: 'Eu quero'),
          const CardContent(label: 'Água'),
        ],
      });
      await _openBoard(tester, 'Casa');
      await tester.tap(find.text('Eu'));
      await tester.pump();
      await tester.tap(find.text('Água'));
      await tester.pump();

      await tester.tap(find.byTooltip('Falar a frase'));
      await tester.pump();

      expect(app.speech.spoken.last, 'Eu quero Água');
      expect(app.speech.spoken, hasLength(3));
    });

    testWidgets('Apagar tira a última palavra; Limpar tira tudo', (
      tester,
    ) async {
      final app = await _pumpApp(tester, {
        'Casa': [
          const CardContent(label: 'Eu'),
          const CardContent(label: 'Quero'),
          const CardContent(label: 'Água'),
        ],
      });
      await _openBoard(tester, 'Casa');
      for (final label in ['Eu', 'Quero', 'Água']) {
        await tester.tap(find.text(label));
        await tester.pump();
      }
      expect(app.sentence.items, hasLength(3));

      await tester.tap(find.byTooltip('Apagar a última palavra'));
      await tester.pump();
      expect(app.sentence.items.map((i) => i.label), ['Eu', 'Quero']);
      expect(_inBar('Água'), findsNothing);

      await tester.tap(find.byTooltip('Limpar a frase'));
      await tester.pump();
      expect(app.sentence.isEmpty, isTrue);
      expect(find.text('Toque nos cards para montar uma frase.'), findsOneWidget);
      expect(_button(tester, Icons.volume_up).onPressed, isNull);
    });

    testWidgets('em uso, segurar o card age como toque na frase', (
      tester,
    ) async {
      final app = await _pumpApp(tester, {
        'Casa': [const CardContent(label: 'Água')],
      });
      await _openBoard(tester, 'Casa');

      await tester.longPress(find.text('Água'));
      await tester.pumpAndSettle();

      // Soltar o dedo depois de segurar vale como toque (não há toque longo).
      expect(app.sentence.items.map((i) => i.label), ['Água']);
      expect(app.speech.spoken, ['Água']);
    });

    testWidgets('a frase continua ao trocar de prancha', (tester) async {
      final app = await _pumpApp(tester, {
        'Casa': [const CardContent(label: 'Água')],
        'Escola': [const CardContent(label: 'Livro')],
      });
      await _openBoard(tester, 'Casa');
      await tester.tap(find.text('Água'));
      await tester.pump();

      // Volta como a seta da AppBar faria (o pageBack do flutter_test procura
      // o tooltip "Back" em inglês e o app está em português).
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await _openBoard(tester, 'Escola');
      expect(_inBar('Água'), findsOneWidget);

      await tester.tap(find.text('Livro'));
      await tester.pump();

      expect(app.sentence.items.map((i) => i.label), ['Água', 'Livro']);
      expect(_inBar('Livro'), findsOneWidget);
    });

    testWidgets('Falar sem voz em português mostra o aviso', (tester) async {
      final sentence = SentenceController()
        ..add(const SentenceItem(label: 'Oi', speech: 'Oi'));
      await _pumpApp(
        tester,
        {
          'Casa': [const CardContent(label: 'Água')],
        },
        failure: const SpeechException(SpeechErrorKind.voiceUnavailable),
        sentence: sentence,
      );
      await _openBoard(tester, 'Casa');

      await tester.tap(find.byTooltip('Falar a frase'));
      await tester.pump();

      expect(find.textContaining('voz em português do Brasil'), findsOneWidget);
    });

    testWidgets('frase só com itens sem texto não pode ser falada', (
      tester,
    ) async {
      final sentence = SentenceController()
        ..add(const SentenceItem(label: '', speech: ''));
      await _pumpApp(
        tester,
        {
          'Casa': [const CardContent(label: 'Água')],
        },
        sentence: sentence,
      );
      await _openBoard(tester, 'Casa');

      expect(_button(tester, Icons.volume_up).onPressed, isNull);
      expect(_button(tester, Icons.backspace_outlined).onPressed, isNotNull);
    });
  });

  group('barra de frase: layout', () {
    SentenceController longSentence() {
      final controller = SentenceController();
      for (var i = 1; i <= 15; i++) {
        controller.add(SentenceItem(label: 'Palavra $i', speech: 'Palavra $i'));
      }
      return controller;
    }

    for (final (name, size, scale) in [
      ('telefone', const Size(390, 844), 1.0),
      ('tablet', const Size(1280, 800), 1.0),
      ('telefone com texto a 200%', const Size(390, 844), 2.0),
    ]) {
      testWidgets('frase longa rola e mostra a última palavra: $name', (
        tester,
      ) async {
        _setScreen(tester, size);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pumpApp(
          tester,
          {
            'Casa': [const CardContent(label: 'Água')],
          },
          sentence: longSentence(),
        );
        await _openBoard(tester, 'Casa');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final last = tester.getTopRight(_inBar('Palavra 15'));
        expect(last.dx, lessThanOrEqualTo(size.width));
        expect(last.dx, greaterThan(0));
      });
    }

    testWidgets('botões têm alvo de toque de pelo menos 48 dp', (tester) async {
      _setScreen(tester, const Size(390, 844));
      final sentence = SentenceController()
        ..add(const SentenceItem(label: 'Oi', speech: 'Oi'));
      await _pumpApp(
        tester,
        {
          'Casa': [const CardContent(label: 'Água')],
        },
        sentence: sentence,
      );
      await _openBoard(tester, 'Casa');

      for (final icon in [
        Icons.volume_up,
        Icons.backspace_outlined,
        Icons.clear_all,
      ]) {
        final size = tester.getSize(find.widgetWithIcon(IconButton, icon));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });
  });
}