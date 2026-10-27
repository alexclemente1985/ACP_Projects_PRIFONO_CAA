import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/home/home_page.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/splash/splash_page.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

Widget _buildApp(SettingsController settings) {
  // Rede e disco falsos: os testes de widget nunca saem da máquina.
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('prifono_symbols_');
  addTearDown(() => root.deleteSync(recursive: true));
  return AppScope(
    settings: settings,
    symbols: provider,
    symbolImages: SymbolImageStore(root: root, provider: provider),
    child: const PrifonoApp(),
  );
}

/// Sobe o app e espera a splash terminar.
Future<void> _pumpToHome(WidgetTester tester, SettingsController settings) async {
  await tester.pumpWidget(_buildApp(settings));
  await tester.pumpAndSettle();
}

void main() {
  group('splash', () {
    testWidgets('começa na splash e termina na Home', (tester) async {
      await tester.pumpWidget(_buildApp(SettingsController()));
      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(SplashPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('tocar na tela pula a splash', (tester) async {
      await tester.pumpWidget(_buildApp(SettingsController()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(SplashPage));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('com "reduzir movimento" a splash é curta', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      await tester.pumpWidget(_buildApp(SettingsController()));
      await tester.pump(const Duration(milliseconds: 850)); // > 800 ms
      await tester.pump(const Duration(milliseconds: 500)); // transição

      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('home', () {
    testWidgets('mostra a tela inicial em português', (tester) async {
      await _pumpToHome(tester, SettingsController());

      expect(find.text('Laboratório de tema'), findsOneWidget);
      expect(find.text('Cores da marca'), findsOneWidget);
    });

    testWidgets('escolher "Escuro" muda o themeMode do app', (tester) async {
      final settings = SettingsController();
      await _pumpToHome(tester, settings);

      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.dark);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });
  });

  testWidgets('não estoura layout com texto em 200%', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_buildApp(SettingsController()));
    expect(tester.takeException(), isNull); // splash em 200%

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // home em 200%
  });
}