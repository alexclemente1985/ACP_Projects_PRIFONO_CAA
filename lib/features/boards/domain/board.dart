import 'package:flutter/foundation.dart';

/// Prancha (quadro) de comunicação. Entidade: identificada por [id].
@immutable
class Board {
  const Board({
    required this.id,
    required this.name,
    required this.gridColumns,
    required this.gridRows,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  static const int minGrid = 1;
  static const int maxGrid = 10;
  static const int defaultColumns = 4;
  static const int defaultRows = 4;

  final int id;
  final String name;
  final int gridColumns;
  final int gridRows;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Regra: o nome é obrigatório (sem espaços nas pontas).
  /// Devolve o nome limpo ou lança [ArgumentError].
  static String checkName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw ArgumentError.value(name, 'name', 'não pode ser vazio');
    }
    return clean;
  }

  /// Regra: a grade fica entre [minGrid] e [maxGrid]. Lança [RangeError].
  static void checkGrid(int columns, int rows) {
    RangeError.checkValueInInterval(columns, minGrid, maxGrid, 'gridColumns');
    RangeError.checkValueInInterval(rows, minGrid, maxGrid, 'gridRows');
  }

  /// Copia alterando só o que o usuário pode editar.
  Board copyWith({String? name, int? gridColumns, int? gridRows}) {
    return Board(
      id: id,
      name: name ?? this.name,
      gridColumns: gridColumns ?? this.gridColumns,
      gridRows: gridRows ?? this.gridRows,
      position: position,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}