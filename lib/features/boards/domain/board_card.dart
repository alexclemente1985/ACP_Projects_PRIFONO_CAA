import 'package:flutter/foundation.dart';
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
  });

  /// Texto exibido no card.
  final String label;

  /// Texto falado, se diferente do [label].
  final String? speechText;

  final SymbolRef? symbol;

  /// Imagem própria (caminho no armazenamento do app).
  final String? imagePath;

  /// Cor de fundo em ARGB (a UI converte para Color).
  final int? backgroundColor;

  /// Se preenchido, tocar no card abre esse quadro.
  final int? linkBoardId;

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
        other.linkBoardId == linkBoardId;
  }

  @override
  int get hashCode => Object.hash(
        label,
        speechText,
        symbol,
        imagePath,
        backgroundColor,
        linkBoardId,
      );
}

/// Card dentro de uma prancha. Entidade: identificada por [id].
/// (Nome BoardCard para não colidir com o widget Card do Flutter.)
@immutable
class BoardCard {
  const BoardCard({
    required this.id,
    required this.boardId,
    required this.position,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int boardId;
  final int position;
  final CardContent content;
  final DateTime createdAt;
  final DateTime updatedAt;
}