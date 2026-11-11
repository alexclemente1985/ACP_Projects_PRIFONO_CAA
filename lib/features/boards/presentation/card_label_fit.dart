import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Tamanho do rótulo do card (ADR-041 decisão 2 e ADR-031).
///
/// O rótulo acompanha a escala de fonte do sistema. O tamanho-base cresce com
/// a célula (tablet) e o texto só encolhe até um PISO de [floorRatio] do
/// base (12 sp quando o base é 16 sp). Antes de quebrar uma palavra no meio,
/// o texto encolhe até o piso. No piso, quebra em até [maxLines] linhas e
/// termina com reticências. A grade continua sem rolagem (ADR-025).
abstract final class CardLabelFit {
  /// Menor tamanho-base, em sp.
  static const double minBaseSize = 16;

  /// Maior tamanho-base, em sp.
  static const double maxBaseSize = 26;

  /// Fração do menor lado da célula que vira tamanho-base.
  static const double baseFactor = 0.15;

  /// O piso é esta fração do tamanho-base (12 / 16).
  static const double floorRatio = 0.75;

  /// Máximo de linhas do rótulo.
  static const int maxLines = 2;

  static final RegExp _spaces = RegExp(r'\s+');

  /// Tamanho-base (sp) para uma célula cujo menor lado mede [cellShortSide].
  static double baseSizeFor(double cellShortSide) {
    return math.min(
      maxBaseSize,
      math.max(minBaseSize, cellShortSide * baseFactor),
    );
  }

  /// Piso (sp) para um tamanho-base.
  static double floorSizeFor(double baseSize) => baseSize * floorRatio;

  /// Altura de [maxLines] linhas no piso: o que o rótulo precisa, no mínimo,
  /// para caber em duas linhas.
  static double twoLinesHeight({
    required TextStyle style,
    required double baseSize,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'Ag\nAg',
        style: style.copyWith(fontSize: floorSizeFor(baseSize)),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// Maior tamanho (sp), de [baseSize] até o piso, em que o rótulo cabe em
  /// [maxWidth] × [maxHeight] sem quebrar palavra no meio e em até [maxLines]
  /// linhas. Se nenhum cabe, devolve o piso.
  static double fitSize({
    required String label,
    required TextStyle style,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required double maxWidth,
    required double maxHeight,
    required double baseSize,
  }) {
    final floor = floorSizeFor(baseSize);
    var size = baseSize;
    while (size > floor) {
      final fits = _fits(
        label: label,
        style: style.copyWith(fontSize: size),
        textScaler: textScaler,
        textDirection: textDirection,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      if (fits) return size;
      size -= 1;
    }
    return floor;
  }

  static bool _fits({
    required String label,
    required TextStyle style,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required double maxWidth,
    required double maxHeight,
  }) {
    // 1) Nenhuma palavra pode ser mais larga que a caixa (senão quebraria).
    for (final word in label.split(_spaces)) {
      if (word.isEmpty) continue;
      final single = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final wordWidth = single.width;
      single.dispose();
      if (wordWidth > maxWidth) return false;
    }
    // 2) O texto inteiro cabe em até `maxLines` linhas e na altura.
    final whole = TextPainter(
      text: TextSpan(text: label, style: style),
      textAlign: TextAlign.center,
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    final ok = !whole.didExceedMaxLines && whole.height <= maxHeight;
    whole.dispose();
    return ok;
  }
}
