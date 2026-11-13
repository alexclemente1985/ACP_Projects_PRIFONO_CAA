import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';

import '../support/unlock_edit_mode.dart';

// AUDITORIA DE ACESSIBILIDADE (E6-1, ADR-041). Versão 5 (E6b-2, ADR-042).
//
// Roda os guidelines oficiais do `flutter_test` (alvo de toque Android 48 dp,
// alvo de toque iOS 44 dp, rótulo em todo alvo tocável e contraste de texto
// WCAG AA) em 15 telas, em telefone (390×844) e tablet (1280×800), com texto a
// 100% e a 200%.
//
// Cada teste junta TODOS os achados da tela numa mensagem só (em vez de parar
// no primeiro). Teste VERDE = a tela passou nos guidelines; teste VERMELHO com
// "[Tappable objects...]" ou "[Text contrast...]" = achado. Rode da RAIZ do
// projeto (onde está o pubspec.yaml):
//
//   flutter test test/a11y/accessibility_audit_test.dart
//
// Ao fim da E6 este arquivo é a trava de regressão (tudo passando).
//
// Histórico:
// - v3 (09/11): o `SemanticsHandle` é liberado DENTRO do teste e as telas
//   longas (editor de card e ajustes) são avaliadas INTEIRAS, numa janela
//   altíssima, para nenhum item ficar cortado pela borda da área visível.
// - v4 (09/11, E6-3): o cenário "prancha 8×3" deixa de rodar no TELEFONE. Ali
//   a célula mede ≈38 dp (< 48 dp) por construção: 8 colunas em 390 dp. A
//   decisão 3 do ADR-041 é AVISAR no formulário da prancha, não bloquear, então
//   a prancha continua desenhando a grade pedida. O aviso é coberto por
//   `test/a11y/text_scale_test.dart`. No tablet (1280 dp) a mesma prancha passa.
// - v5 (E6b-2, ADR-042): a prancha "Temática" tem um card 2×2 e posições em
//   branco, e entra em dois cenários novos (uso e edição). Em edição cada
//   posição em branco é um "+" com rótulo próprio ("linha 2, coluna 3") e
//   precisa passar nos mesmos guidelines de alvo de toque e de rótulo.

/// Palavras da prancha "Casa": uma de cada classe gramatical e uma sem classe.
const List<(String, WordClass?)> _words = [
  ('Eu', WordClass.pronoun),
  ('Quero', WordClass.verb),
  ('Água', WordClass.noun),
  ('Grande', WordClass.adjective),
  ('Em', WordClass.preposition),
  ('O quê?', WordClass.question),
  ('Não', WordClass.negation),
  ('Muito', WordClass.adverb),
  ('E', WordClass.conjunction),
  ('O', WordClass.determiner),
  ('Sem classe', null),
];

const List<({String name, Size size})> _devices = [
  (name: 'telefone', size: Size(390, 844)),
  (name: 'tablet', size: Size(1280, 800)),
];

const List<double> _textScales = [1, 2];

/// Uma tela a auditar: [open] leva o app até ela, a partir da lista de pranchas.
class _Scenario {
  _Scenario(
    this.name,
    this.open, {
    this.withPin = false,
    this.tall = false,
    this.exceptDevices = const <String>{},
  });

  final String name;
  final Future<void> Function(WidgetTester tester) open;

  /// Liga um PIN antes de subir o app (para auditar o pedido de PIN).
  final bool withPin;

  /// Usa uma janela altíssima (sem rolagem): a tela inteira existe e nada fica
  /// cortado pela borda da área visível. Sem isso, o guideline mede o pedaço
  /// VISÍVEL de um item parcialmente rolado para fora e acusa tamanho menor
  /// que o real (achado de 09/11: chip de 56 dp "com 40 dp").
  final bool tall;

  /// Aparelhos (nomes de `_devices`) em que o cenário NÃO roda, de propósito.
  final Set<String> exceptDevices;
}

Future<void> _openBoard(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Ajustes'));
  await tester.pumpAndSettle();
}

/// Rola a tela até [finder] existir e ficar visível. Um `ListView` só constrói
/// o que está perto da área visível, então `ensureVisible` sozinho falha.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _openCardEditor(WidgetTester tester) async {
  await _openBoard(tester, 'Casa');
  await unlockEditMode(tester);
  await tester.tap(find.text('Água'));
  await tester.pumpAndSettle();
}

final List<_Scenario> _scenarios = [
  _Scenario('lista de pranchas (uso)', (tester) async {}),
  _Scenario('lista de pranchas (edição)', unlockEditMode),
  _Scenario('prancha 4×3 (uso)', (tester) => _openBoard(tester, 'Casa')),
  _Scenario('prancha 4×3 (edição)', (tester) async {
    await _openBoard(tester, 'Casa');
    await unlockEditMode(tester);
  }),
  // 8 colunas: no telefone a célula fica abaixo de 48 dp (achado A2). Aceito e
  // avisado no formulário (ADR-041 decisão 3); aqui só o tablet é auditado.
  _Scenario(
    'prancha 8×3 (uso)',
    (tester) => _openBoard(tester, 'Larga'),
    exceptDevices: {'telefone'},
  ),
  // Card 2×2 e posições em branco (ADR-042). Em edição: um "+" por posição.
  _Scenario(
    'prancha com buracos (uso)',
    (tester) => _openBoard(tester, 'Temática'),
  ),
  _Scenario('prancha com buracos (edição)', (tester) async {
    await _openBoard(tester, 'Temática');
    await unlockEditMode(tester);
  }),
  _Scenario('editor de card (início)', _openCardEditor),
  _Scenario('editor de card (página inteira)', _openCardEditor, tall: true),
  _Scenario('busca de pictogramas', (tester) async {
    await _openCardEditor(tester);
    await _scrollTo(tester, find.text('Escolher pictograma'));
    await tester.tap(find.text('Escolher pictograma'));
    await tester.pumpAndSettle();
  }),
  _Scenario('formulário de prancha', (tester) async {
    await unlockEditMode(tester);
    await tester.tap(find.text('Nova prancha'));
    await tester.pumpAndSettle();
  }),
  _Scenario('ajustes (início)', _openSettings),
  _Scenario('ajustes (página inteira)', _openSettings, tall: true),
  _Scenario('sobre e créditos', (tester) async {
    await _openSettings(tester);
    await _scrollTo(tester, find.text('Sobre e créditos'));
    await tester.tap(find.text('Sobre e créditos'));
    await tester.pumpAndSettle();
  }),
  // Com PIN ligado, um toque no cadeado abre o pedido de PIN (E6-5).
  _Scenario('pedido de PIN', (tester) async {
    await tester.tap(find.byIcon(Icons.lock_outline));
    await tester.pumpAndSettle();
  }, withPin: true),
];

Future<InMemoryBoardRepository> _seed() async {
  final repository = InMemoryBoardRepository();
  final casa = await repository.createBoard(
    name: 'Casa',
    gridColumns: 4,
    gridRows: 3,
  );
  for (final (label, wordClass) in _words) {
    await repository.addCard(
      casa.id,
      CardContent(label: label, wordClass: wordClass),
    );
  }
  await repository.createBoard(name: 'Escola');
  // 8 colunas: num telefone de 390 dp a célula fica abaixo de 48 dp (achado A2).
  final larga = await repository.createBoard(
    name: 'Larga',
    gridColumns: 8,
    gridRows: 3,
  );
  for (final (label, wordClass) in _words.take(8)) {
    await repository.addCard(
      larga.id,
      CardContent(label: label, wordClass: wordClass),
    );
  }
  // Card grande (2×2) e dois pequenos, com posições em branco em volta.
  final tematica = await repository.createBoard(
    name: 'Temática',
    gridColumns: 4,
    gridRows: 3,
  );
  const themed = [
    (
      'Brincar',
      WordClass.verb,
      CardPlacement(col: 0, row: 0, colSpan: 2, rowSpan: 2),
    ),
    ('Bola', WordClass.noun, CardPlacement(col: 3, row: 1)),
    ('Parque', WordClass.noun, CardPlacement(col: 1, row: 2)),
  ];
  for (final (label, wordClass, placement) in themed) {
    await repository.addCard(
      tematica.id,
      CardContent(label: label, wordClass: wordClass),
      placement: placement,
    );
  }
  return repository;
}

Widget _buildApp({
  required SettingsController settings,
  required InMemoryBoardRepository boards,
}) {
  // Rede, disco e banco falsos: os testes de widget nunca saem da máquina.
  final provider = ArasaacProvider(
    client: MockClient((_) async => http.Response('[]', 404)),
  );
  final root = Directory.systemTemp.createTempSync('prifono_a11y_');
  addTearDown(() => root.deleteSync(recursive: true));
  return AppScope(
    settings: settings,
    boards: boards,
    symbols: provider,
    symbolImages: SymbolImageStore(root: root, provider: provider),
    child: const PrifonoApp(),
  );
}

/// Avalia os guidelines na tela atual e devolve um texto por guideline que
/// falhou (lista vazia = tela sem achados).
Future<List<String>> _evaluate(
  WidgetTester tester, {
  required double scale,
}) async {
  // O contraste de texto não depende da escala: só a 100%.
  final guidelines = <AccessibilityGuideline>[
    androidTapTargetGuideline,
    iOSTapTargetGuideline,
    labeledTapTargetGuideline,
    if (scale == 1) textContrastGuideline,
  ];
  final failures = <String>[];
  for (final guideline in guidelines) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) {
      failures.add('[${guideline.description}]\n${result.reason}');
    }
  }
  return failures;
}

void main() {
  for (final device in _devices) {
    for (final scale in _textScales) {
      for (final scenario in _scenarios) {
        if (scenario.exceptDevices.contains(device.name)) continue;
        final percent = (scale * 100).round();
        testWidgets(
          '${scenario.name} | ${device.name} | texto $percent%',
          (tester) async {
            tester.view.physicalSize =
                scenario.tall ? Size(device.size.width, 6000) : device.size;
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );

            final settings = SettingsController();
            if (scenario.withPin) await settings.setPin('1234');
            await tester.pumpWidget(
              _buildApp(settings: settings, boards: await _seed()),
            );
            await tester.pumpAndSettle(); // splash

            // O handle precisa ser liberado DENTRO do teste: o Flutter confere
            // isso antes de rodar os `addTearDown`.
            final handle = tester.ensureSemantics();
            final List<String> failures;
            try {
              await scenario.open(tester);
              failures = await _evaluate(tester, scale: scale);
            } finally {
              handle.dispose();
            }

            if (failures.isNotEmpty) {
              fail(failures.join('\n\n'));
            }
          },
        );
      }
    }
  }
}