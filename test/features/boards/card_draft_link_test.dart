import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/card_draft_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

CardDraftController _draft({CardContent? initial}) {
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_draft_link_');
  addTearDown(() => root.deleteSync(recursive: true));
  final controller = CardDraftController(
    images: SymbolImageStore(root: root, provider: provider),
    initial: initial,
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('CardDraftController: link para outra prancha (E5-4)', () {
    test('card novo começa sem link', () {
      final draft = _draft();

      expect(draft.linkBoardId, isNull);
      expect(
        draft.buildContent(label: 'Comer', speechText: '').linkBoardId,
        isNull,
      );
    });

    test('card existente começa com o link que já tinha', () {
      final draft = _draft(
        initial: const CardContent(label: 'Comer', linkBoardId: 7),
      );

      expect(draft.linkBoardId, 7);
      expect(
        draft.buildContent(label: 'Comer', speechText: '').linkBoardId,
        7,
      );
    });

    test('setLinkBoardId troca o destino e vai para o conteúdo salvo', () {
      final draft = _draft(
        initial: const CardContent(label: 'Comer', linkBoardId: 7),
      )..setLinkBoardId(9);

      expect(draft.linkBoardId, 9);
      expect(
        draft.buildContent(label: 'Comer', speechText: '').linkBoardId,
        9,
      );
    });

    test('setLinkBoardId(null) remove o link', () {
      final draft = _draft(
        initial: const CardContent(label: 'Comer', linkBoardId: 7),
      )..setLinkBoardId(null);

      expect(draft.linkBoardId, isNull);
      expect(
        draft.buildContent(label: 'Comer', speechText: '').linkBoardId,
        isNull,
      );
    });

    test('avisa os ouvintes só quando o destino muda', () {
      final draft = _draft();
      var notifications = 0;
      draft.addListener(() => notifications++);

      draft.setLinkBoardId(3);
      expect(notifications, 1);
      draft.setLinkBoardId(3);
      expect(notifications, 1);
      draft.setLinkBoardId(null);
      expect(notifications, 2);
    });
  });
}
