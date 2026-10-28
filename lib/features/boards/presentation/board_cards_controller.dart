import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_repository.dart';

enum CardsStatus { loading, ready, error }

/// Estado dos cards de UMA prancha.
///
/// Depois de toda escrita bem-sucedida, a lista é relida do repositório:
/// a tela sempre mostra o que está salvo, nunca uma cópia que possa divergir.
/// Escritas que falham propagam a exceção para a tela (convenção do projeto).
class BoardCardsController extends ChangeNotifier {
  BoardCardsController(this._repository, {required this._board});

  final BoardRepository _repository;
  final Board _board;

  CardsStatus _status = CardsStatus.loading;
  List<BoardCard> _cards = const [];
  bool _disposed = false;

  Board get board => _board;
  CardsStatus get status => _status;

  /// Cards em ordem de leitura (ADR-026). Lista não modificável.
  List<BoardCard> get cards => _cards;

  int get capacity => BoardCapacity.of(_board.gridColumns, _board.gridRows);

  int get freeCells => BoardCapacity.freeCells(
        cardCount: _cards.length,
        columns: _board.gridColumns,
        rows: _board.gridRows,
      );

  bool get hasRoom => BoardCapacity.hasRoom(
        cardCount: _cards.length,
        columns: _board.gridColumns,
        rows: _board.gridRows,
      );

  /// Carrega (ou recarrega) os cards. Nunca lança: falha vira `status == error`.
  Future<void> load() async {
    _status = CardsStatus.loading;
    notifyListeners();
    await _reload();
  }

  /// Adiciona um card ao final. Lança [BoardFullException] se não houver espaço.
  Future<void> add(CardContent content) async {
    if (!hasRoom) throw BoardFullException(capacity);
    await _write(() async {
      await _repository.addCard(_board.id, content);
    });
  }

  Future<void> update(int cardId, CardContent content) async {
    await _write(() async {
      await _repository.updateCard(cardId, content);
    });
  }

  Future<void> delete(int cardId) async {
    await _write(() async {
      await _repository.deleteCard(cardId);
    });
  }

  Future<void> _write(Future<void> Function() action) async {
    await action(); // se falhar, a exceção sobe e o estado não muda
    await _reload();
  }

  Future<void> _reload() async {
    try {
      final cards = await _repository.listCards(_board.id);
      if (_disposed) return;
      _cards = List.unmodifiable(cards);
      _status = CardsStatus.ready;
    } on Exception {
      if (_disposed) return;
      _status = CardsStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
