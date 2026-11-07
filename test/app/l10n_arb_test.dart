import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Os três arquivos de tradução precisam ter as mesmas chaves e os mesmos
/// parâmetros. Sem este teste, uma chave esquecida só apareceria na tela de
/// quem usa o outro idioma.
Map<String, Object?> _load(String locale) {
  final file = File('lib/app/l10n/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

Set<String> _keys(Map<String, Object?> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

/// Nomes de parâmetros ICU: {nome} ou {nome, plural, ...}.
Set<String> _placeholders(String message) {
  return RegExp(r'\{(\w+)\s*[,}]')
      .allMatches(message)
      .map((match) => match.group(1)!)
      .toSet();
}

void main() {
  final pt = _load('pt');

  for (final locale in ['es', 'en']) {
    group('app_$locale.arb', () {
      final arb = _load(locale);

      test('declara o próprio idioma', () {
        expect(arb['@@locale'], locale);
      });

      test('tem exatamente as mesmas chaves do português', () {
        expect(_keys(arb).difference(_keys(pt)), isEmpty, reason: 'sobrando');
        expect(_keys(pt).difference(_keys(arb)), isEmpty, reason: 'faltando');
      });

      test('nenhum texto vazio', () {
        for (final key in _keys(arb)) {
          expect((arb[key]! as String).trim(), isNotEmpty, reason: key);
        }
      });

      test('mesmos parâmetros em todas as mensagens', () {
        for (final key in _keys(pt)) {
          expect(
            _placeholders(arb[key]! as String),
            _placeholders(pt[key]! as String),
            reason: key,
          );
        }
      });
    });
  }

  test('o português declara o próprio idioma e tem os textos novos', () {
    expect(pt['@@locale'], 'pt');
    expect(_keys(pt), containsAll(['languageSectionTitle', 'languageAutomatic']));
  });

  test('a atribuição oficial do ARASAAC é idêntica nos três idiomas', () {
    // É o texto exigido pelo ARASAAC: não se traduz nem se reescreve.
    final official = pt['creditsArasaacOfficial'];
    expect(_load('es')['creditsArasaacOfficial'], official);
    expect(_load('en')['creditsArasaacOfficial'], official);
  });
}
