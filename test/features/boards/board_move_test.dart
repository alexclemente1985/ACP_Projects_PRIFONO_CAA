import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_move.dart';

// As decisões de "soltar aqui" do arrastar e do "Mover…" (ADR-042, E6b-3):
// funções puras, sem tela.

CardPlacement _at(int col, int row, [int colSpan = 1, int rowSpan = 1]) {
  return CardPlacement(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
}

BoardCard _card(int id, String label, CardPlacement placement) {
  final now = DateTime(2026, 11, 13);
  return BoardCard(
    id: id,
    boardId: 1,
    placement: placement,
    content: CardContent(label: label),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('toCell (soltar numa posição)', () {
    // 3 × 3:   Big Big  .
    //          Big Big  .
    //           .   .  Small
    final big = _card(1, 'Big', _at(0, 0, 2, 2));
    final small = _card(2, 'Small', _at(2, 2));
    final cards = [big, small];

    MovePlan drop(BoardCard card, int col, int row) {
      return BoardMove.toCell(
        card,
        col: col,
        row: row,
        cards: cards,
        columns: 3,
        rows: 3,
      );
    }

    test('na própria posição não muda nada', () {
      expect(drop(small, 2, 2).kind, MoveKind.unchanged);
      expect(drop(big, 0, 0).kind, MoveKind.unchanged);
    });

    test('numa posição livre move e mantém o tamanho', () {
      final plan = drop(small, 2, 0);
      expect(plan.kind, MoveKind.move);
      expect(plan.target, _at(2, 0));
      expect(plan.canApply, isTrue);
    });

    test('as células do próprio card não atrapalham', () {
      // O 2×2 anda uma coluna: continua cobrindo a coluna 1, que já era dele.
      final plan = drop(big, 1, 0);
      expect(plan.kind, MoveKind.move);
      expect(plan.target, _at(1, 0, 2, 2));
    });

    test('que sairia da grade bloqueia', () {
      final plan = drop(big, 2, 0);
      expect(plan.kind, MoveKind.blocked);
      expect(plan.target, isNull);
      expect(plan.canApply, isFalse);
    });

    test('que cobriria outro card bloqueia', () {
      expect(drop(small, 1, 1).kind, MoveKind.blocked);
    });
  });

  group('onto (soltar sobre outro card)', () {
    test('sobre si mesmo não muda nada', () {
      final a = _card(1, 'A', _at(0, 0));
      final plan = BoardMove.onto(
        a,
        a,
        cards: [a],
        columns: 3,
        rows: 3,
      );
      expect(plan.kind, MoveKind.unchanged);
    });

    test('dois cards 1×1 trocam de lugar', () {
      final a = _card(1, 'A', _at(0, 0));
      final b = _card(2, 'B', _at(2, 0));
      final c = _card(3, 'C', _at(1, 1));
      final plan = BoardMove.onto(
        a,
        b,
        cards: [a, b, c],
        columns: 3,
        rows: 3,
      );
      expect(plan.kind, MoveKind.swap);
      expect(plan.other, b);
      expect(plan.canApply, isTrue);
    });

    test('tamanhos diferentes trocam se os dois cabem', () {
      // 5 × 3: o 2×2 vai para a coluna 3 e o 1×1 para o canto.
      final big = _card(1, 'Big', _at(0, 0, 2, 2));
      final small = _card(2, 'Small', _at(3, 0));
      final plan = BoardMove.onto(
        big,
        small,
        cards: [big, small],
        columns: 5,
        rows: 3,
      );
      expect(plan.kind, MoveKind.swap);
      expect(plan.other, small);
    });

    test('bloqueia se um dos dois sairia da grade', () {
      final big = _card(1, 'Big', _at(0, 0, 2, 2));
      final small = _card(2, 'Small', _at(2, 2));
      final plan = BoardMove.onto(
        small,
        big,
        cards: [big, small],
        columns: 3,
        rows: 3,
      );
      expect(plan.kind, MoveKind.blocked);
      expect(plan.other, isNull);
    });

    test('bloqueia se um terceiro card estaria no caminho', () {
      final big = _card(1, 'Big', _at(0, 0, 2, 2));
      final small = _card(2, 'Small', _at(3, 0));
      final third = _card(3, 'Third', _at(4, 1));
      final plan = BoardMove.onto(
        big,
        small,
        cards: [big, small, third],
        columns: 5,
        rows: 3,
      );
      expect(plan.kind, MoveKind.blocked);
    });
  });

  group('toPosition (escolhida no diálogo "Mover…")', () {
    final big = _card(1, 'Big', _at(0, 0, 2, 2));
    final small = _card(2, 'Small', _at(3, 0));
    final cards = [big, small];

    MovePlan choose(BoardCard card, int col, int row) {
      return BoardMove.toPosition(
        card,
        col: col,
        row: row,
        cards: cards,
        columns: 5,
        rows: 3,
      );
    }

    test('uma posição livre move', () {
      final plan = choose(small, 4, 2);
      expect(plan.kind, MoveKind.move);
      expect(plan.target, _at(4, 2));
    });

    test('QUALQUER célula de outro card troca com ele, não só o canto', () {
      final plan = choose(small, 1, 1);
      expect(plan.kind, MoveKind.swap);
      expect(plan.other, big);
    });

    test('a posição atual não muda nada', () {
      expect(choose(small, 3, 0).kind, MoveKind.unchanged);
    });

    test('uma célula do próprio card (que não é o canto) move o canto', () {
      final plan = choose(big, 1, 1);
      expect(plan.kind, MoveKind.move);
      expect(plan.target, _at(1, 1, 2, 2));
    });

    test('só move ou troca pode ser gravado', () {
      expect(const MovePlan.unchanged().canApply, isFalse);
      expect(const MovePlan.blocked().canApply, isFalse);
      expect(MovePlan.move(_at(1, 1)).canApply, isTrue);
      expect(MovePlan.swap(big).canApply, isTrue);
    });
  });
}
