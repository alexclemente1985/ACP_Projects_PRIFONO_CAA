import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/core/db/app_database.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/data/sqlite_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Garantia do ADR-018: o pictograma ESCOLHIDO fica no aparelho e o card
/// funciona sem internet, inclusive depois de fechar e abrir o app.

const SymbolRef _ref = SymbolRef(source: SymbolRef.arasaac, id: '2265');

/// PNG válido de 1×1 pixel (a store só confere a assinatura PNG).
final List<int> _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

/// Rede que sempre falha, anotando cada tentativa em [requests].
http.Client _offlineClient(List<Uri> requests) {
  return MockClient((request) async {
    requests.add(request.url);
    throw const SocketException('sem rede');
  });
}

Directory _tempDir() {
  final dir = Directory.systemTemp.createTempSync('privox_offline_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

/// Uma "execução" do app: banco, repositório e store sobre as mesmas pastas.
/// Abrir duas sessões em sequência, no mesmo diretório, simula fechar e abrir
/// o app: só o que está no disco sobrevive.
class _Session {
  _Session._(this.database, this.boards, this.images);

  static Future<_Session> open({
    required String dbPath,
    required Directory imagesRoot,
    required http.Client client,
  }) async {
    final database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: dbPath,
    );
    final provider = ArasaacProvider(client: client);
    final images = SymbolImageStore(
      root: imagesRoot,
      provider: provider,
      client: client,
    );
    return _Session._(database, SqliteBoardRepository(database.db), images);
  }

  final AppDatabase database;
  final SqliteBoardRepository boards;
  final SymbolImageStore images;

  Future<void> close() async {
    images.close();
    await database.close();
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  group('dados: o pictograma escolhido sobrevive ao reinício', () {
    test('card e imagem voltam do disco, sem nenhuma requisição', () async {
      final dir = _tempDir();
      final dbPath = p.join(dir.path, AppDatabase.fileName);
      final imagesRoot = Directory(p.join(dir.path, 'symbols'));

      // 1ª execução, COM internet: a pessoa escolhe o pictograma.
      final first = await _Session.open(
        dbPath: dbPath,
        imagesRoot: imagesRoot,
        client: MockClient((_) async => http.Response.bytes(_png, 200)),
      );
      final board = await first.boards.createBoard(name: 'Casa');
      await first.images.ensure(_ref);
      await first.boards.addCard(
        board.id,
        const CardContent(label: 'Água', symbol: _ref),
      );
      await first.close();

      // 2ª execução, SEM internet: tudo novo; só o disco é o mesmo.
      final requests = <Uri>[];
      final second = await _Session.open(
        dbPath: dbPath,
        imagesRoot: imagesRoot,
        client: _offlineClient(requests),
      );
      addTearDown(second.close);

      final cards = await second.boards.listCards(board.id);
      expect(cards, hasLength(1));
      expect(cards.single.content.label, 'Água');
      expect(cards.single.content.symbol, _ref);

      expect(second.images.isCached(_ref), isTrue);
      final file = await second.images.ensure(_ref);
      expect(file.readAsBytesSync(), _png);
      expect(requests, isEmpty);
    });

    test('controle: sem o arquivo, o mesmo pedido tenta a rede e falha', () async {
      final dir = _tempDir();
      final requests = <Uri>[];
      final session = await _Session.open(
        dbPath: p.join(dir.path, AppDatabase.fileName),
        imagesRoot: Directory(p.join(dir.path, 'symbols')),
        client: _offlineClient(requests),
      );
      addTearDown(session.close);

      expect(session.images.isCached(_ref), isFalse);
      await expectLater(
        session.images.ensure(_ref),
        throwsA(isA<SymbolProviderException>()),
      );
      expect(requests, hasLength(1));
    });
  });

  group('tela: a prancha desenha o pictograma do disco, sem rede', () {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final dir = _tempDir();
          final requests = <Uri>[];
          final client = _offlineClient(requests);
          final provider = ArasaacProvider(client: client);
          final images = SymbolImageStore(
            root: dir,
            provider: provider,
            client: client,
          );

          // O arquivo já está no disco (veio de uma execução com internet).
          // Escrita síncrona: E/S assíncrona real não roda no relógio falso.
          final file = images.fileFor(_ref);
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(_png);

          final repository = InMemoryBoardRepository();
          final board = await repository.createBoard(name: 'Casa');
          await repository.addCard(
            board.id,
            const CardContent(label: 'Água', symbol: _ref),
          );

          await tester.pumpWidget(
            AppScope(
              settings: SettingsController(),
              boards: repository,
              symbols: provider,
              symbolImages: images,
              child: const PrifonoApp(),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Casa'));
          await tester.pumpAndSettle();

          expect(find.text('Água'), findsOneWidget);
          final image = tester.widget<Image>(find.byType(Image));
          expect(
            image.image,
            isA<FileImage>().having((i) => i.file.path, 'caminho', file.path),
          );
          expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);
          expect(requests, isEmpty);
          expect(tester.takeException(), isNull);

          // Desmonta a tela e dá um instante de tempo REAL para a leitura do
          // arquivo terminar antes de a pasta temporária ser apagada.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
        },
      );
    }
  });
}
