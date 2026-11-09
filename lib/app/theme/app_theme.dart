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

  /// Escuro em azul-noite: botão principal BEGE com texto azul-noite;
  /// rosa e azul como acentos, sempre com texto azul-noite por cima.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BrandColors.bege,
    onPrimary: BrandColors.fundoEscuro,
    primaryContainer: BrandColors.azul,
    onPrimaryContainer: BrandColors.fundoEscuro,
    secondary: BrandColors.rosa,
    onSecondary: BrandColors.fundoEscuro,
    secondaryContainer: BrandColors.rosa,
    onSecondaryContainer: BrandColors.fundoEscuro,
    tertiary: BrandColors.azul,
    onTertiary: BrandColors.fundoEscuro,
    error: BrandColors.erroEscuro,
    onError: BrandColors.sobreErroEscuro,
    surface: BrandColors.superficieEscura,
    onSurface: BrandColors.bege,
    onSurfaceVariant: BrandColors.textoSecundarioEscuro,
    outline: BrandColors.bordaEscuro,
    outlineVariant: BrandColors.bordaEscuro,
  );

  static ThemeData get light =>
      _build(lightScheme, BrandColors.bege, action: BrandColors.azulForte);

  static ThemeData get dark =>
      _build(darkScheme, BrandColors.fundoEscuro, action: darkScheme.primary);

  /// [action] é a cor de TEXTO e ícone de botões sem preenchimento
  /// (TextButton, OutlinedButton) e de indicadores de progresso. No tema claro
  /// o `primary` é o azul da marca (#56B2CB), que dá só ~2,4:1 sobre branco e
  /// bege: não serve como texto (ADR-007 e ADR-041, achado A7). Por isso o
  /// tema claro usa o azul forte (7,17:1 sobre branco).
  static ThemeData _build(
    ColorScheme scheme,
    Color scaffoldBackground, {
    required Color action,
  }) {
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
          foregroundColor: action,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: action),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: action),
      // Cores do chip vêm dos padrões do Material 3: selecionado usa
      // secondaryContainer/onSecondaryContainer (pares testados no contrast_test).
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}