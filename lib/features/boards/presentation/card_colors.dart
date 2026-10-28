import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';

/// Cor de fundo dos cards e o texto legível sobre ela.
///
/// A paleta que o usuário escolhe chega no editor (bloco 4); aqui ficam as
/// regras que valem para QUALQUER cor guardada no banco.
abstract final class CardColors {
  /// Converte o ARGB guardado em [Color], sempre opaca.
  static Color fromArgb(int argb) => Color(argb | 0xFF000000);

  /// Tinta ou branco: o que tiver maior contraste com [background].
  static Color foregroundFor(Color background) {
    final withTinta = contrastRatio(background, BrandColors.tinta);
    final withBranco = contrastRatio(background, BrandColors.branco);
    return withTinta >= withBranco ? BrandColors.tinta : BrandColors.branco;
  }

  /// Razão de contraste WCAG entre duas cores (1 a 21).
  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }
}
