import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/theme/app_theme.dart';

/// Contraste WCAG entre duas cores opacas.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

// Switch ligado do PIN em Ajustes (E6-6a, ADR-041): o trilho precisa de 3:1
// contra o fundo da tela (componente de interface, WCAG 1.4.11) e o polegar
// precisa de 3:1 contra o trilho, senão "ligado" não se distingue de
// "desligado" para quem enxerga pouco.
void main() {
  final themes = <(String, ThemeData)>[
    ('claro', AppTheme.light),
    ('escuro', AppTheme.dark),
  ];

  for (final (name, theme) in themes) {
    final selected = <WidgetState>{WidgetState.selected};

    test('tema $name: trilho ligado tem 3:1 contra o fundo da tela', () {
      final track = theme.switchTheme.trackColor!.resolve(selected)!;

      expect(
        _contrast(track, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(3),
      );
    });

    test('tema $name: polegar ligado tem 3:1 contra o trilho', () {
      final track = theme.switchTheme.trackColor!.resolve(selected)!;
      final thumb = theme.switchTheme.thumbColor!.resolve(selected)!;

      expect(_contrast(thumb, track), greaterThanOrEqualTo(3));
    });
  }
}
