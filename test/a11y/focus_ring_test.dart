import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/a11y/focus_ring_overlay.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/theme/app_theme.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../support/unlock_edit_mode.dart';

// ANEL DE FOCO (E6-5b, ADR-041). O anel é desenhado por `FocusRingOverlay`;
// estes testes forçam o modo de foco (`FocusManager.highlightStrategy`) em vez
// de depender de teclas, e leem o último retângulo desenhado no painter.

/// Contraste WCAG entre duas cores OPACAS.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Foco "de teclado": o anel aparece. Volta ao automático no fim do teste.
void _useKeyboardFocus() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

/// Foco "de toque": o anel não aparece.
void _useTouchFocus() {
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

/// Sobe o app com a prancha "Casa" (cards "Água" e "Quero"). Com [openBoard],
/// entra nela; senão fica na lista de pranchas.
Future<void> _pumpApp(WidgetTester tester, {bool openBoard = true}) async {
  final boards = InMemoryBoardRepository();
  final board = await boards.createBoard(
    name: 'Casa',
    gridColumns: 3,
    gridRows: 2,
  );
  await boards.addCard(board.id, const CardContent(label: 'Água'));
  await boards.addCard(board.id, const CardContent(label: 'Quero'));

  // Rede, disco e banco falsos: os testes de widget nunca saem da máquina.
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('prifono_focus_');
  addTearDown(() => root.deleteSync(recursive: true));

  await tester.pumpWidget(
    AppScope(
      settings: SettingsController(),
      boards: boards,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle(); // splash
  if (openBoard) {
    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();
  }
}

/// O painter que está desenhando o anel agora.
FocusRingPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byKey(FocusRingOverlay.paintKey),
  );
  return paint.foregroundPainter! as FocusRingPainter;
}

/// Dá o foco ao controle que contém [finder] (o `Focus` mais próximo acima).
Future<void> _focusAround(WidgetTester tester, Finder finder) async {
  Focus.of(tester.element(finder)).requestFocus();
  await tester.pumpAndSettle();
}

void main() {
  group('anel de foco global', () {
    testWidgets('com foco "de toque" nenhum anel é desenhado', (tester) async {
      _useTouchFocus();
      await _pumpApp(tester);

      await _focusAround(tester, find.text('Água'));

      expect(_painter(tester).lastRing, isNull);
    });

    testWidgets('com foco "de teclado" o anel envolve o card em foco', (
      tester,
    ) async {
      _useKeyboardFocus();
      await _pumpApp(tester);

      await _focusAround(tester, find.text('Água'));

      final card = tester.getRect(
        find.ancestor(of: find.text('Água'), matching: find.byType(InkWell)),
      );
      final ring = _painter(tester).lastRing;
      expect(ring, isNotNull);
      expect(
        ring,
        rectMoreOrLessEquals(
          card.inflate(FocusRingOverlay.outset),
          epsilon: 0.5,
        ),
      );
    });

    testWidgets('o anel passa para o outro card quando o foco muda', (
      tester,
    ) async {
      _useKeyboardFocus();
      await _pumpApp(tester);

      await _focusAround(tester, find.text('Água'));
      final first = _painter(tester).lastRing!;
      await _focusAround(tester, find.text('Quero'));
      final second = _painter(tester).lastRing!;

      // Mesma linha, "Quero" à direita de "Água".
      expect(second.top, closeTo(first.top, 0.5));
      expect(second.left, greaterThan(first.left));
    });

    testWidgets('sem o foco, o anel some', (tester) async {
      _useKeyboardFocus();
      await _pumpApp(tester);
      await _focusAround(tester, find.text('Água'));
      expect(_painter(tester).lastRing, isNotNull);

      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();

      expect(_painter(tester).lastRing, isNull);
    });

    testWidgets('o cadeado ganha o anel global (48 dp + folga)', (
      tester,
    ) async {
      _useKeyboardFocus();
      await _pumpApp(tester);

      await _focusAround(tester, find.byIcon(Icons.lock_outline));

      final ring = _painter(tester).lastRing;
      expect(ring, isNotNull);
      const expected = 48 + 2 * FocusRingOverlay.outset;
      expect(ring!.width, closeTo(expected, 0.5));
      expect(ring.height, closeTo(expected, 0.5));
    });

    testWidgets('campo de texto em foco não ganha o anel (tem borda própria)', (
      tester,
    ) async {
      _useKeyboardFocus();
      await _pumpApp(tester, openBoard: false);
      await unlockEditMode(tester);

      await tester.tap(find.text('Nova prancha'));
      await tester.pumpAndSettle();

      // O campo do nome tem `autofocus`.
      expect(find.byType(TextFormField), findsOneWidget);
      expect(_painter(tester).lastRing, isNull);
    });
  });

  group('contraste do foco', () {
    final themes = <(String, ThemeData)>[
      ('claro', AppTheme.light),
      ('escuro', AppTheme.dark),
    ];

    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      test('anel >= 3:1 sobre o fundo da tela e sobre a superfície ($name)', () {
        final ring = scheme.onSurface;
        expect(
          _contrast(ring, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(3),
        );
        expect(_contrast(ring, scheme.surface), greaterThanOrEqualTo(3));
      });

      test('borda do campo de texto em foco >= 3:1 sobre a superfície ($name)', () {
        final border = theme.inputDecorationTheme.focusedBorder;
        expect(border, isNotNull);
        expect(
          _contrast(border!.borderSide.color, scheme.surface),
          greaterThanOrEqualTo(3),
        );
      });

      test('rótulo do campo de texto em foco >= 4,5:1 sobre a superfície ($name)', () {
        final style = WidgetStateProperty.resolveAs<TextStyle?>(
          theme.inputDecorationTheme.floatingLabelStyle,
          {WidgetState.focused},
        );
        expect(style?.color, isNotNull);
        expect(
          _contrast(style!.color!, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}