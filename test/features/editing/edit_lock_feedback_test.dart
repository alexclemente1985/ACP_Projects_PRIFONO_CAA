import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/theme/app_theme.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/features/boards/presentation/card_colors.dart';
import 'package:prifono_caa/features/editing/presentation/edit_lock_button.dart';

import '../../support/pump_lock_app.dart';

// FEEDBACK AO SEGURAR O CADEADO (E6-4.1 e E6-4.3, ADR-041).
//
// Rode da RAIZ do projeto:
//   flutter test test/features/editing/edit_lock_feedback_test.dart

Finder get _lock => find.byIcon(Icons.lock_outline);
Finder get _track => find.byKey(HoldToUnlock.progressTrackKey);
Finder get _fill => find.byKey(HoldToUnlock.progressFillKey);

/// Registra as vibrações que o app pede ao sistema (texto do tipo, por
/// exemplo "HapticFeedbackType.lightImpact").
List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add('${call.arguments}');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

int _count(List<String> calls, String kind) =>
    calls.where((call) => call.contains(kind)).length;

void main() {
  group('barra de progresso', () {
    testWidgets('cresce do lado do cadeado para o lado oposto', (tester) async {
      await pumpLockApp(tester);
      expect(_track, findsNothing);

      final gesture = await tester.startGesture(tester.getCenter(_lock));
      await tester.pump(); // dá a partida na contagem
      await tester.pump(const Duration(milliseconds: 750)); // metade
      expect(_track, findsOneWidget);
      final half = tester.getRect(_fill);
      expect(half.right, closeTo(390, 0.5), reason: 'começa no lado do cadeado');
      expect(half.width, closeTo(195, 2));

      await tester.pump(const Duration(milliseconds: 375)); // 75%
      final threeQuarters = tester.getRect(_fill);
      expect(threeQuarters.right, closeTo(390, 0.5));
      expect(threeQuarters.width, closeTo(292.5, 2));
      expect(threeQuarters.left, lessThan(half.left));

      await gesture.up();
      await tester.pump();
    });

    testWidgets('fica colada no fundo da AppBar, na lista e na prancha', (
      tester,
    ) async {
      await pumpLockApp(tester);

      Future<void> expectBarAtAppBarBottom() async {
        final gesture = await tester.startGesture(tester.getCenter(_lock));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final bar = tester.getRect(_track);
        final appBar = tester.getRect(find.byType(AppBar));
        expect(bar.bottom, closeTo(appBar.bottom, 0.5));
        expect(bar.height, HoldToUnlock.progressBarHeight);
        expect(bar.width, closeTo(390, 0.5));
        await gesture.up();
        await tester.pump();
      }

      await expectBarAtAppBarBottom();
      await tester.tap(find.text('Casa'));
      await tester.pumpAndSettle();
      await expectBarAtAppBarBottom();
    });

    testWidgets('só existe durante a contagem', (tester) async {
      final editMode = await pumpLockApp(tester);
      expect(_track, findsNothing);

      // Soltar antes de 1,5 s.
      var gesture = await tester.startGesture(tester.getCenter(_lock));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_track, findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(_track, findsNothing);
      expect(editMode.isEditing, isFalse);

      // Contagem completa: some ao completar, mesmo com o dedo ainda embaixo.
      gesture = await tester.startGesture(tester.getCenter(_lock));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      expect(_track, findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(editMode.isEditing, isTrue);
    });
  });

  group('vibração', () {
    testWidgets('leve ao começar a contagem e média ao completar', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await pumpLockApp(tester);
      calls.clear();

      final gesture = await tester.startGesture(tester.getCenter(_lock));
      await tester.pump();
      expect(_count(calls, 'lightImpact'), 1);
      expect(_count(calls, 'mediumImpact'), 0);

      await tester.pump(const Duration(milliseconds: 1600));
      expect(_count(calls, 'lightImpact'), 1);
      expect(_count(calls, 'mediumImpact'), 1);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('soltar antes de completar não dá a vibração do fim', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await pumpLockApp(tester);
      calls.clear();

      final gesture = await tester.startGesture(tester.getCenter(_lock));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();

      expect(_count(calls, 'lightImpact'), 1);
      expect(_count(calls, 'mediumImpact'), 0);
    });
  });

  group('contraste (E6-4.1)', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('anel e barra: pelo menos 3:1 sobre a AppBar (${mode.name})', (
        tester,
      ) async {
        await pumpLockApp(tester, themeMode: mode);
        final gesture = await tester.startGesture(tester.getCenter(_lock));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final appBar = tester.element(find.byType(AppBar));
        final theme = Theme.of(appBar);
        expect(
          theme.brightness,
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          reason: 'o harness precisa trocar o tema',
        );
        final background = theme.appBarTheme.backgroundColor!;
        final ring = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        final fill = tester.widget<ColoredBox>(_fill);

        expect(
          CardColors.contrastRatio(ring.color!, background),
          greaterThanOrEqualTo(3),
          reason: 'anel',
        );
        expect(
          CardColors.contrastRatio(fill.color, background),
          greaterThanOrEqualTo(3),
          reason: 'barra',
        );
        // A cor escolhida: azul forte no claro, bege no escuro.
        final expected = mode == ThemeMode.dark
            ? AppTheme.darkScheme.primary
            : BrandColors.azulForte;
        expect(ring.color, expected);
        expect(fill.color, expected);

        await gesture.up();
        await tester.pump();
      });
    }
  });
}