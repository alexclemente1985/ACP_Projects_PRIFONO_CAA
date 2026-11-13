import 'package:prifono_caa/features/boards/domain/board_card.dart';

/// Regras de posição e tamanho dos cards na grade (ADR-042).
///
/// São funções puras: a regra fica no domínio, não nos repositórios (ADR-021).
/// Os repositórios chamam as versões `require...` (que lançam [ArgumentError]);
/// a tela chama as versões que devolvem `bool`/`null` para avisar "Não cabe
/// aí" ANTES de tentar gravar.
///
/// Em todas, [others] são os OUTROS cards da prancha: quem chama tira da lista
/// o próprio card que está sendo movido ou redimensionado.
abstract final class BoardLayout {
  /// O [placement] está inteiro dentro da grade [columns] × [rows]?
  static bool fits(
    CardPlacement placement, {
    required int columns,
    required int rows,
  }) {
    return placement.col >= 0 &&
        placement.row >= 0 &&
        placement.colSpan >= 1 &&
        placement.rowSpan >= 1 &&
        placement.endCol <= columns &&
        placement.endRow <= rows;
  }

  /// O [placement] não cobre nenhuma célula de [others]?
  static bool isFree(
    CardPlacement placement,
    Iterable<CardPlacement> others,
  ) {
    return !others.any(placement.overlaps);
  }

  /// Cabe na grade E está livre.
  static bool canPlace(
    CardPlacement placement, {
    required int columns,
    required int rows,
    required Iterable<CardPlacement> others,
  }) {
    return fits(placement, columns: columns, rows: rows) &&
        isFree(placement, others);
  }

  /// Como [canPlace], mas lança [ArgumentError] explicando o motivo.
  static void requirePlaceable(
    CardPlacement placement, {
    required int columns,
    required int rows,
    required Iterable<CardPlacement> others,
  }) {
    if (!fits(placement, columns: columns, rows: rows)) {
      throw ArgumentError.value(
        placement,
        'placement',
        'não cabe na grade de $columns × $rows',
      );
    }
    if (!isFree(placement, others)) {
      throw ArgumentError.value(
        placement,
        'placement',
        'cobre outro card da prancha',
      );
    }
  }

  /// Primeira posição livre, em ordem de leitura (linha por linha, da esquerda
  /// para a direita), para um card de [colSpan] × [rowSpan]. `null` se não há.
  static CardPlacement? firstFree({
    required int columns,
    required int rows,
    required Iterable<CardPlacement> others,
    int colSpan = 1,
    int rowSpan = 1,
  }) {
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final candidate = CardPlacement(
          col: col,
          row: row,
          colSpan: colSpan,
          rowSpan: rowSpan,
        );
        if (canPlace(
          candidate,
          columns: columns,
          rows: rows,
          others: others,
        )) {
          return candidate;
        }
      }
    }
    return null;
  }

  /// Ainda existe ao menos uma célula livre para um card 1×1?
  static bool hasRoom({
    required int columns,
    required int rows,
    required Iterable<CardPlacement> others,
  }) {
    return firstFree(columns: columns, rows: rows, others: others) != null;
  }

  /// Quantas células da grade não estão cobertas por nenhum card.
  /// (Cards fora da grade não contam: só as células de dentro são olhadas.)
  static int freeCells({
    required int columns,
    required int rows,
    required Iterable<CardPlacement> others,
  }) {
    var free = 0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        if (isFree(CardPlacement(col: col, row: row), others)) free++;
      }
    }
    return free;
  }

  /// Troca de lugar [a] e [b] (ADR-042, regra a): cada um assume o canto
  /// superior esquerdo do outro e MANTÉM o próprio tamanho. Devolve as duas
  /// novas posições (na ordem `a`, `b`) ou `null` se a troca não é possível:
  /// algum dos dois sairia da grade, cobriria um card de [others] ou os dois
  /// se cobririam.
  static (CardPlacement, CardPlacement)? swap(
    CardPlacement a,
    CardPlacement b, {
    required int columns,
    required int rows,
    required Iterable<CardPlacement> others,
  }) {
    final newA = a.copyWith(col: b.col, row: b.row);
    final newB = b.copyWith(col: a.col, row: a.row);
    if (!canPlace(newA, columns: columns, rows: rows, others: others)) {
      return null;
    }
    if (!canPlace(newB, columns: columns, rows: rows, others: others)) {
      return null;
    }
    if (newA.overlaps(newB)) return null;
    return (newA, newB);
  }

  /// Quantos cards NÃO ficariam inteiros dentro de uma grade [columns] ×
  /// [rows] (ADR-042, regra f). Zero = a mudança de grade é permitida. Um card
  /// que ocupa a linha ou coluna que sairia conta, mesmo que sobrem células.
  static int cardsOutside(
    Iterable<CardPlacement> placements, {
    required int columns,
    required int rows,
  }) {
    return placements
        .where((p) => !fits(p, columns: columns, rows: rows))
        .length;
  }
}
