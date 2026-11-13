import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

/// Conteúdo editável de um card. Objeto de valor: igualdade por campos.
@immutable
class CardContent {
  const CardContent({
    this.label = '',
    this.speechText,
    this.symbol,
    this.imagePath,
    this.backgroundColor,
    this.linkBoardId,
    this.wordClass,
  });

  /// Texto exibido no card.
  final String label;

  /// Texto falado, se diferente do [label].
  final String? speechText;

  final SymbolRef? symbol;

  /// Imagem própria (caminho no armazenamento do app).
  final String? imagePath;

  /// Cor de fundo livre em ARGB. LEGADO (ADR-038): o editor não oferece mais
  /// essa escolha, mas cards antigos continuam com a cor que já tinham.
  final int? backgroundColor;

  /// Se preenchido, tocar no card abre esse quadro.
  final int? linkBoardId;

  /// Classe gramatical (Chave de Fitzgerald). Manda na cor do card; `null` =
  /// sem classe (ADR-038).
  final WordClass? wordClass;

  /// O que o TTS deve falar.
  String get textToSpeak {
    final text = speechText?.trim();
    return (text != null && text.isNotEmpty) ? text : label;
  }

  /// Mesmo conteúdo, sem o link para outra prancha.
  CardContent withoutLink() {
    return CardContent(
      label: label,
      speechText: speechText,
      symbol: symbol,
      imagePath: imagePath,
      backgroundColor: backgroundColor,
      wordClass: wordClass,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CardContent &&
        other.label == label &&
        other.speechText == speechText &&
        other.symbol == symbol &&
        other.imagePath == imagePath &&
        other.backgroundColor == backgroundColor &&
        other.linkBoardId == linkBoardId &&
        other.wordClass == wordClass;
  }

  @override
  int get hashCode => Object.hash(
        label,
        speechText,
        symbol,
        imagePath,
        backgroundColor,
        linkBoardId,
        wordClass,
      );
}

/// Onde o card está na grade e quanto espaço ocupa (ADR-042). Objeto de valor.
///
/// [col] e [row] contam a partir de 0, no canto superior esquerdo da prancha.
/// O card cobre [colSpan] colunas × [rowSpan] linhas a partir dessa célula.
/// Este objeto NÃO conhece a grade: quem confere se cabe é o `BoardLayout`.
@immutable
class CardPlacement {
  const CardPlacement({
    required this.col,
    required this.row,
    this.colSpan = 1,
    this.rowSpan = 1,
  });

  final int col;
  final int row;
  final int colSpan;
  final int rowSpan;

  /// Primeira coluna DEPOIS do card (exclusiva).
  int get endCol => col + colSpan;

  /// Primeira linha DEPOIS do card (exclusiva).
  int get endRow => row + rowSpan;

  /// Os dois cobrem alguma célula em comum? (Encostar nas bordas não conta.)
  bool overlaps(CardPlacement other) {
    return col < other.endCol &&
        other.col < endCol &&
        row < other.endRow &&
        other.row < endRow;
  }

  CardPlacement copyWith({int? col, int? row, int? colSpan, int? rowSpan}) {
    return CardPlacement(
      col: col ?? this.col,
      row: row ?? this.row,
      colSpan: colSpan ?? this.colSpan,
      rowSpan: rowSpan ?? this.rowSpan,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CardPlacement &&
        other.col == col &&
        other.row == row &&
        other.colSpan == colSpan &&
        other.rowSpan == rowSpan;
  }

  @override
  int get hashCode => Object.hash(col, row, colSpan, rowSpan);

  @override
  String toString() =>
      'CardPlacement(col: $col, row: $row, colSpan: $colSpan, '
      'rowSpan: $rowSpan)';
}

/// Card dentro de uma prancha. Entidade: identificada por [id].
/// (Nome BoardCard para não colidir com o widget Card do Flutter.)
@immutable
class BoardCard {
  const BoardCard({
    required this.id,
    required this.boardId,
    required this.placement,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int boardId;

  /// Posição e tamanho na grade (ADR-042). Substitui o antigo `position`
  /// (ordem de leitura), que continua no banco só por compatibilidade.
  final CardPlacement placement;
  final CardContent content;
  final DateTime createdAt;
  final DateTime updatedAt;
}
