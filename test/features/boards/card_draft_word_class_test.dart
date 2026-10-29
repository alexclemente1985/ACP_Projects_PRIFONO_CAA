import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/boards/presentation/card_draft_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

CardDraftController _draft({CardContent? initial}) {
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_draft_class_');
  addTearDown(() => root.deleteSync(recursive: true));
  final controller = CardDraftController(
    images: SymbolImageStore(root: root, provider: provider),
    initial: initial,
  );
  addTearDown(controller.dispose);
  return controller;
}

CardContent _build(CardDraftController draft) =>
    draft.buildContent(label: 'Comer', speechText: '');

void main() {
  group('CardDraftController: classe gramatical (E5-4b)', () {
    test('card novo começa sem classe', () {
      final draft = _draft();

      expect(draft.wordClass, isNull);
      expect(_build(draft).wordClass, isNull);
    });

    test('card existente começa com a classe que já tinha', () {
      final draft = _draft(
        initial: const CardContent(label: 'Comer', wordClass: WordClass.verb),
      );

      expect(draft.wordClass, WordClass.verb);
      expect(_build(draft).wordClass, WordClass.verb);
    });

    test('setWordClass troca a classe e vai para o conteúdo salvo', () {
      final draft = _draft()..setWordClass(WordClass.noun);

      expect(draft.wordClass, WordClass.noun);
      expect(_build(draft).wordClass, WordClass.noun);
    });

    test('setWordClass(null) remove a classe', () {
      final draft = _draft(
        initial: const CardContent(label: 'Comer', wordClass: WordClass.verb),
      )..setWordClass(null);

      expect(draft.wordClass, isNull);
      expect(_build(draft).wordClass, isNull);
    });

    test('avisa os ouvintes só quando algo muda', () {
      final draft = _draft();
      var notifications = 0;
      draft.addListener(() => notifications++);

      draft.setWordClass(WordClass.verb);
      expect(notifications, 1);
      draft.setWordClass(WordClass.verb); // igual: nada muda
      expect(notifications, 1);
      draft.setWordClass(null);
      expect(notifications, 2);
    });

    test('card antigo mantém a cor livre se a classe não for mexida', () {
      final draft = _draft(
        initial: const CardContent(label: 'Comer', backgroundColor: 0xFFFBB7C4),
      );

      expect(_build(draft).backgroundColor, 0xFFFBB7C4);
      expect(_build(draft).wordClass, isNull);
    });

    test('escolher uma classe descarta a cor livre antiga', () {
      final draft = _draft(
        initial: const CardContent(label: 'Comer', backgroundColor: 0xFFFBB7C4),
      )..setWordClass(WordClass.verb);

      final content = _build(draft);
      expect(content.wordClass, WordClass.verb);
      expect(content.backgroundColor, isNull);
    });

    test('escolher "Nenhuma" num card de cor livre também descarta a cor', () {
      final draft = _draft(
        initial: const CardContent(label: 'Comer', backgroundColor: 0xFFFBB7C4),
      );
      var notifications = 0;
      draft.addListener(() => notifications++);

      draft.setWordClass(null);

      expect(notifications, 1); // mudou: a cor livre saiu
      expect(_build(draft).backgroundColor, isNull);
      expect(_build(draft).wordClass, isNull);
    });

    test('não mexe no link nem no restante do conteúdo', () {
      final draft = _draft(
        initial: const CardContent(
          label: 'Comer',
          speechText: 'Quero comer',
          imagePath: 'a/b.png',
          linkBoardId: 7,
        ),
      )..setWordClass(WordClass.verb);

      final content = draft.buildContent(
        label: 'Comer',
        speechText: 'Quero comer',
      );
      expect(content.linkBoardId, 7);
      expect(content.imagePath, 'a/b.png');
      expect(content.speechText, 'Quero comer');
    });
  });
}
