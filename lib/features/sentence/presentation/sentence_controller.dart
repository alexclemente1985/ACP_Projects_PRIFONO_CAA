import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';

/// Uma entrada da frase: o item e um número que o identifica ENQUANTO ele
/// estiver na frase.
///
/// O [id] existe porque duas palavras iguais ("quero", "quero") são o mesmo
/// [SentenceItem] por valor, mas a tela precisa distingui-las para arrastar,
/// remover e animar a ficha certa (ADR-039).
@immutable
class SentenceEntry {
  const SentenceEntry({required this.id, required this.item});

  final int id;
  final SentenceItem item;
}

/// Estado da frase que a pessoa está montando (ADR-033, E5-2; ADR-039, E5-4c).
///
/// Vive no [AppScope], não na tela da prancha: assim a frase continua ao
/// trocar de prancha. Não é gravada no banco: ao fechar o app a barra volta
/// vazia.
class SentenceController extends ChangeNotifier {
  final List<SentenceEntry> _entries = [];
  int _nextId = 0;

  /// Entradas na ordem da frase (somente leitura).
  List<SentenceEntry> get entries => UnmodifiableListView(_entries);

  /// Itens na ordem da frase (somente leitura).
  List<SentenceItem> get items =>
      List.unmodifiable(_entries.map((entry) => entry.item));

  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  /// A frase para a voz: os textos falados separados por espaço. Itens sem
  /// texto (só imagem) ficam de fora.
  String get text {
    return _entries
        .map((entry) => entry.item.speech.trim())
        .where((speech) => speech.isNotEmpty)
        .join(' ');
  }

  /// Há algo para falar? (uma frase só com itens sem texto não tem.)
  bool get canSpeak => text.isNotEmpty;

  void add(SentenceItem item) {
    _entries.add(SentenceEntry(id: _nextId++, item: item));
    notifyListeners();
  }

  /// Apaga o último item. Sem itens, não faz nada (e não avisa ninguém).
  void removeLast() {
    if (_entries.isEmpty) return;
    _entries.removeLast();
    notifyListeners();
  }

  /// Apaga o item da posição [index], em qualquer lugar da frase. Posição
  /// inexistente: não faz nada (e não avisa ninguém).
  void removeAt(int index) {
    if (index < 0 || index >= _entries.length) return;
    _entries.removeAt(index);
    notifyListeners();
  }

  /// Leva o item da posição [from] para a posição [to], que é a posição FINAL
  /// dele na frase (0 = primeiro). Posições inexistentes ou iguais: não faz
  /// nada (e não avisa ninguém).
  void move(int from, int to) {
    final last = _entries.length - 1;
    if (from < 0 || from > last || to < 0 || to > last || from == to) return;
    _entries.insert(to, _entries.removeAt(from));
    notifyListeners();
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }
}
