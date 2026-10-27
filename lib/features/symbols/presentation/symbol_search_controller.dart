import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_result.dart';

enum SymbolSearchStatus { idle, loading, results, empty, error }

/// Estado da tela de busca: espera o usuário parar de digitar (debounce) e
/// descarta respostas atrasadas.
class SymbolSearchController extends ChangeNotifier {
  SymbolSearchController(
    this._provider, {
    this.debounce = const Duration(milliseconds: 400),
  });

  final SymbolProvider _provider;
  final Duration debounce;

  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;

  SymbolSearchStatus _status = SymbolSearchStatus.idle;
  List<SymbolResult> _results = const [];
  SymbolErrorKind? _error;
  String _query = '';

  SymbolSearchStatus get status => _status;
  List<SymbolResult> get results => _results;
  SymbolErrorKind? get error => _error;

  /// Último texto buscado (já sem espaços nas pontas).
  String get query => _query;

  /// Chamado a cada mudança no campo de texto.
  void onQueryChanged(String text) {
    _timer?.cancel();
    if (text.trim().isEmpty) {
      _reset();
      return;
    }
    _timer = Timer(debounce, () => unawaited(search(text)));
  }

  /// Busca agora (ex.: o usuário apertou "buscar" no teclado).
  Future<void> search(String text) async {
    _timer?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      _reset();
      return;
    }

    // Cada busca ganha um número. Se outra começar enquanto esta espera a
    // rede, a resposta desta (já velha) é descartada.
    final generation = ++_generation;
    _query = query;
    _status = SymbolSearchStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final found = await _provider.search(query);
      if (_disposed || generation != _generation) return;
      _results = found;
      _status = found.isEmpty
          ? SymbolSearchStatus.empty
          : SymbolSearchStatus.results;
    } on SymbolProviderException catch (error) {
      if (_disposed || generation != _generation) return;
      _results = const [];
      _error = error.kind;
      _status = SymbolSearchStatus.error;
    }
    notifyListeners();
  }

  void retry() {
    if (_query.isNotEmpty) unawaited(search(_query));
  }

  void _reset() {
    _generation++; // invalida qualquer busca em andamento
    _query = '';
    _results = const [];
    _error = null;
    _status = SymbolSearchStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
