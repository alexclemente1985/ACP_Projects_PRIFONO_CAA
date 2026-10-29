import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';

void main() {
  group('SentenceItem e a classe gramatical (E5-4b)', () {
    test('fromContent leva a classe do card', () {
      final item = SentenceItem.fromContent(
        const CardContent(label: 'Eu', wordClass: WordClass.pronoun),
      );

      expect(item.wordClass, WordClass.pronoun);
    });

    test('a classe entra na igualdade', () {
      const a = SentenceItem(
        label: 'Eu',
        speech: 'Eu',
        wordClass: WordClass.pronoun,
      );

      expect(
        a,
        const SentenceItem(
          label: 'Eu',
          speech: 'Eu',
          wordClass: WordClass.pronoun,
        ),
      );
      expect(a == const SentenceItem(label: 'Eu', speech: 'Eu'), isFalse);
    });
  });
}
