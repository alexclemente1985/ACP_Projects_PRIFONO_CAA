import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_bar.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_controller.dart';

SentenceController _sentence(List<String> labels) {
  final controller = SentenceController();
  for (final label in labels) {
    controller.add(SentenceItem(label: label, speech: label));
  }
  return controller;
}

/// Só a barra de frase, sem o resto do app (o toque nas fichas e o menu não
/// dependem de pranchas, voz nem banco).
Future<void> _pumpBar(WidgetTester tester, SentenceController controller) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: SentenceBar(controller: controller),
        ),
      ),
    ),
  );
}

List<String> _labels(SentenceController controller) =>
    controller.items.map((item) => item.label).toList();

/// Texto DENTRO do menu da ficha (o rótulo da ficha também está na barra).
Finder _inMenu(String text) {
  return find.descendant(
    of: find.byType(SimpleDialog),
    matching: find.text(text),
  );
}

void main() {
  group('barra de frase: menu da ficha (ADR-039)', () {
    testWidgets('tocar numa ficha do meio oferece remover e mover', (
      tester,
    ) async {
      final controller = _sentence(['Eu', 'Quero', 'Água']);
      await _pumpBar(tester, controller);

      await tester.tap(find.text('Quero'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(_inMenu('Quero'), findsOneWidget); // título do menu
      expect(_inMenu('Remover da frase'), findsOneWidget);
      expect(_inMenu('Mover para a esquerda'), findsOneWidget);
      expect(_inMenu('Mover para a direita'), findsOneWidget);
      expect(_labels(controller), ['Eu', 'Quero', 'Água']); // nada mudou
    });

    testWidgets('remover tira só a ficha escolhida, em qualquer posição', (
      tester,
    ) async {
      final controller = _sentence(['Eu', 'Quero', 'Água']);
      await _pumpBar(tester, controller);

      await tester.tap(find.text('Quero'));
      await tester.pumpAndSettle();
      await tester.tap(_inMenu('Remover da frase'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsNothing);
      expect(_labels(controller), ['Eu', 'Água']);
      expect(find.text('Quero'), findsNothing);
    });

    testWidgets('remover a primeira ficha também funciona', (tester) async {
      final controller = _sentence(['Eu', 'Quero', 'Água']);
      await _pumpBar(tester, controller);

      await tester.tap(find.text('Eu'));
      await tester.pumpAndSettle();
      await tester.tap(_inMenu('Remover da frase'));
      await tester.pumpAndSettle();

      expect(_labels(controller), ['Quero', 'Água']);
    });

    testWidgets('mover para a direita e para a esquerda troca de lugar', (
      tester,
    ) async {
      final controller = _sentence(['Eu', 'Quero', 'Água']);
      await _pumpBar(tester, controller);

      await tester.tap(find.text('Eu'));
      await tester.pumpAndSettle();
      await tester.tap(_inMenu('Mover para a direita'));
      await tester.pumpAndSettle();
      expect(_labels(controller), ['Quero', 'Eu', 'Água']);

      await tester.tap(find.text('Água'));
      await tester.pumpAndSettle();
      await tester.tap(_inMenu('Mover para a esquerda'));
      await tester.pumpAndSettle();
      expect(_labels(controller), ['Quero', 'Água', 'Eu']);
    });

    testWidgets('a primeira não move para a esquerda; a última, para a direita', (
      tester,
    ) async {
      final controller = _sentence(['Eu', 'Quero', 'Água']);
      await _pumpBar(tester, controller);

      await tester.tap(find.text('Eu'));
      await tester.pumpAndSettle();
      expect(_inMenu('Mover para a esquerda'), findsNothing);
      expect(_inMenu('Mover para a direita'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5)); // fecha o menu
      await tester.pumpAndSettle();

      await tester.tap(find.text('Água'));
      await tester.pumpAndSettle();
      expect(_inMenu('Mover para a direita'), findsNothing);
      expect(_inMenu('Mover para a esquerda'), findsOneWidget);
    });

    testWidgets('com uma ficha só, o menu tem só "Remover"', (tester) async {
      final controller = _sentence(['Oi']);
      await _pumpBar(tester, controller);

      await tester.tap(find.text('Oi'));
      await tester.pumpAndSettle();

      expect(_inMenu('Remover da frase'), findsOneWidget);
      expect(_inMenu('Mover para a esquerda'), findsNothing);
      expect(_inMenu('Mover para a direita'), findsNothing);
    });

    testWidgets('fechar o menu sem escolher não muda a frase', (tester) async {
      final controller = _sentence(['Eu', 'Quero']);
      await _pumpBar(tester, controller);

      await tester.tap(find.text('Eu'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5)); // fora do menu
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsNothing);
      expect(_labels(controller), ['Eu', 'Quero']);
    });

    testWidgets('palavras iguais são fichas diferentes: remove só a tocada', (
      tester,
    ) async {
      final controller = _sentence(['Quero', 'Água', 'Quero']);
      await _pumpBar(tester, controller);

      await tester.tap(find.text('Quero').last);
      await tester.pumpAndSettle();
      await tester.tap(_inMenu('Remover da frase'));
      await tester.pumpAndSettle();

      expect(_labels(controller), ['Quero', 'Água']);
    });

    testWidgets('as fichas têm alvo de toque de pelo menos 48 dp', (
      tester,
    ) async {
      final controller = _sentence(['Eu', 'Quero']);
      await _pumpBar(tester, controller);

      final size = tester.getSize(
        find.ancestor(of: find.text('Eu'), matching: find.byType(InkWell)).first,
      );
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });

  group('barra de frase: arrastar para reorganizar (ADR-039)', () {
    Future<void> holdAndDrag(
      WidgetTester tester,
      Finder from,
      Offset delta,
    ) async {
      final gesture = await tester.startGesture(tester.getCenter(from));
      // O arraste só começa depois de segurar a ficha por um tempo.
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      const steps = 10;
      for (var i = 0; i < steps; i++) {
        await gesture.moveBy(delta / steps.toDouble());
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('segurar e arrastar a primeira ficha para o fim', (
      tester,
    ) async {
      final controller = _sentence(['Eu', 'Quero', 'Água']);
      await _pumpBar(tester, controller);

      await holdAndDrag(tester, find.text('Eu'), const Offset(300, 0));

      expect(_labels(controller), ['Quero', 'Água', 'Eu']);
    });

    testWidgets('segurar e arrastar a última ficha para o começo', (
      tester,
    ) async {
      final controller = _sentence(['Eu', 'Quero', 'Água']);
      await _pumpBar(tester, controller);

      await holdAndDrag(tester, find.text('Água'), const Offset(-165, 0));

      expect(_labels(controller), ['Água', 'Eu', 'Quero']);
    });

    testWidgets('tocar rápido não arrasta: só abre o menu', (tester) async {
      final controller = _sentence(['Eu', 'Quero']);
      await _pumpBar(tester, controller);

      await tester.tap(find.text('Eu'));
      await tester.pumpAndSettle();

      expect(_labels(controller), ['Eu', 'Quero']);
      expect(find.byType(SimpleDialog), findsOneWidget);
    });
  });

  group('barra de frase: layout com remoção e arraste', () {
    testWidgets('remover uma ficha de frase longa não estoura o layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final controller =
          _sentence([for (var i = 1; i <= 12; i++) 'Palavra $i']);
      await _pumpBar(tester, controller);
      await tester.pumpAndSettle();

      controller.removeAt(5);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.length, 11);
    });
  });
}
