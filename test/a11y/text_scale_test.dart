import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/theme/app_theme.dart';
import 'package:prifono_caa/features/boards/domain/board.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/board_cell_size.dart';
import 'package:prifono_caa/features/boards/presentation/board_form_dialog.dart';
import 'package:prifono_caa/features/boards/presentation/card_label_fit.dart';
import 'package:prifono_caa/features/pin/presentation/pin_dialogs.dart';

import '../support/pump_editing_app.dart';
import '../support/unlock_edit_mode.dart';

// TESTES DE TEXTO AMPLIADO E AVISO DE CÉLULA (E6-6a, ADR-041).
//
// A auditoria (accessibility_audit_test.dart) cobre o tamanho dos alvos de
// toque a 200%; aqui ficam os CONTRATOS que ela não olha: o teclado do PIN, o
// rótulo do card (piso e base), o aviso de célula pequena e a mensagem de
// estado rolável da prancha.
//
// Regra do projeto: a fonte dos testes de widget é a "Ahem" (todo glifo é um
// quadrado). Por isso nada aqui afirma largura exata de texto: afirmamos
// faixas e comportamento.

const List<({String name, Size size})> _devices = [
  (name: 'telefone', size: Size(390, 844)),
  (name: 'tablet', size: Size(1280, 800)),
];

/// Textos em português, lidos do próprio ARB (nada de texto copiado à mão).
AppLocalizations get _pt => lookupAppLocalizations(const Locale('pt'));

void _setView(WidgetTester tester, Size size, {double textScale = 2}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Finder get _lock => find.byIcon(Icons.lock_outline);

/// A tecla de um dígito do teclado do PIN.
Finder _key(String digit) => find.widgetWithText(FilledButton, digit);

/// Sobe o app com PIN 1234 e abre o pedido de PIN pelo cadeado.
Future<EditingApp> _openPinDialog(WidgetTester tester) async {
  final app = await pumpEditingApp(
    tester,
    boards: {'Casa': const []},
    pin: '1234',
  );
  await tester.tap(_lock);
  await tester.pumpAndSettle();
  expect(find.byType(PinVerifyDialog), findsOneWidget);
  return app;
}

Widget _dialogHarness(void Function(BoardFormResult?) onResult) {
  return MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () async {
              onResult(await showBoardFormDialog(context));
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
}

/// Abre o formulário de prancha novo e sobe as colunas até [columns].
Future<void> _openForm(
  WidgetTester tester, {
  required int columns,
  void Function(BoardFormResult?)? onResult,
}) async {
  await tester.pumpWidget(_dialogHarness(onResult ?? (_) {}));
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  for (var c = Board.defaultColumns; c < columns; c++) {
    await tester.tap(find.byTooltip('Aumentar colunas'));
    await tester.pump();
  }
}

void main() {
  group('PIN a 200%', () {
    for (final device in _devices) {
      testWidgets(
        '${device.name}: o teclado não muda de lugar quando o erro aparece',
        (tester) async {
          // Janela ALTA: sem rolagem do diálogo, o que se mede é só o teclado.
          _setView(tester, Size(device.size.width, 2400));
          final app = await _openPinDialog(tester);
          final keyBefore = tester.getTopLeft(_key('5'));

          // 1111 não é o PIN (1234): aparece o erro.
          for (final digit in ['1', '1', '1', '1']) {
            await tester.tap(_key(digit));
            await tester.pump();
          }
          await tester.pumpAndSettle();

          expect(app.editMode.isEditing, isFalse);
          expect(
            tester.getTopLeft(_key('5')),
            offsetMoreOrLessEquals(keyBefore, epsilon: 0.01),
          );
          // A mensagem tem altura própria e termina antes da primeira tecla.
          final message = tester.getRect(find.text(_pt.pinWrong));
          expect(message.height, greaterThan(0));
          expect(
            message.bottom,
            lessThanOrEqualTo(tester.getRect(_key('1')).top + 0.5),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '${device.name}: as 10 teclas têm 48 dp ou mais e o PIN certo destrava',
        (tester) async {
          _setView(tester, device.size);
          final app = await _openPinDialog(tester);

          for (var d = 0; d <= 9; d++) {
            final size = tester.getSize(_key('$d'));
            expect(size.width, greaterThanOrEqualTo(48), reason: 'tecla $d');
            expect(size.height, greaterThanOrEqualTo(48), reason: 'tecla $d');
          }

          // O diálogo rola (scrollable: true): chega até cada tecla antes.
          for (final digit in ['1', '2', '3', '4']) {
            await tester.ensureVisible(_key(digit));
            await tester.pump();
            await tester.tap(_key(digit));
            await tester.pump();
          }
          await tester.pumpAndSettle();

          expect(find.byType(PinVerifyDialog), findsNothing);
          expect(app.editMode.isEditing, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('rótulo do card a 200%', () {
    const labels = ['Sim', 'Quero beber água agora', 'Paralelepípedo'];

    for (final device in _devices) {
      testWidgets(
        '${device.name}: entre o piso e a base, em até 2 linhas, alvo de 48 dp',
        (tester) async {
          _setView(tester, device.size);
          await pumpEditingApp(
            tester,
            boards: {
              'Casa': [for (final label in labels) CardContent(label: label)],
            },
          );
          await tester.tap(find.text('Casa'));
          await tester.pumpAndSettle();

          for (final label in labels) {
            final text = tester.widget<Text>(find.text(label));
            final tile = tester.getSize(
              find
                  .ancestor(of: find.text(label), matching: find.byType(InkWell))
                  .first,
            );
            final base = CardLabelFit.baseSizeFor(
              math.min(tile.width, tile.height),
            );
            final floor = CardLabelFit.floorSizeFor(base);
            final fontSize = text.style?.fontSize;

            expect(fontSize, isNotNull, reason: label);
            expect(fontSize!, greaterThanOrEqualTo(floor - 0.01), reason: label);
            expect(fontSize, lessThanOrEqualTo(base + 0.01), reason: label);
            expect(text.maxLines, CardLabelFit.maxLines, reason: label);
            expect(tile.width, greaterThanOrEqualTo(48), reason: label);
            expect(tile.height, greaterThanOrEqualTo(48), reason: label);
            expect(
              tester.getSize(find.text(label)).height,
              lessThanOrEqualTo(tile.height),
              reason: label,
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('aviso de célula pequena (boardFormCellTooSmall)', () {
    String warning(double width) =>
        _pt.boardFormCellTooSmall(BoardCellSize.maxColumnsFor(width));

    testWidgets('390 dp: 6 colunas (o máximo sugerido) sem aviso, 7 com aviso', (
      tester,
    ) async {
      _setView(tester, const Size(390, 844), textScale: 1);
      await _openForm(tester, columns: 6);
      expect(find.text(warning(390)), findsNothing);

      await tester.tap(find.byTooltip('Aumentar colunas'));
      await tester.pump();

      expect(find.text(warning(390)), findsOneWidget);
    });

    testWidgets('390 dp: com 4 colunas (o padrão) não há aviso', (tester) async {
      _setView(tester, const Size(390, 844), textScale: 1);
      await _openForm(tester, columns: Board.defaultColumns);

      expect(find.text(warning(390)), findsNothing);
    });

    testWidgets('1280 dp: 7 colunas cabem, sem aviso', (tester) async {
      _setView(tester, const Size(1280, 800), textScale: 1);
      await _openForm(tester, columns: 7);

      expect(find.text(warning(1280)), findsNothing);
    });

    testWidgets('o aviso não bloqueia: salvar devolve as 7 colunas', (
      tester,
    ) async {
      _setView(tester, const Size(390, 844), textScale: 1);
      BoardFormResult? result;
      await _openForm(tester, columns: 7, onResult: (value) => result = value);
      expect(find.text(warning(390)), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Casa');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(result?.name, 'Casa');
      expect(result?.columns, 7);
    });
  });

  group('mensagem de estado da prancha a 200%', () {
    for (final device in _devices) {
      testWidgets(
        '${device.name}: no máximo 20% da altura, rolável por dentro',
        (tester) async {
          _setView(tester, device.size);
          await pumpEditingApp(
            tester,
            boards: {
              'Casa': const [
                CardContent(label: 'Água'),
                CardContent(label: 'Comer'),
              ],
            },
          );
          await tester.tap(find.text('Casa'));
          await tester.pumpAndSettle();
          await unlockEditMode(tester);

          final message = find.text(_pt.editModeHint);
          expect(message, findsOneWidget);
          final scrollView = find
              .ancestor(of: message, matching: find.byType(SingleChildScrollView))
              .first;
          final viewport = tester.getSize(scrollView);
          final scrollable = tester.state<ScrollableState>(
            find.descendant(of: scrollView, matching: find.byType(Scrollable)),
          );
          final textHeight = tester.getSize(message).height;

          // A mensagem nunca passa de 20% da altura da janela...
          expect(viewport.height, lessThanOrEqualTo(device.size.height * 0.2));
          // ...e o texto inteiro continua ALCANÇÁVEL: o que não cabe rola.
          expect(
            textHeight,
            lessThanOrEqualTo(
              viewport.height + scrollable.position.maxScrollExtent + 0.5,
            ),
          );
          // A grade não perde espaço: o primeiro card segue dentro da tela.
          final screen = Offset.zero & device.size;
          final card = tester.getRect(find.text('Água'));
          expect(screen.contains(card.topLeft), isTrue);
          expect(screen.contains(card.bottomRight), isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
