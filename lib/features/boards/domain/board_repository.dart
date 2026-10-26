import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';

/// Contrato de acesso a pranchas e cards. A UI só conhece esta interface.
abstract interface class BoardRepository {
  /// Pranchas na ordem de exibição.
  Future<List<Board>> listBoards();

  Future<Board?> getBoard(int id);

  /// Cria ao final da lista. Lança [ArgumentError] se nome vazio ou grade
  /// fora de [Board.minGrid]..[Board.maxGrid].
  Future<Board> createBoard({
    required String name,
    int gridColumns = Board.defaultColumns,
    int gridRows = Board.defaultRows,
  });

  /// Atualiza nome e grade. Lança NotFoundException se não existir.
  Future<Board> updateBoard(Board board);

  /// Apaga a prancha e seus cards. Idempotente (apagar de novo não falha).
  Future<void> deleteBoard(int id);

  Future<List<BoardCard>> listCards(int boardId);

  /// Adiciona ao final. Lança NotFoundException se a prancha não existir.
  Future<BoardCard> addCard(int boardId, CardContent content);

  /// Substitui o conteúdo. Lança NotFoundException se não existir.
  Future<BoardCard> updateCard(int cardId, CardContent content);

  /// Idempotente.
  Future<void> deleteCard(int cardId);

  /// Define a nova ordem. [orderedCardIds] deve conter exatamente os cards
  /// da prancha, sem repetir; senão lança [ArgumentError].
  Future<void> reorderCards(int boardId, List<int> orderedCardIds);
}