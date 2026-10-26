import 'package:flutter/painting.dart';

/// Razão de contraste WCAG entre duas cores (1.0 a 21.0).
/// Texto normal exige >= 4.5; texto grande e componentes de UI, >= 3.0.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}