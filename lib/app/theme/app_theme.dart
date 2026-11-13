import 'package:flutter/material.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';

/// Tamanho mínimo de alvo de toque. Material pede 48; para CAA, usuários com
/// motricidade reduzida se beneficiam de alvos maiores.
const double kMinTouchTarget = 56;

/// Espessura (dp) da borda de um chip NÃO selecionado e de um selecionado
/// (ADR-041, E6-4.2). A seleção é marcada pela borda grossa (e pela cor), não
/// por ícone de check. As fichas de classe gramatical do editor usam os mesmos
/// valores.
const double kChipBorderWidth = 1.5;
const double kChipSelectedBorderWidth = 4;

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
  /// (TextButton, OutlinedButton), de indicadores de progresso (inclusive o
  /// anel e a barra do cadeado, E6-4.1) e, desde o E6-5b, da borda e do rótulo
  /// de um campo de texto em foco. No tema claro o `primary` é o azul da marca
  /// (#56B2CB), que dá só ~2,4:1 sobre branco e bege: não serve como texto nem
  /// como traço fino (ADR-007 e ADR-041, achado A7). Por isso o tema claro usa o
  /// azul forte (7,17:1 sobre branco). No escuro o azul forte não serve (cerca de
  /// 1,6:1 sobre a superfície azul-noite, conta do Claude): lá a cor é o bege.
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
      // Switch ligado (E6-6a): o trilho padrão usa `primary` (no claro, o azul
      // da marca, ~2,35:1 sobre o fundo; ADR-041, achado lateral do E6-5).
      // Trilho na cor de ação; polegar com contraste sobre ela (branco no
      // claro, onde a `onPrimary` é a tinta e daria ~2,4:1). Desligado e
      // desativado seguem o padrão do Material (devolver null).
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) return null;
          return states.contains(WidgetState.selected) ? action : null;
        }),
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled) ||
              !states.contains(WidgetState.selected)) {
            return null;
          }
          return ThemeData.estimateBrightnessForColor(action) == Brightness.dark
              ? BrandColors.branco
              : scheme.onPrimary;
        }),
      ),
      // Campos de texto (E6-5b): em foco, a borda e o rótulo flutuante usavam
      // `primary` (no claro, o azul da marca, ~2,4:1 sobre branco). O anel de
      // foco global (FocusRingOverlay) NÃO cobre campos de texto: é esta borda
      // que mostra o foco. Rótulo em erro mantém a cor de erro do Material.
      inputDecorationTheme: InputDecorationThemeData(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: action, width: 2),
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) return const TextStyle();
          return states.contains(WidgetState.focused)
              ? TextStyle(color: action)
              : const TextStyle();
        }),
      ),
      // Cores do chip vêm dos padrões do Material 3: selecionado usa
      // secondaryContainer/onSecondaryContainer (pares testados no
      // contrast_test). A SELEÇÃO é marcada pela borda (E6-4.2): grossa e na
      // cor do texto quando selecionado, fina e na cor da borda quando não.
      chipTheme: ChipThemeData(
        side: WidgetStateBorderSide.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return BorderSide(
            color: selected ? scheme.onSurface : scheme.outline,
            width: selected ? kChipSelectedBorderWidth : kChipBorderWidth,
          );
        }),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}