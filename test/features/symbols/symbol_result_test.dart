import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_result.dart';

void main() {
  const symbol = SymbolResult(
    id: '2484',
    keywords: ['menina', 'garota', 'criança'],
  );

  test('sem busca, usa a primeira palavra', () {
    expect(symbol.suggestedLabel(''), 'menina');
  });

  test('prefere a palavra exatamente buscada (ignorando maiúsculas)', () {
    expect(symbol.suggestedLabel('Criança'), 'criança');
  });

  test('aceita palavra que contém o texto buscado', () {
    expect(symbol.suggestedLabel('gar'), 'garota');
  });

  test('sem correspondência, volta à primeira palavra', () {
    expect(symbol.suggestedLabel('zzz'), 'menina');
  });

  test('sem palavras, o rótulo é vazio', () {
    expect(const SymbolResult(id: '1', keywords: []).suggestedLabel('x'), '');
  });
}
