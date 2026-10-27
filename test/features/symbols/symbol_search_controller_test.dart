import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_result.dart';
import 'package:prifono_caa/features/symbols/presentation/symbol_search_controller.dart';

class _FakeProvider implements SymbolProvider {
  _FakeProvider(this.handler);

  Future<List<SymbolResult>> Function(String text) handler;
  final List<String> calls = [];

  @override
  String get sourceId => 'arasaac';

  @override
  Future<List<SymbolResult>> search(
    String text, {
    bool includeSensitive = false,
  }) {
    calls.add(text);
    return handler(text);
  }

  @override
  Uri imageUri(String symbolId, {SymbolImageSize size = SymbolImageSize.medium}) {
    throw UnimplementedError();
  }
}

const _a = SymbolResult(id: '1', keywords: ['a']);
const _b = SymbolResult(id: '2', keywords: ['b']);

void main() {
  test('busca: loading -> results', () async {
    final provider = _FakeProvider((_) async => [_a]);
    final controller = SymbolSearchController(provider);
    addTearDown(controller.dispose);
    final seen = <SymbolSearchStatus>[];
    controller.addListener(() => seen.add(controller.status));

    await controller.search('casa');

    expect(seen, [SymbolSearchStatus.loading, SymbolSearchStatus.results]);
    expect(controller.results, [_a]);
    expect(controller.query, 'casa');
  });

  test('sem resultado vira empty', () async {
    final controller = SymbolSearchController(_FakeProvider((_) async => []));
    addTearDown(controller.dispose);

    await controller.search('zzz');

    expect(controller.status, SymbolSearchStatus.empty);
  });

  test('erro guarda o tipo e permite tentar de novo', () async {
    var fail = true;
    final provider = _FakeProvider((_) async {
      if (fail) throw const SymbolProviderException(SymbolErrorKind.offline);
      return [_a];
    });
    final controller = SymbolSearchController(provider);
    addTearDown(controller.dispose);

    await controller.search('casa');
    expect(controller.status, SymbolSearchStatus.error);
    expect(controller.error, SymbolErrorKind.offline);

    fail = false;
    controller.retry();
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, SymbolSearchStatus.results);
  });

  test('resposta atrasada de uma busca antiga é descartada', () async {
    final slow = Completer<List<SymbolResult>>();
    final provider = _FakeProvider((text) {
      return text == 'a' ? slow.future : Future.value([_b]);
    });
    final controller = SymbolSearchController(provider);
    addTearDown(controller.dispose);

    final first = controller.search('a'); // fica esperando
    await controller.search('b'); // termina antes
    slow.complete([_a]); // a resposta velha chega por último
    await first;

    expect(controller.results, [_b]);
    expect(controller.query, 'b');
  });

  test('texto vazio volta ao estado inicial sem consultar a fonte', () async {
    final provider = _FakeProvider((_) async => [_a]);
    final controller = SymbolSearchController(provider);
    addTearDown(controller.dispose);

    await controller.search('casa');
    await controller.search('   ');

    expect(controller.status, SymbolSearchStatus.idle);
    expect(provider.calls, ['casa']);
  });

  test('debounce: digitar rápido gera uma única busca', () async {
    final provider = _FakeProvider((_) async => [_a]);
    final controller = SymbolSearchController(
      provider,
      debounce: const Duration(milliseconds: 30),
    );
    addTearDown(controller.dispose);

    controller
      ..onQueryChanged('c')
      ..onQueryChanged('ca')
      ..onQueryChanged('cas');
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(provider.calls, ['cas']);
  });

  test('dispose cancela a busca agendada', () async {
    final provider = _FakeProvider((_) async => [_a]);
    final controller = SymbolSearchController(
      provider,
      debounce: const Duration(milliseconds: 30),
    )..onQueryChanged('casa');

    controller.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(provider.calls, isEmpty);
  });
}
