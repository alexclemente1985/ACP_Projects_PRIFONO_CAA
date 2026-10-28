/// Regras de capacidade da prancha (ADR-025).
///
/// Uma prancha comporta no máximo colunas × linhas cards, sem rolagem.
/// São funções puras: a regra fica no domínio, não nos repositórios (ADR-021).
abstract final class BoardCapacity {
  /// Quantos cards cabem numa grade de [columns] × [rows].
  static int of(int columns, int rows) => columns * rows;

  /// Ainda existe célula livre para mais um card?
  static bool hasRoom({
    required int cardCount,
    required int columns,
    required int rows,
  }) {
    return cardCount < of(columns, rows);
  }

  /// Quantas células ficam livres (nunca negativo).
  static int freeCells({
    required int cardCount,
    required int columns,
    required int rows,
  }) {
    final free = of(columns, rows) - cardCount;
    return free > 0 ? free : 0;
  }

  /// Quantos cards NÃO caberiam se a grade passasse a ser [columns] × [rows].
  /// Zero significa que a mudança é permitida.
  static int overflowAfterResize({
    required int cardCount,
    required int columns,
    required int rows,
  }) {
    final overflow = cardCount - of(columns, rows);
    return overflow > 0 ? overflow : 0;
  }
}

/// Tentativa de adicionar um card a uma prancha já cheia.
class BoardFullException implements Exception {
  const BoardFullException(this.capacity);

  /// Capacidade total da prancha (colunas × linhas).
  final int capacity;

  @override
  String toString() =>
      'BoardFullException: a prancha já tem $capacity cards (capacidade máxima)';
}

/// Tentativa de reduzir a grade abaixo da quantidade de cards existentes.
class BoardGridTooSmallException implements Exception {
  const BoardGridTooSmallException(this.cardsToRemove);

  /// Quantos cards precisam ser removidos antes de reduzir a grade.
  final int cardsToRemove;

  @override
  String toString() =>
      'BoardGridTooSmallException: remova $cardsToRemove cards antes de '
      'reduzir a grade';
}
