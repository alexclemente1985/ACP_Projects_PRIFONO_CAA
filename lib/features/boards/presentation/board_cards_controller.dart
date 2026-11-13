import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_capacity.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_layout.dart';
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

  /// Cards em ordem de leitura: linha e, na mesma linha, coluna (ADR-042).
  /// Lista não modificável.
  List<BoardCard> get cards => _cards;

  int get capacity => BoardCapacity.of(_board.gridColumns, _board.gridRows);

  List<CardPlacement> get _placements => [
        for (final card in _cards) card.placement,
      ];

  /// Células livres da grade (ADR-042: conta células, não cards).
  int get freeCells => BoardLayout.freeCells(
        columns: _board.gridColumns,
        rows: _board.gridRows,
        others: _placements,
      );

  /// Existe ao menos uma célula livre para um card 1×1?
  bool get hasRoom => BoardLayout.hasRoom(
        columns: _board.gridColumns,
        rows: _board.gridRows,
        others: _placements,
      );

  /// Carrega (ou recarrega) os cards. Nunca lança: falha vira `status == error`.
  Future<void> load() async {
    _status = CardsStatus.loading;
    notifyListeners();
    await _reload();
  }

  /// Adiciona um card. Sem [placement], vai para a primeira célula livre e
  /// lança [BoardFullException] se não houver. Com [placement], o repositório
  /// confere (lança [ArgumentError] se não couber ou cobrir outro card).
  Future<void> add(CardContent content, {CardPlacement? placement}) async {
    if (placement == null && !hasRoom) throw BoardFullException(capacity);
    await _write(() async {
      await _repository.addCard(_board.id, content, placement: placement);
    });
  }

  Future<void> update(int cardId, CardContent content) async {
    await _write(() async {
      await _repository.updateCard(cardId, content);
    });
  }

  /// Apaga o card. A posição fica em branco; os outros não se mexem (ADR-042).
  Future<void> delete(int cardId) async {
    await _write(() async {
      await _repository.deleteCard(cardId);
    });
  }

  /// Move o card para ([col], [row]). A tela consulta `BoardLayout.canPlace`
  /// antes, para avisar "Não cabe aí"; o repositório confere de novo.
  Future<void> move(int cardId, {required int col, required int row}) async {
    await _write(() async {
      await _repository.moveCard(cardId, col: col, row: row);
    });
  }

  /// Troca de lugar dois cards da prancha (ADR-042, regra a).
  Future<void> swap(int cardIdA, int cardIdB) async {
    await _write(() async {
      await _repository.swapCards(cardIdA, cardIdB);
    });
  }

  /// Muda a largura e a altura do card; só consome células em branco.
  Future<void> resize(
    int cardId, {
    required int colSpan,
    required int rowSpan,
  }) async {
    await _write(() async {
      await _repository.resizeCard(
        cardId,
        colSpan: colSpan,
        rowSpan: rowSpan,
      );
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
