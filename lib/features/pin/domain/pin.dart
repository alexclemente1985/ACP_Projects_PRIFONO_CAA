import 'dart:math';

import 'package:flutter/foundation.dart';

/// Regras do PIN do modo de edição (ADR-040).
abstract final class PinRules {
  /// Quantidade de dígitos.
  static const int length = 4;

  static final RegExp _fourDigits = RegExp(r'^[0-9]{4}$');

  /// PIN válido = exatamente 4 dígitos de 0 a 9.
  static bool isValid(String? pin) => pin != null && _fourDigits.hasMatch(pin);
}

/// Conta de multiplicação da "Esqueci o PIN": um adulto resolve de cabeça, uma
/// criança pequena não. Não é segurança contra ataque (ADR-040).
@immutable
class PinChallenge {
  const PinChallenge({required this.a, required this.b});

  /// Sorteia a conta: a de 12 a 19 e b de 6 a 9 (resposta de 72 a 171).
  factory PinChallenge.random(Random random) {
    return PinChallenge(a: 12 + random.nextInt(8), b: 6 + random.nextInt(4));
  }

  final int a;
  final int b;

  int get answer => a * b;

  /// A resposta digitada confere? Espaços sobrando não atrapalham.
  bool accepts(String typed) => int.tryParse(typed.trim()) == answer;
}
