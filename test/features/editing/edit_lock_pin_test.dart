import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/a11y/focus_ring_overlay.dart';
import 'package:prifono_caa/features/editing/presentation/edit_lock_button.dart';
import 'package:prifono_caa/features/pin/presentation/pin_dialogs.dart';

import '../../support/pump_editing_app.dart';

Finder get _lockClosed => find.byIcon(Icons.lock_outline);

void main() {
  group('cadeado com PIN: um toque basta', () {
    testWidgets('tocar no cadeado abre o pedido de PIN', (tester) async {
      final app = await pumpEditingApp(
        tester,
        boards: {'Casa': const []},
        pin: '1234',
      );
      expect(find.byType(TapToUnlock), findsOneWidget);
      expect(find.byType(HoldToUnlock), findsNothing);

      await tester.tap(_lockClosed);
      await tester.pumpAndSettle();

      expect(find.byType(PinVerifyDialog), findsOneWidget);
      // O PIN ainda não foi digitado: continua em uso.
      expect(app.editMode.isEditing, isFalse);
    });

    testWidgets('cancelar o pedido de PIN deixa em uso', (tester) async {
      final app = await pumpEditingApp(
        tester,
        boards: {'Casa': const []},
        pin: '1234',
      );
      await tester.tap(_lockClosed);
      await tester.pumpAndSettle();

      // Toca fora do diálogo (a barreira o fecha).
      await tester.tapAt(const Offset(2, 300));
      await tester.pumpAndSettle();

      expect(find.byType(PinVerifyDialog), findsNothing);
      expect(app.editMode.isEditing, isFalse);
    });

    testWidgets('o cadeado de toque também tem pelo menos 48 dp', (
      tester,
    ) async {
      for (final size in const [Size(390, 844), Size(1280, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpEditingApp(tester, boards: {'Casa': const []}, pin: '1234');

        final lock = tester.getSize(find.byType(TapToUnlock));

        expect(lock.width, greaterThanOrEqualTo(48));
        expect(lock.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('ligar o PIN com a tela aberta troca o cadeado', (
      tester,
    ) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      expect(find.byType(HoldToUnlock), findsOneWidget);

      await app.settings.setPin('1234');
      await tester.pump();
      expect(find.byType(TapToUnlock), findsOneWidget);
      expect(find.byType(HoldToUnlock), findsNothing);

      await app.settings.clearPin();
      await tester.pump();
      expect(find.byType(HoldToUnlock), findsOneWidget);
      expect(find.byType(TapToUnlock), findsNothing);
    });
  });

  group('cadeado sem PIN: teclado externo', () {
    testWidgets('Enter no cadeado focado destrava direto', (tester) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      // O foco do detector de teclado do cadeado (o Icon está dentro dele).
      Focus.of(tester.element(_lockClosed)).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(app.editMode.isEditing, isTrue);
      expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
    });

    testWidgets('Espaço no cadeado focado também destrava', (tester) async {
      final app = await pumpEditingApp(tester, boards: {'Casa': const []});
      Focus.of(tester.element(_lockClosed)).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(app.editMode.isEditing, isTrue);
    });

    // E6-5c: desde o E6-5b o anel é o GLOBAL (FocusRingOverlay), não mais um
    // círculo dentro do cadeado.
    testWidgets('o foco por teclado desenha o anel global no cadeado', (
      tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await pumpEditingApp(tester, boards: {'Casa': const []});
      expect(_focusRing(tester), isNull);

      Focus.of(tester.element(_lockClosed)).requestFocus();
      await tester.pumpAndSettle();

      final ring = _focusRing(tester);
      expect(ring, isNotNull);
      expect(ring!.contains(tester.getCenter(_lockClosed)), isTrue);
      expect(ring.width, greaterThanOrEqualTo(48));
      expect(ring.height, greaterThanOrEqualTo(48));
    });
  });
}

/// O último retângulo desenhado pelo anel de foco global (null = sem anel).
Rect? _focusRing(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byKey(FocusRingOverlay.paintKey),
  );
  final painter = paint.foregroundPainter;
  return painter is FocusRingPainter ? painter.lastRing : null;
}
