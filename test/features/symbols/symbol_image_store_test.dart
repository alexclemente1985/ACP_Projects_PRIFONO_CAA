import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

const List<int> _png = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  1,
  2,
  3,
];
const SymbolRef _ref = SymbolRef(source: SymbolRef.arasaac, id: '2349');

void main() {
  late Directory root;
  var requests = 0;
  late http.Response Function(http.Request) reply;

  SymbolImageStore buildStore({Duration? timeout}) {
    final client = MockClient((request) async {
      requests++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return reply(request);
    });
    return SymbolImageStore(
      root: root,
      provider: ArasaacProvider(client: client),
      client: client,
      timeout: timeout ?? const Duration(seconds: 5),
    );
  }

  setUp(() {
    requests = 0;
    reply = (_) => http.Response.bytes(_png, 200);
    root = Directory.systemTemp.createTempSync('prifono_store_');
    addTearDown(() => root.deleteSync(recursive: true));
  });

  test('baixa, grava e devolve o arquivo', () async {
    final store = buildStore();

    final file = await store.ensure(_ref);

    expect(file.existsSync(), isTrue);
    expect(file.readAsBytesSync(), _png);
    expect(file.path, endsWith('arasaac/2349_500.png'));
    expect(store.isCached(_ref), isTrue);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('segunda chamada usa o arquivo local, sem rede', () async {
    final store = buildStore();

    await store.ensure(_ref);
    await store.ensure(_ref);

    expect(requests, 1);
  });

  test('downloads simultâneos do mesmo símbolo viram um só', () async {
    final store = buildStore();

    final files = await Future.wait<File>([
      store.ensure(_ref),
      store.ensure(_ref),
    ]);

    expect(requests, 1);
    expect(files.first.path, files.last.path);
  });

  test('conteúdo que não é PNG é rejeitado e nada é gravado', () async {
    reply = (_) => http.Response('<html>erro</html>', 200);
    final store = buildStore();

    await expectLater(
      store.ensure(_ref),
      throwsA(
        isA<SymbolProviderException>().having(
          (e) => e.kind,
          'kind',
          SymbolErrorKind.badResponse,
        ),
      ),
    );
    expect(store.isCached(_ref), isFalse);
  });

  test('HTTP 500 vira erro de servidor', () async {
    reply = (_) => http.Response('x', 500);
    final store = buildStore();

    await expectLater(
      store.ensure(_ref),
      throwsA(
        isA<SymbolProviderException>().having(
          (e) => e.kind,
          'kind',
          SymbolErrorKind.server,
        ),
      ),
    );
  });

  test('id malicioso e fonte desconhecida são recusados', () async {
    final store = buildStore();

    await expectLater(
      store.ensure(const SymbolRef(source: SymbolRef.arasaac, id: '../x')),
      throwsArgumentError,
    );
    await expectLater(
      store.ensure(const SymbolRef(source: 'outra', id: '1')),
      throwsArgumentError,
    );
    expect(requests, 0);
  });

  test('se o download falhar, uma nova tentativa funciona', () async {
    reply = (_) => http.Response('x', 500);
    final store = buildStore();
    await expectLater(
      store.ensure(_ref),
      throwsA(isA<SymbolProviderException>()),
    );

    reply = (_) => http.Response.bytes(_png, 200);
    final file = await store.ensure(_ref);

    expect(file.existsSync(), isTrue);
  });
}
