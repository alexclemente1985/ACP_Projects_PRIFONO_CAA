import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/app/theme/app_theme.dart';
import 'package:prifono_caa/features/boards/presentation/card_colors.dart';
import 'package:prifono_caa/features/settings/domain/app_language.dart';

import '../support/pump_lock_app.dart';

// CHIPS SELECIONADOS (E6-4.2, ADR-041): a seleção é a BORDA mais grossa, sem
// check. Rode da RAIZ do projeto:
//   flutter test test/theme/chip_style_test.dart

void main() {
  for (final (name, theme) in [
    ('claro', AppTheme.light),
    ('escuro', AppTheme.dark),
  ]) {
    group('tema $name', () {
      BorderSide sideWhen({required bool selected}) {
        final side = WidgetStateProperty.resolveAs<BorderSide?>(
          theme.chipTheme.side,
          selected ? <WidgetState>{WidgetState.selected} : <WidgetState>{},
        );
        expect(side, isNotNull);
        return side!;
      }

      test('o chip selecionado tem borda bem mais grossa', () {
        final normal = sideWhen(selected: false);
        final selected = sideWhen(selected: true);

        expect(normal.width, kChipBorderWidth);
        expect(selected.width, kChipSelectedBorderWidth);
        expect(selected.width, greaterThanOrEqualTo(3));
        expect(selected.width - normal.width, greaterThanOrEqualTo(2.5));
      });

      test('as bordas têm pelo menos 3:1 sobre o fundo da tela', () {
        final background = theme.scaffoldBackgroundColor;

        expect(
          CardColors.contrastRatio(sideWhen(selected: false).color, background),
          greaterThanOrEqualTo(3),
          reason: 'borda normal',
        );
        expect(
          CardColors.contrastRatio(sideWhen(selected: true).color, background),
          greaterThanOrEqualTo(3),
          reason: 'borda selecionada',
        );
      });
    });
  }

  testWidgets('os chips de Ajustes não desenham check', (tester) async {
    // Tela alta: todos os chips (tema e idioma) existem na árvore.
    await pumpLockApp(tester, size: const Size(390, 2400));
    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();

    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .toList();
    expect(chips, hasLength(3 + 1 + AppLanguage.concrete.length));
    for (final chip in chips) {
      expect(chip.showCheckmark, isFalse);
    }
  });
}