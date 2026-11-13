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
  ///
  /// NÃO confere se os cards cabem na nova grade: quem chama confere antes
  /// (o BoardsController, com `BoardLayout.cardsOutside`; ADR-025/042).
  Future<Board> updateBoard(Board board);

  /// Apaga a prancha e seus cards. Idempotente (apagar de novo não falha).
  Future<void> deleteBoard(int id);

  /// Cards da prancha em ordem de leitura: linha e, na mesma linha, coluna
  /// (ADR-042).
  Future<List<BoardCard>> listCards(int boardId);

  /// Adiciona um card. Lança NotFoundException se a prancha não existir.
  ///
  /// Sem [placement], o card (1×1) vai para a primeira célula livre em ordem
  /// de leitura; se não há célula livre, lança `BoardFullException`. Com
  /// [placement], ele precisa caber na grade e não cobrir outro card; senão
  /// lança [ArgumentError].
  Future<BoardCard> addCard(
    int boardId,
    CardContent content, {
    CardPlacement? placement,
  });

  /// Substitui o conteúdo (não mexe na posição). Lança NotFoundException se
  /// não existir.
  Future<BoardCard> updateCard(int cardId, CardContent content);

  /// Idempotente. A posição fica em branco; os outros cards não se mexem
  /// (ADR-042, regra e).
  Future<void> deleteCard(int cardId);

  /// Move o card para ([col], [row]) mantendo o tamanho. Pode deslizar sobre
  /// a própria área antiga. Lança NotFoundException se o card não existir e
  /// [ArgumentError] se não couber na grade ou cobrir outro card.
  Future<BoardCard> moveCard(
    int cardId, {
    required int col,
    required int row,
  });

  /// Troca de lugar dois cards da MESMA prancha: cada um assume o canto
  /// superior esquerdo do outro e mantém o próprio tamanho (ADR-042, regra a).
  /// Lança NotFoundException se algum não existir e [ArgumentError] se os ids
  /// forem iguais, as pranchas diferentes ou algum dos dois não couber.
  Future<void> swapCards(int cardIdA, int cardIdB);

  /// Muda a largura e a altura mantendo o canto superior esquerdo. Só consome
  /// posições em branco (ADR-042, regra c). Lança NotFoundException se o card
  /// não existir e [ArgumentError] se o tamanho for menor que 1×1, sair da
  /// grade ou cobrir outro card.
  Future<BoardCard> resizeCard(
    int cardId, {
    required int colSpan,
    required int rowSpan,
  });
}
