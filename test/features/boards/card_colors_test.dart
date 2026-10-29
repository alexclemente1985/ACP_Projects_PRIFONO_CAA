import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/boards/presentation/card_colors.dart';

void main() {
  group('CardColors', () {
    test('texto tem contraste mínimo 4,5:1 sobre as cores da marca', () {
      const backgrounds = <String, Color>{
        'rosa': BrandColors.rosa,
        'azul': BrandColors.azul,
        'bege': BrandColors.bege,
        'branco': BrandColors.branco,
        'fundoEscuro': BrandColors.fundoEscuro,
        'superficieEscura': BrandColors.superficieEscura,
      };
      for (final entry in backgrounds.entries) {
        final foreground = CardColors.foregroundFor(entry.value);
        expect(
          CardColors.contrastRatio(entry.value, foreground),
          greaterThanOrEqualTo(4.5),
          reason: 'contraste insuficiente sobre ${entry.key}',
        );
      }
    });

    test('escolhe tinta sobre cor clara e branco sobre cor escura', () {
      expect(CardColors.foregroundFor(BrandColors.rosa), BrandColors.tinta);
      expect(
        CardColors.foregroundFor(BrandColors.fundoEscuro),
        BrandColors.branco,
      );
    });

    test('fromArgb sempre devolve cor opaca', () {
      expect(CardColors.fromArgb(0x80FBB7C4), const Color(0xFFFBB7C4));
    });
  });

  group('Chave de Fitzgerald (ADR-038)', () {
    test('cada classe tem o tom aprovado', () {
      expect(
        {
          for (final value in WordClass.values)
            value: CardColors.forWordClass(value),
        },
        const {
          WordClass.pronoun: Color(0xFFFFE45C),
          WordClass.verb: Color(0xFF7ED68B),
          WordClass.noun: Color(0xFFFFAE57),
          WordClass.adjective: Color(0xFF79BDF0),
          WordClass.preposition: Color(0xFFFFB0D0),
          WordClass.question: Color(0xFFC7A4EE),
          WordClass.negation: Color(0xFFF2837B),
          WordClass.adverb: Color(0xFFC79A6A),
          WordClass.conjunction: Color(0xFFFFFFFF),
          WordClass.determiner: Color(0xFFC9CED3),
        },
      );
    });

    test('as dez cores são diferentes entre si', () {
      final colors = {
        for (final value in WordClass.values) CardColors.forWordClass(value),
      };

      expect(colors.length, WordClass.values.length);
    });

    test('o texto é a tinta, com contraste mínimo 4,5:1, em todas as classes', () {
      for (final value in WordClass.values) {
        final background = CardColors.forWordClass(value);
        final foreground = CardColors.foregroundFor(background);

        expect(foreground, BrandColors.tinta, reason: '$value');
        expect(
          CardColors.contrastRatio(background, foreground),
          greaterThanOrEqualTo(4.5),
          reason: 'contraste insuficiente em $value',
        );
      }
    });
  });

  group('CardColors.resolve', () {
    const themeBackground = Color(0xFF111111);
    const themeForeground = Color(0xFFEEEEEE);

    test('sem classe e sem cor livre usa as cores do tema', () {
      final palette = CardColors.resolve(
        themeBackground: themeBackground,
        themeForeground: themeForeground,
      );

      expect(palette.background, themeBackground);
      expect(palette.foreground, themeForeground);
    });

    test('a classe vence a cor livre antiga', () {
      final palette = CardColors.resolve(
        wordClass: WordClass.verb,
        legacyArgb: 0xFFFBB7C4,
        themeBackground: themeBackground,
        themeForeground: themeForeground,
      );

      expect(palette.background, const Color(0xFF7ED68B));
      expect(palette.foreground, BrandColors.tinta);
    });

    test('card antigo, sem classe, mantém a cor livre que já tinha', () {
      final palette = CardColors.resolve(
        legacyArgb: 0xFF122A30,
        themeBackground: themeBackground,
        themeForeground: themeForeground,
      );

      expect(palette.background, const Color(0xFF122A30));
      expect(palette.foreground, BrandColors.branco);
    });
  });
}
