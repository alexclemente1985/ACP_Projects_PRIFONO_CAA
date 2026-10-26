import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';

/// Resposta JSON em UTF-8 SEM charset no header, de propósito:
/// o provider precisa decodificar UTF-8 mesmo assim.
http.Response _json(Object body, {int status = 200}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, Object?> _picto(
  int id,
  String keyword, {
  bool sex = false,
  bool violence = false,
}) {
  return {
    '_id': id,
    'keywords': [
      {'keyword': keyword, 'type': 2},
    ],
    'sex': sex,
    'violence': violence,
    'schematic': false,
  };
}

ArasaacProvider _providerReplying(http.Response response) {
  return ArasaacProvider(client: MockClient((_) async => response));
}

Matcher _failsWith(SymbolErrorKind kind) {
  return throwsA(
    isA<SymbolProviderException>().having((e) => e.kind, 'kind', kind),
  );
}

void main() {
  group('search', () {
    test('monta a URL oficial com idioma e texto codificado', () async {
      late http.Request captured;
      final provider = ArasaacProvider(
        client: MockClient((request) async {
          captured = request;
          return _json(<Object>[]);
        }),
      );

      await provider.search('ônibus escolar');

      expect(captured.url.scheme, 'https');
      expect(captured.url.host, 'api.arasaac.org');
      expect(
        captured.url.path,
        '/v1/pictograms/br/search/%C3%B4nibus%20escolar',
      );
    });

    test('lê os resultados e preserva acentos', () async {
      final provider = _providerReplying(
        _json([_picto(100, 'água'), _picto(200, 'maçã')]),
      );

      final results = await provider.search('a');

      expect(results.map((r) => r.id), ['100', '200']);
      expect(results.first.label, 'água');
      expect(results.last.label, 'maçã');
    });

    test('esconde conteúdo sensível por padrão', () async {
      final provider = _providerReplying(
        _json([
          _picto(1, 'bola'),
          _picto(2, 'a', sex: true),
          _picto(3, 'b', violence: true),
        ]),
      );

      expect((await provider.search('x')).map((r) => r.id), ['1']);
      expect(
        (await provider.search('x', includeSensitive: true)).length,
        3,
      );
    });

    test('HTTP 404 significa "sem resultado", não erro', () async {
      final provider = _providerReplying(_json(<Object>[], status: 404));

      expect(await provider.search('zzzz'), isEmpty);
    });

    test('HTTP 500 vira erro de servidor', () async {
      final provider = _providerReplying(_json({'message': 'x'}, status: 500));

      await expectLater(
        provider.search('casa'),
        _failsWith(SymbolErrorKind.server),
      );
    });

    test('resposta que não é lista vira badResponse', () async {
      final provider = _providerReplying(_json({'oops': true}));

      await expectLater(
        provider.search('casa'),
        _failsWith(SymbolErrorKind.badResponse),
      );
    });

    test('JSON inválido vira badResponse', () async {
      final provider = _providerReplying(
        http.Response.bytes(utf8.encode('<html>'), 200),
      );

      await expectLater(
        provider.search('casa'),
        _failsWith(SymbolErrorKind.badResponse),
      );
    });

    test('itens malformados são ignorados', () async {
      final provider = _providerReplying(
        _json([
          'texto solto',
          {'sem_id': true},
          {'_id': 'abc'},
          _picto(7, 'gato'),
        ]),
      );

      final results = await provider.search('g');

      expect(results.map((r) => r.id), ['7']);
    });

    test('sem rede vira offline', () async {
      final provider = ArasaacProvider(
        client: MockClient((_) async => throw const SocketException('sem rede')),
      );

      await expectLater(
        provider.search('casa'),
        _failsWith(SymbolErrorKind.offline),
      );
    });

    test('resposta lenta vira timeout', () async {
      final provider = ArasaacProvider(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return _json(<Object>[]);
        }),
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        provider.search('casa'),
        _failsWith(SymbolErrorKind.timeout),
      );
    });

    test('texto vazio não faz requisição', () async {
      var requests = 0;
      final provider = ArasaacProvider(
        client: MockClient((_) async {
          requests++;
          return _json(<Object>[]);
        }),
      );

      expect(await provider.search('   '), isEmpty);
      expect(requests, 0);
    });
  });

  group('imageUri', () {
    final provider = ArasaacProvider(
      client: MockClient((_) async => _json(<Object>[])),
    );

    test('usa o padrão oficial de URL estática', () {
      expect(
        provider.imageUri('2349').toString(),
        'https://static.arasaac.org/pictograms/2349/2349_500.png',
      );
      expect(
        provider.imageUri('2349', size: SymbolImageSize.small).toString(),
        'https://static.arasaac.org/pictograms/2349/2349_300.png',
      );
    });

    test('rejeita ids que não sejam só dígitos', () {
      expect(() => provider.imageUri('../x'), throwsArgumentError);
      expect(() => provider.imageUri(''), throwsArgumentError);
      expect(() => provider.imageUri('12a'), throwsArgumentError);
    });
  });
}