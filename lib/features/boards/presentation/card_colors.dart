import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';

/// Fundo de um card e o texto legível sobre ele.
typedef CardPalette = ({Color background, Color foreground});

/// Cores dos cards: a da classe gramatical (Chave de Fitzgerald, ADR-038) e as
/// regras de contraste que valem para QUALQUER cor guardada no banco.
abstract final class CardColors {
  /// Converte o ARGB guardado em [Color], sempre opaca.
  static Color fromArgb(int argb) => Color(argb | 0xFF000000);

  /// Cor de fundo de cada classe. Tons aprovados em 29/10/2026 (ADR-038); o
  /// texto sobre eles é sempre a tinta, com contraste de 6,8:1 ou mais.
  static Color forWordClass(WordClass wordClass) {
    return switch (wordClass) {
      WordClass.pronoun => const Color(0xFFFFE45C),
      WordClass.verb => const Color(0xFF7ED68B),
      WordClass.noun => const Color(0xFFFFAE57),
      WordClass.adjective => const Color(0xFF79BDF0),
      WordClass.preposition => const Color(0xFFFFB0D0),
      WordClass.question => const Color(0xFFC7A4EE),
      WordClass.negation => const Color(0xFFF2837B),
      WordClass.adverb => const Color(0xFFC79A6A),
      WordClass.conjunction => const Color(0xFFFFFFFF),
      WordClass.determiner => const Color(0xFFC9CED3),
    };
  }

  /// Fundo e texto de um card. Ordem de prioridade (ADR-038):
  /// classe gramatical > cor livre antiga ([legacyArgb]) > cores do tema.
  static CardPalette resolve({
    required Color themeBackground,
    required Color themeForeground,
    WordClass? wordClass,
    int? legacyArgb,
  }) {
    final Color? base;
    if (wordClass != null) {
      base = forWordClass(wordClass);
    } else if (legacyArgb != null) {
      base = fromArgb(legacyArgb);
    } else {
      base = null;
    }
    if (base == null) {
      return (background: themeBackground, foreground: themeForeground);
    }
    return (background: base, foreground: foregroundFor(base));
  }

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
