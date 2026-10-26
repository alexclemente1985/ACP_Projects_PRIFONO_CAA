/// Um símbolo encontrado numa busca, independente da fonte (ADR-005).
final class SymbolResult {
  const SymbolResult({
    required this.id,
    required this.keywords,
    this.isSensitive = false,
  });

  /// Identificador na fonte (para ARASAAC, o número do pictograma).
  final String id;

  /// Palavras associadas, na ordem devolvida pela fonte.
  final List<String> keywords;

  /// Conteúdo marcado pela fonte como sexual ou violento.
  final bool isSensitive;

  /// Texto sugerido para o card.
  String get label => keywords.isEmpty ? '' : keywords.first;
}
