import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/editing/presentation/edit_mode_controller.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../../support/unlock_edit_mode.dart';

class _App {
  _App(this.settings, this.editMode);

  final SettingsController settings;
  final EditModeController editMode;
}

/// Sobe o app com a prancha "Casa" e fica na lista de pranchas. Com [pin], o
/// PIN já está ligado.
Future<_App> _pumpApp(WidgetTester tester, {String? pin}) async {
  final settings = SettingsController();
  if (pin != null) await settings.setPin(pin);
  final editMode = EditModeController();
  final repository = InMemoryBoardRepository();
  final board = await repository.createBoard(name: 'Casa');
  await repository.addCard(board.id, const CardContent(label: 'Água'));
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('privox_pin_');
  addTearDown(() => root.deleteSync(recursive: true));

  await tester.pumpWidget(
    AppScope(
      settings: settings,
      boards: repository,
      symbols: provider,
      symbolImages: SymbolImageStore(root: root, provider: provider),
      editMode: editMode,
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return _App(settings, editMode);
}

Future<void> _openBoard(WidgetTester tester) async {
  await tester.tap(find.text('Casa'));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Ajustes'));
  await tester.pumpAndSettle();
}

/// Toca nas teclas do PIN, uma por uma, dentro do diálogo aberto.
Future<void> _typePin(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(digit),
      ),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Resolve a conta do "Esqueci o PIN" lendo-a da tela.
int _challengeAnswer(WidgetTester tester) {
  final question = find.textContaining('quanto é').evaluate().single.widget
      as Text;
  final match = RegExp(r'quanto é (\d+) × (\d+)\?').firstMatch(question.data!)!;
  return int.parse(match.group(1)!) * int.parse(match.group(2)!);
}

void main() {
  group('entrar no modo de edição com PIN (ADR-040)', () {
    testWidgets('sem PIN, segurar o cadeado destrava direto', (tester) async {
      final app = await _pumpApp(tester);
      await _openBoard(tester);

      await unlockEditMode(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(app.editMode.isEditing, isTrue);
    });

    testWidgets('com PIN, segurar o cadeado pede o PIN e ainda não destrava', (
      tester,
    ) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openBoard(tester);

      await unlockEditMode(tester);

      expect(find.text('Digite o PIN'), findsOneWidget);
      expect(app.editMode.isEditing, isFalse);
    });

    testWidgets('PIN certo destrava e fecha o pedido', (tester) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openBoard(tester);
      await unlockEditMode(tester);

      await _typePin(tester, '1234');

      expect(find.byType(AlertDialog), findsNothing);
      expect(app.editMode.isEditing, isTrue);
      expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
    });

    testWidgets('PIN errado avisa, limpa as bolinhas e continua pedindo', (
      tester,
    ) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openBoard(tester);
      await unlockEditMode(tester);

      await _typePin(tester, '1111');

      expect(find.text('PIN incorreto. Tente de novo.'), findsOneWidget);
      expect(find.text('Digite o PIN'), findsOneWidget);
      expect(app.editMode.isEditing, isFalse);

      // Pode tentar de novo, e o aviso some ao digitar.
      await _typePin(tester, '1234');
      expect(app.editMode.isEditing, isTrue);
    });

    testWidgets('apagar um dígito corrige o que foi digitado', (tester) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openBoard(tester);
      await unlockEditMode(tester);

      await _typePin(tester, '19');
      await tester.tap(find.byTooltip('Apagar o último número'));
      await tester.pump();
      await _typePin(tester, '234');

      expect(app.editMode.isEditing, isTrue);
    });

    testWidgets('cancelar o pedido não destrava', (tester) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openBoard(tester);
      await unlockEditMode(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(app.editMode.isEditing, isFalse);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('segurar o cadeado de novo depois de cancelar pede o PIN outra vez', (
      tester,
    ) async {
      await _pumpApp(tester, pin: '1234');
      await _openBoard(tester);
      await unlockEditMode(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await unlockEditMode(tester);

      expect(find.text('Digite o PIN'), findsOneWidget);
    });

    testWidgets('Esqueci o PIN: a conta certa destrava', (tester) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openBoard(tester);
      await unlockEditMode(tester);

      await tester.tap(find.text('Esqueci o PIN'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        _challengeAnswer(tester).toString(),
      );
      await tester.tap(find.text('Liberar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(app.editMode.isEditing, isTrue);
      expect(app.settings.hasPin, isTrue); // o PIN continua ligado
    });

    testWidgets('Esqueci o PIN: conta errada avisa e não destrava', (
      tester,
    ) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openBoard(tester);
      await unlockEditMode(tester);
      await tester.tap(find.text('Esqueci o PIN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1');
      await tester.tap(find.text('Liberar'));
      await tester.pumpAndSettle();

      expect(find.text('Resposta errada. Esta é outra conta.'), findsOneWidget);
      expect(app.editMode.isEditing, isFalse);
    });

    testWidgets('Esqueci o PIN: cancelar volta ao pedido do PIN', (
      tester,
    ) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openBoard(tester);
      await unlockEditMode(tester);
      await tester.tap(find.text('Esqueci o PIN'));
      await tester.pumpAndSettle();

      // Dois diálogos empilhados, cada um com o seu "Cancelar": o de cima é o
      // último na árvore.
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();

      expect(find.text('Digite o PIN'), findsOneWidget);
      expect(app.editMode.isEditing, isFalse);
    });

    testWidgets('lista de pranchas também pede o PIN', (tester) async {
      final app = await _pumpApp(tester, pin: '1234');

      await unlockEditMode(tester);
      expect(find.text('Digite o PIN'), findsOneWidget);
      await _typePin(tester, '1234');

      expect(app.editMode.isEditing, isTrue);
    });

    testWidgets('teclado cabe no telefone com texto a 200% e no tablet', (
      tester,
    ) async {
      for (final (size, scale) in [
        (const Size(390, 844), 2.0),
        (const Size(1280, 800), 1.0),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pumpApp(tester, pin: '1234');
        await _openBoard(tester);

        await unlockEditMode(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('Digite o PIN'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
      }
    });
  });

  group('Ajustes: ligar, trocar e desligar o PIN', () {
    testWidgets('começa desligado, sem o botão de trocar', (tester) async {
      await _pumpApp(tester);
      await _openSettings(tester);

      expect(find.text('Pedir PIN para editar'), findsOneWidget);
      expect(find.text('Desligado'), findsOneWidget);
      expect(find.text('Trocar PIN'), findsNothing);
    });

    testWidgets('ligar: digita duas vezes e o PIN passa a valer', (
      tester,
    ) async {
      final app = await _pumpApp(tester);
      await _openSettings(tester);

      await tester.tap(find.text('Pedir PIN para editar'));
      await tester.pumpAndSettle();
      expect(find.text('Escolha um PIN de 4 números'), findsOneWidget);
      await _typePin(tester, '4321');
      expect(find.text('Digite o PIN de novo'), findsOneWidget);
      await _typePin(tester, '4321');

      expect(find.byType(AlertDialog), findsNothing);
      expect(app.settings.hasPin, isTrue);
      expect(app.settings.checkPin('4321'), isTrue);
      expect(find.text('PIN ligado.'), findsOneWidget);
      expect(find.text('Ligado'), findsOneWidget);
      expect(find.text('Trocar PIN'), findsOneWidget);
    });

    testWidgets('ligar: PINs diferentes voltam ao começo com aviso', (
      tester,
    ) async {
      final app = await _pumpApp(tester);
      await _openSettings(tester);
      await tester.tap(find.text('Pedir PIN para editar'));
      await tester.pumpAndSettle();

      await _typePin(tester, '1234');
      await _typePin(tester, '4321');

      expect(find.text('Os PINs não são iguais. Escolha de novo.'), findsOneWidget);
      expect(find.text('Escolha um PIN de 4 números'), findsOneWidget);
      expect(app.settings.hasPin, isFalse);
    });

    testWidgets('ligar: cancelar deixa tudo como estava', (tester) async {
      final app = await _pumpApp(tester);
      await _openSettings(tester);
      await tester.tap(find.text('Pedir PIN para editar'));
      await tester.pumpAndSettle();
      await _typePin(tester, '1234');

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(app.settings.hasPin, isFalse);
      expect(find.text('Desligado'), findsOneWidget);
    });

    testWidgets('desligar pede o PIN atual; com o PIN certo, desliga', (
      tester,
    ) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openSettings(tester);

      await tester.tap(find.text('Pedir PIN para editar'));
      await tester.pumpAndSettle();
      expect(find.text('Digite o PIN'), findsOneWidget);
      expect(app.settings.hasPin, isTrue); // ainda ligado
      await _typePin(tester, '1234');

      expect(app.settings.hasPin, isFalse);
      expect(find.text('PIN desligado.'), findsOneWidget);
      expect(find.text('Trocar PIN'), findsNothing);
    });

    testWidgets('desligar com o PIN errado ou cancelando mantém o PIN', (
      tester,
    ) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openSettings(tester);
      await tester.tap(find.text('Pedir PIN para editar'));
      await tester.pumpAndSettle();

      await _typePin(tester, '0000');
      expect(app.settings.hasPin, isTrue);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(app.settings.hasPin, isTrue);
      expect(find.text('Ligado'), findsOneWidget);
    });

    testWidgets('trocar pede o PIN atual e depois o novo', (tester) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openSettings(tester);

      await tester.tap(find.text('Trocar PIN'));
      await tester.pumpAndSettle();
      await _typePin(tester, '1234');
      expect(find.text('Escolha um PIN de 4 números'), findsOneWidget);
      await _typePin(tester, '5678');
      await _typePin(tester, '5678');

      expect(app.settings.checkPin('5678'), isTrue);
      expect(app.settings.checkPin('1234'), isFalse);
      expect(find.text('PIN trocado.'), findsOneWidget);
    });

    testWidgets('trocar com o PIN atual errado não chega ao passo do novo', (
      tester,
    ) async {
      final app = await _pumpApp(tester, pin: '1234');
      await _openSettings(tester);
      await tester.tap(find.text('Trocar PIN'));
      await tester.pumpAndSettle();

      await _typePin(tester, '9999');

      expect(find.text('Escolha um PIN de 4 números'), findsNothing);
      expect(find.text('PIN incorreto. Tente de novo.'), findsOneWidget);
      expect(app.settings.checkPin('1234'), isTrue);
    });
  });
}