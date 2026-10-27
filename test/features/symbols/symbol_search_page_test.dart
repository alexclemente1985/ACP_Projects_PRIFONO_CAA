import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_pick.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_result.dart';
import 'package:prifono_caa/features/symbols/presentation/symbol_search_page.dart';

class _FakeProvider implements SymbolProvider {
  _FakeProvider(this.handler);

  Future<List<SymbolResult>> Function(String text) handler;
  int calls = 0;

  @override
  String get sourceId => 'arasaac';

  @override
  Future<List<SymbolResult>> search(
    String text, {
    bool includeSensitive = false,
  }) {
    calls++;
    return handler(text);
  }

  @override
  Uri imageUri(String symbolId, {SymbolImageSize size = SymbolImageSize.medium}) {
    return Uri.https('static.arasaac.org', '/pictograms/$symbolId/${symbolId}_300.png');
  }
}

const _results = [
  SymbolResult(id: '1', keywords: ['casa']),
  SymbolResult(id: '2', keywords: ['menina', 'criança']),
];

Widget _app(SymbolProvider provider, {void Function(SymbolPick?)? onResult}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () async {
              final pick = await Navigator.of(context).push<SymbolPick>(
                MaterialPageRoute(
                  builder: (_) => SymbolSearchPage(provider: provider),
                ),
              );
              onResult?.call(pick);
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _typeAndSubmit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra a mensagem inicial e a atribuição ao ARASAAC', (tester) async {
    await tester.pumpWidget(_app(_FakeProvider((_) async => [])));
    await _open(tester);

    expect(find.text('Digite uma palavra para buscar pictogramas.'), findsOneWidget);
    expect(find.textContaining('ARASAAC'), findsOneWidget);
  });

  testWidgets('lista os resultados buscados', (tester) async {
    await tester.pumpWidget(_app(_FakeProvider((_) async => _results)));
    await _open(tester);

    await _typeAndSubmit(tester, 'casa');

    expect(find.text('casa'), findsWidgets);
    expect(find.text('menina'), findsOneWidget);
  });

  testWidgets('sem resultados mostra a mensagem com o termo', (tester) async {
    await tester.pumpWidget(_app(_FakeProvider((_) async => [])));
    await _open(tester);

    await _typeAndSubmit(tester, 'zzz');

    expect(find.textContaining('Nenhum pictograma encontrado'), findsOneWidget);
    expect(find.textContaining('zzz'), findsWidgets);
  });

  testWidgets('erro de rede mostra mensagem e "Tentar de novo" funciona', (tester) async {
    var offline = true;
    final provider = _FakeProvider((_) async {
      if (offline) throw const SymbolProviderException(SymbolErrorKind.offline);
      return _results;
    });
    await tester.pumpWidget(_app(provider));
    await _open(tester);

    await _typeAndSubmit(tester, 'casa');
    expect(find.textContaining('Sem conexão'), findsOneWidget);

    offline = false;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('menina'), findsOneWidget);
    expect(provider.calls, 2);
  });

  testWidgets('tocar num resultado devolve a escolha com o texto buscado', (tester) async {
    SymbolPick? picked;
    await tester.pumpWidget(
      _app(
        _FakeProvider((_) async => _results),
        onResult: (pick) => picked = pick,
      ),
    );
    await _open(tester);
    await _typeAndSubmit(tester, 'criança');

    await tester.tap(find.text('menina'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.symbol.id, '2');
    expect(picked!.label, 'criança'); // o que o usuário buscou, não "menina"
  });
}
