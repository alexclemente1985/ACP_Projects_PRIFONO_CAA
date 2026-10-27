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

  /// Primeira palavra da fonte.
  String get label => keywords.isEmpty ? '' : keywords.first;

  /// Texto sugerido para o card: a palavra que o usuário buscou, se ela for
  /// uma das palavras do símbolo (ex.: buscou "criança", o símbolo tem
  /// [menina, garota, criança] -> sugere "criança", não "menina").
  String suggestedLabel(String query) {
    final wanted = query.trim().toLowerCase();
    if (wanted.isEmpty) return label;
    for (final keyword in keywords) {
      if (keyword.toLowerCase() == wanted) return keyword;
    }
    for (final keyword in keywords) {
      if (keyword.toLowerCase().contains(wanted)) return keyword;
    }
    return label;
  }
}