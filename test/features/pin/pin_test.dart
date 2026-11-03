import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/pin/domain/pin.dart';

void main() {
  group('PinRules', () {
    test('aceita exatamente 4 dígitos', () {
      expect(PinRules.isValid('1234'), isTrue);
      expect(PinRules.isValid('0000'), isTrue);
      expect(PinRules.isValid('9071'), isTrue);
    });

    test('recusa nulo, vazio, curto, longo e o que não é número', () {
      expect(PinRules.isValid(null), isFalse);
      expect(PinRules.isValid(''), isFalse);
      expect(PinRules.isValid('123'), isFalse);
      expect(PinRules.isValid('12345'), isFalse);
      expect(PinRules.isValid('12a4'), isFalse);
      expect(PinRules.isValid(' 123'), isFalse);
      expect(PinRules.isValid('12-4'), isFalse);
      expect(PinRules.isValid('١٢٣٤'), isFalse); // dígitos árabes
    });

    test('o tamanho do PIN é 4', () {
      expect(PinRules.length, 4);
    });
  });

  group('PinChallenge', () {
    test('a resposta é a × b', () {
      const challenge = PinChallenge(a: 14, b: 6);

      expect(challenge.answer, 84);
    });

    test('aceita a resposta certa, com ou sem espaços', () {
      const challenge = PinChallenge(a: 14, b: 6);

      expect(challenge.accepts('84'), isTrue);
      expect(challenge.accepts(' 84 '), isTrue);
    });

    test('recusa resposta errada, vazia ou que não é número', () {
      const challenge = PinChallenge(a: 14, b: 6);

      expect(challenge.accepts('85'), isFalse);
      expect(challenge.accepts(''), isFalse);
      expect(challenge.accepts('oitenta e quatro'), isFalse);
    });

    test('o sorteio fica nas faixas combinadas (a 12–19, b 6–9)', () {
      final random = Random(42);
      for (var i = 0; i < 500; i++) {
        final challenge = PinChallenge.random(random);

        expect(challenge.a, inInclusiveRange(12, 19));
        expect(challenge.b, inInclusiveRange(6, 9));
        expect(challenge.answer, inInclusiveRange(72, 171));
      }
    });

    test('o sorteio varia', () {
      final random = Random(7);
      final seen = {
        for (var i = 0; i < 100; i++) PinChallenge.random(random).answer,
      };

      expect(seen.length, greaterThan(10));
    });
  });
}
