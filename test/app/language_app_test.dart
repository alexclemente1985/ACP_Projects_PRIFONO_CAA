import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/settings/data/in_memory_settings_repository.dart';
import 'package:prifono_caa/features/settings/domain/app_language.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

Widget _buildApp(SettingsController settings) {
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('prifono_language_');
  addTearDown(() => root.deleteSync(recursive: true));
  return AppScope(
    settings: settings,
    boards: InMemoryBoardRepository(),
    symbols: provider,
    symbolImages: SymbolImageStore(root: root, provider: provider),
    child: const PrifonoApp(),
  );
}

Future<void> _pump(WidgetTester tester, SettingsController settings) async {
  await tester.pumpWidget(_buildApp(settings));
  await tester.pumpAndSettle();
}

// Mensagem da lista vazia em cada idioma.
const _pt = 'Nenhuma prancha ainda';
const _es = 'Todavía no hay tableros';
const _en = 'No boards yet';

void main() {
  group('idioma do app', () {
    testWidgets('padrão dos testes é português, mesmo com aparelho em inglês', (
      tester,
    ) async {
      // O aparelho de teste está em en_US (ver ADR-034): o idioma é do app.
      await _pump(tester, SettingsController());

      expect(find.text(_pt), findsOneWidget);
    });

    testWidgets('escolha gravada em espanhol abre em espanhol', (tester) async {
      final repository = InMemorySettingsRepository();
      await repository.write(SettingsController.languageKey, 'spanish');
      final settings = SettingsController(repository: repository);
      await settings.load();

      await _pump(tester, settings);

      expect(find.text(_es), findsOneWidget);
    });

    testWidgets('trocar o idioma muda a tela na hora', (tester) async {
      final settings = SettingsController();
      await _pump(tester, settings);
      expect(find.text(_pt), findsOneWidget);

      await settings.setLanguage(AppLanguage.english);
      await tester.pumpAndSettle();

      expect(find.text(_en), findsOneWidget);
      expect(find.text(_pt), findsNothing);
    });
  });

  group('Automático', () {
    testWidgets('segue o idioma do aparelho', (tester) async {
      final settings = SettingsController(
        defaultLanguage: AppLanguage.system,
        deviceLocales: const [Locale('es', 'MX')],
      );

      await _pump(tester, settings);

      expect(find.text(_es), findsOneWidget);
    });

    testWidgets('aparelho em idioma sem tradução abre em inglês', (
      tester,
    ) async {
      final settings = SettingsController(
        defaultLanguage: AppLanguage.system,
        deviceLocales: const [Locale('fr', 'FR')],
      );

      await _pump(tester, settings);

      expect(find.text(_en), findsOneWidget);
    });

    testWidgets('o app avisa o controle quando o idioma do aparelho muda', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final settings = SettingsController(
        defaultLanguage: AppLanguage.system,
        deviceLocales: const [Locale('pt', 'BR')],
      );
      await _pump(tester, settings);
      expect(find.text(_pt), findsOneWidget);

      tester.platformDispatcher.localesTestValue = const [Locale('es', 'ES')];
      await tester.pumpAndSettle();

      expect(find.text(_es), findsOneWidget);
    });
  });

  group('Ajustes: seção Idioma', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Español'));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra Automático e os três idiomas, cada um no seu nome', (
      tester,
    ) async {
      await _pump(tester, SettingsController());

      await openSettings(tester);

      expect(find.text('Automático'), findsOneWidget);
      expect(find.text('Português'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('o idioma em uso aparece selecionado', (tester) async {
      await _pump(tester, SettingsController());
      await openSettings(tester);

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Português'),
      );

      expect(chip.selected, isTrue);
    });

    testWidgets('tocar em English troca a tela de Ajustes na hora', (
      tester,
    ) async {
      final settings = SettingsController();
      await _pump(tester, settings);
      await openSettings(tester);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(settings.language, AppLanguage.english);
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      // Os nomes dos idiomas não são traduzidos.
      expect(find.text('Português'), findsOneWidget);
    });

    testWidgets('Automático volta a seguir o aparelho', (tester) async {
      final settings = SettingsController(
        deviceLocales: const [Locale('es', 'ES')],
      );
      await _pump(tester, settings);
      await openSettings(tester);

      await tester.tap(find.text('Automático'));
      await tester.pumpAndSettle();

      expect(settings.language, AppLanguage.system);
      expect(settings.effectiveLanguage, AppLanguage.spanish);
      expect(
        find.text(
          'El idioma se aplica a la app, a la búsqueda de pictogramas y a la '
          'voz.',
        ),
        findsOneWidget,
      );
    });
  });
}
