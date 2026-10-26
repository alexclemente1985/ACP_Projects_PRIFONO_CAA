import 'package:flutter/material.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';

/// Tamanho mínimo de alvo de toque. Material pede 48; para CAA, usuários com
/// motricidade reduzida se beneficiam de alvos maiores.
const double kMinTouchTarget = 56;

abstract final class AppTheme {
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: BrandColors.azul,
    onPrimary: BrandColors.tinta,
    primaryContainer: BrandColors.azul,
    onPrimaryContainer: BrandColors.tinta,
    secondary: BrandColors.rosa,
    onSecondary: BrandColors.tinta,
    secondaryContainer: BrandColors.rosa,
    onSecondaryContainer: BrandColors.tinta,
    tertiary: BrandColors.azulForte,
    onTertiary: BrandColors.branco,
    error: BrandColors.erroClaro,
    onError: BrandColors.sobreErroClaro,
    surface: BrandColors.branco,
    onSurface: BrandColors.tinta,
    onSurfaceVariant: BrandColors.textoSecundarioClaro,
    outline: BrandColors.bordaClaro,
    outlineVariant: BrandColors.bordaClaro,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BrandColors.azul,
    onPrimary: BrandColors.tinta,
    primaryContainer: BrandColors.azul,
    onPrimaryContainer: BrandColors.tinta,
    secondary: BrandColors.rosa,
    onSecondary: BrandColors.tinta,
    secondaryContainer: BrandColors.rosa,
    onSecondaryContainer: BrandColors.tinta,
    tertiary: BrandColors.bege,
    onTertiary: BrandColors.tinta,
    error: BrandColors.erroEscuro,
    onError: BrandColors.sobreErroEscuro,
    surface: BrandColors.superficieEscura,
    onSurface: BrandColors.bege,
    onSurfaceVariant: BrandColors.textoSecundarioEscuro,
    outline: BrandColors.bordaEscuro,
    outlineVariant: BrandColors.bordaEscuro,
  );

  static ThemeData get light => _build(lightScheme, BrandColors.bege);

  static ThemeData get dark => _build(darkScheme, BrandColors.fundoEscuro);

  static ThemeData _build(ColorScheme scheme, Color scaffoldBackground) {
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
    const buttonSize = Size(kMinTouchTarget, kMinTouchTarget);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outline),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 16),
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
      ),
    );
  }
}