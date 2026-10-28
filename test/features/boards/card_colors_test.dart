import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
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
}

