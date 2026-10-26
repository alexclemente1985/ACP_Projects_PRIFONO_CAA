import 'package:flutter/foundation.dart';

/// Referência a um símbolo de uma fonte externa (ex.: ARASAAC).
/// Guardamos só a referência, nunca uma cópia do arquivo (ADR-005).
@immutable
class SymbolRef {
  const SymbolRef({required this.source, required this.id, this.locale});

  static const String arasaac = 'arasaac';

  final String source;
  final String id;
  final String? locale;

  @override
  bool operator ==(Object other) {
    return other is SymbolRef &&
        other.source == source &&
        other.id == id &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(source, id, locale);
}