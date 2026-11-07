import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';

/// Guarda os endereços pedidos; responde "sem resultado" (404 com lista vazia).
class _Spy {
  final List<Uri> requests = [];

  MockClient get client => MockClient((request) async {
        requests.add(request.url);
        return http.Response('[]', 404);
      });
}

void main() {
  test('sem configuração busca em português do Brasil (br)', () async {
    final spy = _Spy();
    final provider = ArasaacProvider(client: spy.client);

    await provider.search('casa');

    expect(provider.locale, 'br');
    expect(spy.requests.single.path, '/v1/pictograms/br/search/casa');
  });

  test('o locale fixo continua valendo', () async {
    final spy = _Spy();
    final provider = ArasaacProvider(client: spy.client, locale: 'es');

    await provider.search('casa');

    expect(spy.requests.single.path, '/v1/pictograms/es/search/casa');
  });

  test('localeSource é lido a cada busca (trocar o idioma vale na hora)',
      () async {
    final spy = _Spy();
    var language = 'br';
    final provider = ArasaacProvider(
      client: spy.client,
      localeSource: () => language,
    );

    await provider.search('casa');
    language = 'es';
    await provider.search('casa');
    language = 'en';
    await provider.search('house');

    expect(spy.requests.map((uri) => uri.path), [
      '/v1/pictograms/br/search/casa',
      '/v1/pictograms/es/search/casa',
      '/v1/pictograms/en/search/house',
    ]);
  });

  test('localeSource tem prioridade sobre o locale fixo', () async {
    final spy = _Spy();
    final provider = ArasaacProvider(
      client: spy.client,
      locale: 'br',
      localeSource: () => 'en',
    );

    await provider.search('house');

    expect(spy.requests.single.path, '/v1/pictograms/en/search/house');
  });

  test('a imagem não depende do idioma', () {
    final provider = ArasaacProvider(localeSource: () => 'en');

    expect(
      provider.imageUri('2475').toString(),
      contains('/pictograms/2475/2475_'),
    );
  });
}
