import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/about/credits_page.dart';
import 'package:prifono_caa/features/about/privox_mark.dart';

Widget _buildPage({ThemeMode themeMode = ThemeMode.light}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    themeMode: themeMode,
    theme: ThemeData(),
    darkTheme: ThemeData.dark(),
    home: const CreditsPage(),
  );
}

void _setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('CreditsPage', () {
    testWidgets('mostra marca, licença do ARASAAC, autoria e política', (
      tester,
    ) async {
      _setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(_buildPage());

      expect(find.byType(PrivoxMark), findsOneWidget);
      expect(find.text('Sobre e créditos'), findsOneWidget); // título da AppBar
      expect(find.text('Privox'), findsOneWidget);
      expect(find.textContaining('sem conta e sem anúncios'), findsOneWidget);

      expect(find.text('Pictogramas'), findsOneWidget);
      expect(find.textContaining('Los símbolos pictográficos'), findsOneWidget);
      expect(find.textContaining('uso não comercial'), findsOneWidget);
      expect(find.textContaining('mesma licença'), findsOneWidget);

      expect(find.text('Privacidade da busca'), findsOneWidget);

      expect(find.text('Quem faz o Privox'), findsOneWidget);
      expect(find.textContaining('ACP Projects'), findsOneWidget);
      expect(find.textContaining('Priscilla de Sá'), findsOneWidget);

      expect(find.text('Política de privacidade'), findsOneWidget);
      expect(find.text(CreditsPage.privacyPolicyUrl), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('em tablet o conteúdo fica centralizado e limitado', (
      tester,
    ) async {
      _setScreen(tester, const Size(1280, 800));
      await tester.pumpWidget(_buildPage());

      final card = tester.getRect(find.byType(Card).first);
      expect(card.width, lessThanOrEqualTo(CreditsPage.maxContentWidth));
      expect(card.center.dx, closeTo(640, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('não estoura o layout com texto em 200%', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      _setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(_buildPage());
      expect(tester.takeException(), isNull);

      // Chega ao fim da página rolando.
      await tester.ensureVisible(find.text(CreditsPage.privacyPolicyUrl));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('desenha no tema escuro sem erro', (tester) async {
      _setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(_buildPage(themeMode: ThemeMode.dark));

      expect(find.byType(PrivoxMark), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PrivoxMark', () {
    testWidgets('desenha em tamanho pequeno e grande sem erro', (tester) async {
      for (final size in [24.0, 112.0]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: PrivoxMark(size: size)),
          ),
        );
        expect(tester.getSize(find.byType(PrivoxMark)), Size.square(size));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('desenha todos os quadros da animação sem erro', (
      tester,
    ) async {
      for (var step = 0; step <= 20; step++) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: PrivoxMark(progress: step / 20)),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    test('só redesenha quando progresso ou cores mudam', () {
      const base = PrivoxMarkPainter(
        pinkColor: PrivoxMark.defaultPink,
        blueColor: PrivoxMark.defaultBlue,
      );
      const same = PrivoxMarkPainter(
        pinkColor: PrivoxMark.defaultPink,
        blueColor: PrivoxMark.defaultBlue,
      );
      const otherColor = PrivoxMarkPainter(
        pinkColor: PrivoxMark.defaultPink,
        blueColor: Color(0xFF000000),
      );
      const otherProgress = PrivoxMarkPainter(
        pinkColor: PrivoxMark.defaultPink,
        blueColor: PrivoxMark.defaultBlue,
        progress: 0.5,
      );

      const otherFill = PrivoxMarkPainter(
        pinkColor: PrivoxMark.defaultPink,
        blueColor: PrivoxMark.defaultBlue,
        bubbleFillColor: Color(0xFFFFFFFF),
      );

      expect(base.shouldRepaint(same), isFalse);
      expect(base.shouldRepaint(otherFill), isTrue);
      expect(base.shouldRepaint(otherColor), isTrue);
      expect(base.shouldRepaint(otherProgress), isTrue);
    });
  });
}
