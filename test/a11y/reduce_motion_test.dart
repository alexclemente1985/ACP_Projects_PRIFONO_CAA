import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/splash/splash_page.dart';

import '../support/pump_lock_app.dart';
import '../support/unlock_edit_mode.dart';

// "REDUZIR MOVIMENTO" (E6-4, ADR-041).
//
// Com `disableAnimations`, um AnimationController no modo padrão (`normal`)
// encurta a duração. Duas telas dependem de tempo FIXO e usam `preserve`:
// o cadeado (a contagem de 1,5 s é uma proteção) e a splash (marca parada por
// 800 ms). Rode da RAIZ do projeto:
//   flutter test test/a11y/reduce_motion_test.dart

void _reduceMotionOn(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  testWidgets('a splash mostra a marca completa por cerca de 800 ms', (
    tester,
  ) async {
    _reduceMotionOn(tester);
    await pumpLockApp(tester, settle: false);
    await tester.pump(); // dá a partida na animação
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(SplashPage), findsNothing);
    expect(find.text('Casa'), findsOneWidget);
  });

  testWidgets('soltar o cadeado aos 200 ms não destrava a edição', (
    tester,
  ) async {
    _reduceMotionOn(tester);
    final editMode = await pumpLockApp(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.lock_outline)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pump();

    expect(editMode.isEditing, isFalse);
  });

  testWidgets('segurar por mais de 1,5 s ainda destrava', (tester) async {
    _reduceMotionOn(tester);
    final editMode = await pumpLockApp(tester);

    await unlockEditMode(tester);

    expect(editMode.isEditing, isTrue);
  });
}