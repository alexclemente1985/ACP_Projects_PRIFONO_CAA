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