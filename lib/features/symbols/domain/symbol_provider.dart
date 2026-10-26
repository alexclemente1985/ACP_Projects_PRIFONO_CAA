import 'package:prifono_caa/features/symbols/domain/symbol_result.dart';

/// Tamanhos de imagem usados pelo app. O ARASAAC oferece 300, 500 e 2500 px;
/// 2500 é grande demais para um card.
enum SymbolImageSize {
  small(300),
  medium(500);

  const SymbolImageSize(this.pixels);

  final int pixels;
}

enum SymbolErrorKind { offline, timeout, server, badResponse }

/// Falha ao consultar a fonte de símbolos. A UI traduz [kind] em mensagem.
class SymbolProviderException implements Exception {
  const SymbolProviderException(this.kind, [this.detail]);

  final SymbolErrorKind kind;
  final String? detail;

  @override
  String toString() =>
      'SymbolProviderException($kind${detail == null ? '' : ': $detail'})';
}

/// Fonte de símbolos. Isola o app do ARASAAC (ADR-005).
abstract interface class SymbolProvider {
  /// Gravado em SymbolRef.source.
  String get sourceId;

  /// Busca por texto. Por padrão esconde conteúdo sensível.
  /// Sem resultado devolve lista vazia; falha lança [SymbolProviderException].
  Future<List<SymbolResult>> search(
    String text, {
    bool includeSensitive = false,
  });

  /// Endereço da imagem do símbolo. Lança [ArgumentError] se o id for inválido.
  Uri imageUri(
    String symbolId, {
    SymbolImageSize size = SymbolImageSize.medium,
  });
}
