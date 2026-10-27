import 'package:prifono_caa/features/symbols/domain/symbol_result.dart';

/// O que a tela de busca devolve quando o usuário escolhe um símbolo.
final class SymbolPick {
  const SymbolPick({required this.symbol, required this.label});

  final SymbolResult symbol;

  /// Texto sugerido para o card.
  final String label;
}