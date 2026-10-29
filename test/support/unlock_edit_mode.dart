import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Segura o cadeado da AppBar por mais que o tempo necessário (1,5 s) e solta:
/// o app entra no modo de edição (E5-3). Há um cadeado fechado na tela.
///
/// (O nome do arquivo não termina em `_test` de propósito: é só um apoio.)
Future<void> unlockEditMode(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byIcon(Icons.lock_outline)),
  );
  // O primeiro quadro só dá a partida na animação (tempo decorrido = 0).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1600));
  await gesture.up();
  await tester.pumpAndSettle();
}
