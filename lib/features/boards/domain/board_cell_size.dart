/// Medidas da grade de cards na tela da prancha (ADR-025, ADR-041 decisão 3).
///
/// A grade ocupa a tela inteira, com margem de [pagePadding] em volta e
/// [gap] entre as células. Estas funções puras dão a largura de cada célula
/// para uma largura de tela. O formulário da prancha usa isso para AVISAR (sem
/// bloquear) quando a célula ficaria menor que [minTouch]; a `BoardPage` usa
/// as mesmas constantes de margem e espaço, para a conta e o desenho nunca
/// divergirem.
///
/// É uma ESTIMATIVA pela largura da tela: ignora recortes de tela (notch) e
/// não olha a altura (telefone deitado: backlog, ver ADR-041).
abstract final class BoardCellSize {
  /// Margem da grade nos quatro lados.
  static const double pagePadding = 16;

  /// Espaço entre duas células vizinhas.
  static const double gap = 8;

  /// Menor lado confortável de um alvo de toque (Android: 48 dp).
  static const double minTouch = 48;

  /// Largura de uma célula numa tela de [screenWidth] dp com [columns] colunas.
  static double widthFor({required double screenWidth, required int columns}) {
    final usable = screenWidth - 2 * pagePadding - gap * (columns - 1);
    return usable / columns;
  }

  /// A célula ficaria menor que [minTouch]?
  static bool isTooSmall({required double screenWidth, required int columns}) {
    return widthFor(screenWidth: screenWidth, columns: columns) < minTouch;
  }

  /// Maior número de colunas que mantém a célula em [minTouch] ou mais (no
  /// mínimo 1).
  static int maxColumnsFor(double screenWidth) {
    final fits =
        ((screenWidth - 2 * pagePadding + gap) / (minTouch + gap)).floor();
    return fits < 1 ? 1 : fits;
  }
}