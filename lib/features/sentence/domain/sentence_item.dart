import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

/// Uma palavra (ou frase curta) da barra de frase. Objeto de valor.
///
/// É uma "foto" do card no momento do toque: se o card for editado ou
/// excluído depois, a frase que já está na barra não muda.
@immutable
class SentenceItem {
  const SentenceItem({
    required this.label,
    required this.speech,
    this.symbol,
    this.backgroundColor,
    this.wordClass,
  });

  /// O que a barra mostra: o mesmo rótulo do card.
  factory SentenceItem.fromContent(CardContent content) {
    return SentenceItem(
      label: content.label,
      speech: content.textToSpeak,
      symbol: content.symbol,
      backgroundColor: content.backgroundColor,
      wordClass: content.wordClass,
    );
  }

  /// Texto exibido na barra.
  final String label;

  /// Texto que entra na fala da frase (o "texto falado" do card, ou o rótulo).
  final String speech;

  final SymbolRef? symbol;

  /// Cor livre LEGADA em ARGB, igual à do card (ADR-038).
  final int? backgroundColor;

  /// Classe gramatical do card: define a cor da ficha (ADR-038).
  final WordClass? wordClass;

  @override
  bool operator ==(Object other) {
    return other is SentenceItem &&
        other.label == label &&
        other.speech == speech &&
        other.symbol == symbol &&
        other.backgroundColor == backgroundColor &&
        other.wordClass == wordClass;
  }

  @override
  int get hashCode =>
      Object.hash(label, speech, symbol, backgroundColor, wordClass);
}
