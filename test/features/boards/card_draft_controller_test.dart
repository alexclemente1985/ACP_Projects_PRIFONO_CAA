import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/card_draft_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

final Uint8List _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  1, 2, 3,
]);

SymbolRef _ref(String id) => SymbolRef(source: SymbolRef.arasaac, id: id);

/// Rede falsa: cada teste decide se está offline e pode segurar a resposta
/// de um pictograma (`gates`) para simular demora.
class _FakeNetwork {
  int requests = 0;
  bool offline = false;
  final Map<String, Completer<void>> gates = {};

  late final MockClient client = MockClient((request) async {
    requests++;
    final id = request.url.pathSegments[1]; // /pictograms/<id>/<id>_500.png
    await gates[id]?.future;
    if (offline) throw http.ClientException('sem rede');
    return http.Response.bytes(_png, 200);
  });
}

CardDraftController _newController(_FakeNetwork network, {CardContent? initial}) {
  final root = Directory.systemTemp.createTempSync('prifono_draft_');
  addTearDown(() => root.deleteSync(recursive: true));
  final provider = ArasaacProvider(client: network.client);
  final store = SymbolImageStore(
    root: root,
    provider: provider,
    client: network.client,
  );
  final controller = CardDraftController(images: store, initial: initial);
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('CardDraftController', () {
    test('card novo começa sem símbolo e pode ser salvo', () {
      final controller = _newController(_FakeNetwork());

      expect(controller.symbol, isNull);
      expect(controller.symbolStatus, SymbolDownloadStatus.none);
      expect(controller.canSave, isTrue);
      expect(controller.imageFile, isNull);
    });

    test('escolher símbolo baixa a imagem e só então libera o salvamento', () async {
      final network = _FakeNetwork()..gates['2265'] = Completer<void>();
      final controller = _newController(network);

      final pending = controller.selectSymbol(_ref('2265'));
      expect(controller.symbolStatus, SymbolDownloadStatus.downloading);
      expect(controller.canSave, isFalse);

      network.gates['2265']!.complete();
      await pending;

      expect(controller.symbolStatus, SymbolDownloadStatus.ready);
      expect(controller.canSave, isTrue);
      expect(controller.symbol, _ref('2265'));
      expect(controller.imageFile!.existsSync(), isTrue);
    });

    test('falha de rede bloqueia o salvamento e tentar de novo recupera', () async {
      final network = _FakeNetwork()..offline = true;
      final controller = _newController(network);

      await controller.selectSymbol(_ref('2265'));

      expect(controller.symbolStatus, SymbolDownloadStatus.failed);
      expect(controller.downloadError, SymbolErrorKind.offline);
      expect(controller.canSave, isFalse);
      expect(controller.imageFile!.existsSync(), isFalse);

      network.offline = false;
      await controller.retryDownload();

      expect(controller.symbolStatus, SymbolDownloadStatus.ready);
      expect(controller.canSave, isTrue);
      expect(controller.downloadError, isNull);
    });

    test('remover o símbolo depois da falha libera salvar só com texto', () async {
      final network = _FakeNetwork()..offline = true;
      final controller = _newController(network);
      await controller.selectSymbol(_ref('2265'));
      expect(controller.canSave, isFalse);

      controller.removeSymbol();

      expect(controller.symbol, isNull);
      expect(controller.symbolStatus, SymbolDownloadStatus.none);
      expect(controller.downloadError, isNull);
      expect(controller.canSave, isTrue);
    });

    test('a escolha mais nova vence a resposta atrasada da anterior', () async {
      final network = _FakeNetwork()..gates['1'] = Completer<void>();
      final controller = _newController(network);

      final first = controller.selectSymbol(_ref('1'));
      await controller.selectSymbol(_ref('2')); // sem espera: termina logo
      expect(controller.symbol, _ref('2'));
      expect(controller.symbolStatus, SymbolDownloadStatus.ready);

      network.gates['1']!.complete();
      await first;

      expect(controller.symbol, _ref('2'));
      expect(controller.symbolStatus, SymbolDownloadStatus.ready);
    });

    test('buildContent normaliza os textos e preserva link e imagem própria', () {
      final initial = CardContent(
        label: 'Velho',
        symbol: _ref('2265'),
        imagePath: '/img/x.png',
        linkBoardId: 7,
      );
      final controller = _newController(_FakeNetwork(), initial: initial)
        ..setBackgroundColor(0xFFFBB7C4);

      final content =
          controller.buildContent(label: '  Água  ', speechText: '   ');

      expect(content.label, 'Água');
      expect(content.speechText, isNull);
      expect(content.symbol, _ref('2265'));
      expect(content.imagePath, '/img/x.png');
      expect(content.linkBoardId, 7);
      expect(content.backgroundColor, 0xFFFBB7C4);

      final withSpeech =
          controller.buildContent(label: 'Água', speechText: ' Quero água ');
      expect(withSpeech.speechText, 'Quero água');
      expect(withSpeech.textToSpeak, 'Quero água');
    });

    test('buildContent lança StateError enquanto baixa', () async {
      final network = _FakeNetwork()..gates['2265'] = Completer<void>();
      final controller = _newController(network);
      final pending = controller.selectSymbol(_ref('2265'));

      expect(
        () => controller.buildContent(label: 'A', speechText: ''),
        throwsStateError,
      );

      network.gates['2265']!.complete();
      await pending;
    });

    test('símbolo que já vinha salvo conta como pronto e não baixa de novo', () {
      final network = _FakeNetwork();
      final controller = _newController(
        network,
        initial: CardContent(label: 'Água', symbol: _ref('2265')),
      );

      expect(controller.symbolStatus, SymbolDownloadStatus.ready);
      expect(controller.canSave, isTrue);
      expect(network.requests, 0);
    });

    test('setBackgroundColor avisa só quando a cor muda', () {
      final controller = _newController(_FakeNetwork());
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setBackgroundColor(0xFFFBB7C4);
      controller.setBackgroundColor(0xFFFBB7C4);
      expect(notifications, 1);

      controller.setBackgroundColor(null);
      expect(notifications, 2);
      expect(controller.backgroundColor, isNull);
    });

    test('dispose no meio do download não lança', () async {
      final network = _FakeNetwork()..gates['2265'] = Completer<void>();
      final controller = _newController(network);
      final pending = controller.selectSymbol(_ref('2265'));

      controller.dispose();
      network.gates['2265']!.complete();

      await pending; // não deve lançar nem notificar depois do dispose
    });
  });
}
