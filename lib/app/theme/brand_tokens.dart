import 'package:flutter/painting.dart';

/// Tokens de cor da marca PRIFONO.
///
/// Fornecidos pelo desenvolvedor: rosa, azul, bege, branco.
/// Derivados (PROPOSTOS, aguardando aprovação): todo o resto, criado
/// apenas para garantir contraste mínimo WCAG AA (4,5:1 texto, 3:1 UI).
abstract final class BrandColors {
  // --- Fornecidas pela marca ---
  static const Color rosa = Color(0xFFFBB7C4);
  static const Color azul = Color(0xFF56B2CB);
  static const Color bege = Color(0xFFFEFEE9);
  static const Color branco = Color(0xFFFFFFFF);

  // --- Derivadas (propostas): tema claro ---
  /// Tinta: texto sobre rosa/azul/bege/branco. 7,05:1 sobre azul.
  static const Color tinta = Color(0xFF1B1B1F);

  /// Azul escuro para texto/ícone/borda sobre fundo claro. 7,17:1 sobre branco.
  static const Color azulForte = Color(0xFF1A5F73);

  static const Color textoSecundarioClaro = Color(0xFF4A4A52); // 8,78:1 s/ branco
  static const Color bordaClaro = Color(0xFF6B6B73); // 5,28:1 s/ branco

  // --- Derivadas (propostas): tema escuro, em azul-noite ---
  // Mesmo matiz (193°) do azul da marca, bem mais escuro.
  static const Color fundoEscuro = Color(0xFF122A30); // bege 14,7:1
  static const Color superficieEscura = Color(0xFF1C3C45); // bege 11,5:1
  static const Color textoSecundarioEscuro = Color(0xFFC3DBE2); // 10,4:1 s/ fundo
  static const Color bordaEscuro = Color(0xFF8FB4C0); // 5,3:1 s/ superfície

  // Erro (funcional, não é da marca).
  static const Color erroClaro = Color(0xFFB3261B); // 6,54:1 com branco
  static const Color sobreErroClaro = Color(0xFFFFFFFF);
  static const Color erroEscuro = Color(0xFFF2B8B5);
  static const Color sobreErroEscuro = Color(0xFF601410); // 7,66:1
}