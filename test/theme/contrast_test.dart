import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/theme/app_theme.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/core/a11y/contrast.dart';

void main() {
  const textMin = 4.5;
  const uiMin = 3.0;

  void expectScheme(String name, ColorScheme s, Color scaffold) {
    final textPairs = <String, (Color, Color)>{
      'onPrimary/primary': (s.onPrimary, s.primary),
      'onSecondary/secondary': (s.onSecondary, s.secondary),
      'onTertiary/tertiary': (s.onTertiary, s.tertiary),
      'onError/error': (s.onError, s.error),
      'onSurface/surface': (s.onSurface, s.surface),
      'onSurface/scaffold': (s.onSurface, scaffold),
      'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
      'onSurfaceVariant/scaffold': (s.onSurfaceVariant, scaffold),
    };
    textPairs.forEach((label, pair) {
      test('$name texto $label >= $textMin', () {
        expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(textMin));
      });
    });

    test('$name borda/outline >= $uiMin sobre surface e scaffold', () {
      expect(contrastRatio(s.outline, s.surface), greaterThanOrEqualTo(uiMin));
      expect(contrastRatio(s.outline, scaffold), greaterThanOrEqualTo(uiMin));
    });
  }

  group('tema claro', () {
    expectScheme('claro', AppTheme.lightScheme, BrandColors.bege);

    test('azul-forte legível como texto sobre branco e bege', () {
      expect(
        contrastRatio(BrandColors.azulForte, BrandColors.branco),
        greaterThanOrEqualTo(textMin),
      );
      expect(
        contrastRatio(BrandColors.azulForte, BrandColors.bege),
        greaterThanOrEqualTo(textMin),
      );
    });
  });

  group('tema escuro', () {
    expectScheme('escuro', AppTheme.darkScheme, BrandColors.fundoEscuro);

    test('rosa e azul legíveis como texto sobre o fundo escuro', () {
      expect(
        contrastRatio(BrandColors.rosa, BrandColors.fundoEscuro),
        greaterThanOrEqualTo(textMin),
      );
      expect(
        contrastRatio(BrandColors.azul, BrandColors.fundoEscuro),
        greaterThanOrEqualTo(textMin),
      );
    });
  });

  test('regra da marca: rosa e azul NÃO servem de texto sobre branco', () {
    expect(
      contrastRatio(BrandColors.rosa, BrandColors.branco),
      lessThan(textMin),
    );
    expect(
      contrastRatio(BrandColors.azul, BrandColors.branco),
      lessThan(textMin),
    );
  });
}
