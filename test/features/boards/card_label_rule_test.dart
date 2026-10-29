import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/presentation/card_label_rule.dart';

void main() {
  group('labelAfterPick', () {
    test('rótulo vazio recebe o texto do pictograma', () {
      expect(
        labelAfterPick(current: '', autoFilled: null, pickLabel: 'água'),
        'água',
      );
    });

    test('só espaços conta como vazio', () {
      expect(
        labelAfterPick(current: '   ', autoFilled: null, pickLabel: 'água'),
        'água',
      );
    });

    test('rótulo ainda igual ao preenchido pelo pictograma anterior troca', () {
      expect(
        labelAfterPick(
          current: 'maçã',
          autoFilled: 'maçã',
          pickLabel: 'banana',
        ),
        'banana',
      );
    });

    test('espaços nas pontas não impedem a troca', () {
      expect(
        labelAfterPick(
          current: ' maçã ',
          autoFilled: 'maçã',
          pickLabel: 'banana',
        ),
        'banana',
      );
    });

    test('rótulo que a pessoa mudou é mantido', () {
      expect(
        labelAfterPick(
          current: 'maçã verde',
          autoFilled: 'maçã',
          pickLabel: 'banana',
        ),
        'maçã verde',
      );
    });

    test('rótulo escrito à mão, sem pictograma anterior, é mantido', () {
      expect(
        labelAfterPick(current: 'Mamãe', autoFilled: null, pickLabel: 'mãe'),
        'Mamãe',
      );
    });
  });
}
