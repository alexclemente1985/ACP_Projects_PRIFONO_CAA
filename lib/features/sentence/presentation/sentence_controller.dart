import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';

/// Estado da frase que a pessoa está montando (ADR-033, E5-2).
///
/// Vive no [AppScope], não na tela da prancha: assim a frase continua ao
/// trocar de prancha. Não é gravada no banco: ao fechar o app a barra volta
/// vazia.
class SentenceController extends ChangeNotifier {
  final List<SentenceItem> _items = [];

  /// Itens na ordem em que foram adicionados (somente leitura).
  List<SentenceItem> get items => UnmodifiableListView(_items);

  bool get isEmpty => _items.isEmpty;

  /// A frase para a voz: os textos falados separados por espaço. Itens sem
  /// texto (só imagem) ficam de fora.
  String get text {
    return _items
        .map((item) => item.speech.trim())
        .where((speech) => speech.isNotEmpty)
        .join(' ');
  }

  /// Há algo para falar? (uma frase só com itens sem texto não tem.)
  bool get canSpeak => text.isNotEmpty;

  void add(SentenceItem item) {
    _items.add(item);
    notifyListeners();
  }

  /// Apaga o último item. Sem itens, não faz nada (e não avisa ninguém).
  void removeLast() {
    if (_items.isEmpty) return;
    _items.removeLast();
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
