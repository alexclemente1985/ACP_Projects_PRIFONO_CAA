import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';

void main() {
  group('WordClass', () {
    test('as chaves gravadas no banco são estáveis (nunca mudam)', () {
      // Se este teste quebrar, você mudou um valor JÁ PUBLICADO: os cards
      // salvos perderiam a classe. Acrescente classes, não renomeie.
      expect(
        {for (final value in WordClass.values) value: value.key},
        {
          WordClass.pronoun: 'pronoun',
          WordClass.verb: 'verb',
          WordClass.noun: 'noun',
          WordClass.adjective: 'adjective',
          WordClass.preposition: 'preposition',
          WordClass.question: 'question',
          WordClass.negation: 'negation',
          WordClass.adverb: 'adverb',
          WordClass.conjunction: 'conjunction',
          WordClass.determiner: 'determiner',
        },
      );
    });

    test('fromKey devolve a classe de cada chave', () {
      for (final value in WordClass.values) {
        expect(WordClass.fromKey(value.key), value);
      }
    });

    test('chave nula ou desconhecida vira "sem classe"', () {
      expect(WordClass.fromKey(null), isNull);
      expect(WordClass.fromKey(''), isNull);
      expect(WordClass.fromKey('classe_do_futuro'), isNull);
    });
  });

  group('CardContent com classe', () {
    test('a classe entra na igualdade', () {
      const verb = CardContent(label: 'Comer', wordClass: WordClass.verb);

      expect(verb, const CardContent(label: 'Comer', wordClass: WordClass.verb));
      expect(verb == const CardContent(label: 'Comer'), isFalse);
      expect(
        verb == const CardContent(label: 'Comer', wordClass: WordClass.noun),
        isFalse,
      );
      expect(
        verb.hashCode,
        const CardContent(label: 'Comer', wordClass: WordClass.verb).hashCode,
      );
    });

    test('withoutLink tira o link e mantém a classe', () {
      const content = CardContent(
        label: 'Comer',
        linkBoardId: 7,
        wordClass: WordClass.verb,
      );

      final plain = content.withoutLink();

      expect(plain.linkBoardId, isNull);
      expect(plain.wordClass, WordClass.verb);
    });
  });
}
