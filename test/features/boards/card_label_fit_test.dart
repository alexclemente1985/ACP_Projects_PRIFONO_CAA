import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/presentation/card_label_fit.dart';

const TextStyle _style = TextStyle(fontWeight: FontWeight.w600);

double _fit(
  String label, {
  required double maxWidth,
  double maxHeight = 200,
  double baseSize = 16,
  TextScaler scaler = TextScaler.noScaling,
}) {
  return CardLabelFit.fitSize(
    label: label,
    style: _style,
    textScaler: scaler,
    textDirection: TextDirection.ltr,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    baseSize: baseSize,
  );
}

/// Largura de uma palavra numa linha só, no tamanho [size].
double _wordWidth(String word, double size) {
  final painter = TextPainter(
    text: TextSpan(text: word, style: _style.copyWith(fontSize: size)),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  group('tamanhos', () {
    test('o tamanho-base cresce com a célula, entre 16 e 26 sp', () {
      expect(CardLabelFit.baseSizeFor(83), 16); // telefone
      expect(CardLabelFit.baseSizeFor(120), closeTo(18, 0.001));
      expect(CardLabelFit.baseSizeFor(300), 26); // tablet
    });

    test('o piso é 75% do tamanho-base', () {
      expect(CardLabelFit.floorSizeFor(16), 12);
      expect(CardLabelFit.floorSizeFor(26), 19.5);
    });
  });

  group('ajuste do rótulo', () {
    testWidgets('palavra curta em caixa folgada fica no tamanho-base', (
      tester,
    ) async {
      expect(_fit('Sim', maxWidth: 300), 16);
    });

    testWidgets('palavra larga demais encolhe, sem passar do piso', (
      tester,
    ) async {
      final narrow = _wordWidth('Grande', 16) * 0.9;

      final size = _fit('Grande', maxWidth: narrow);

      expect(size, lessThan(16));
      expect(size, inInclusiveRange(12, 14.5));
    });

    testWidgets('palavra que não cabe nem no piso devolve o piso', (
      tester,
    ) async {
      expect(_fit('Responsabilidade', maxWidth: 20), 12);
    });

    testWidgets('texto que precisa de mais de 2 linhas devolve o piso', (
      tester,
    ) async {
      final size = _fit(
        'um dois três quatro cinco seis sete oito',
        maxWidth: 100,
        maxHeight: 500,
      );

      expect(size, 12);
    });

    testWidgets('a escala de fonte do sistema entra na conta', (tester) async {
      // Caixa 20% mais larga que a palavra a 100%: a 200% ela não cabe mais.
      final width = _wordWidth('Quero', 16) * 1.2;
      final normal = _fit('Quero', maxWidth: width);
      final doubled = _fit(
        'Quero',
        maxWidth: width,
        scaler: const TextScaler.linear(2),
      );

      expect(normal, 16);
      expect(doubled, lessThan(normal));
      expect(doubled, greaterThanOrEqualTo(12));
    });

    testWidgets('altura de duas linhas acompanha a escala', (tester) async {
      double height(TextScaler scaler) => CardLabelFit.twoLinesHeight(
            style: _style,
            baseSize: 16,
            textScaler: scaler,
            textDirection: TextDirection.ltr,
          );

      final normal = height(TextScaler.noScaling);
      final doubled = height(const TextScaler.linear(2));

      expect(normal, greaterThan(0));
      expect(doubled, closeTo(normal * 2, 2));
    });
  });
}