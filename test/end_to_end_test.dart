import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/boards/presentation/card_editor_page.dart';
import 'package:prifono_caa/features/editing/presentation/edit_mode_controller.dart';
import 'package:prifono_caa/features/pin/presentation/pin_dialogs.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_controller.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';
import 'package:prifono_caa/features/symbols/presentation/symbol_search_page.dart';

import 'features/speech/fake_speech_service.dart';
import 'support/pump_editing_app.dart';
import 'support/unlock_edit_mode.dart';

// TESTES PONTA A PONTA (E6-6b, ADR-041).
//
// O app inteiro de pé (PrifonoApp + AppScope), do jeito que a pessoa usa:
//  1. fluxo completo com BUSCA REAL: a busca e o download do pictograma passam
//     pelo ArasaacProvider e pelo SymbolImageStore de verdade; só a REDE é
//     falsa (MockClient);
//  2. editar um card com PIN ligado.
//
// Regras do projeto que valem aqui:
//  - nada de pumpAndSettle com um indicador de progresso na tela (o
//    CircularProgressIndicator anima para sempre e o settle estoura): enquanto
//    a busca ou o download estão em andamento, só pump(Duration);
//  - o download grava arquivo de verdade (create, writeAsBytes, rename). O
//    relógio falso do testWidgets não conclui I/O real: o laço de
//    _waitForDownload alterna uma espera REAL (runAsync) com um pump.

/// PNG mínimo: a assinatura basta para o SymbolImageStore aceitar. Não
/// decodifica como imagem; o app cai no errorBuilder (por isso os testes não
/// afirmam pixels, só o arquivo e o que foi gravado).
final Uint8List _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  1, 2, 3,
]);

/// Formato da busca do ARASAAC (conferido em arasaac_provider.dart).
const String _searchJson =
    '[{"_id": 2265, "keywords": [{"keyword": "água"}], '
    '"sex": false, "violence": false}]';

/// Textos em português, lidos do próprio ARB.
AppLocalizations get _pt => lookupAppLocalizations(const Locale('pt'));

/// Rede falsa do ARASAAC: a busca (api.arasaac.org) devolve o JSON em UTF-8 e
/// a imagem (static.arasaac.org) devolve o PNG. Guarda as URLs pedidas.
MockClient _arasaacClient(List<Uri> requests) {
  return MockClient((request) async {
    requests.add(request.url);
    switch (request.url.host) {
      case 'api.arasaac.org':
        return http.Response.bytes(
          utf8.encode(_searchJson),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      case 'static.arasaac.org':
        return http.Response.bytes(_png, 200);
      default:
        return http.Response('', 404);
    }
  });
}

/// As peças do app que o teste do fluxo precisa olhar.
class _FlowApp {
  _FlowApp({
    required this.editMode,
    required this.speech,
    required this.sentence,
    required this.boards,
    required this.images,
  });

  final EditModeController editMode;
  final FakeSpeechService speech;
  final SentenceController sentence;
  final InMemoryBoardRepository boards;
  final SymbolImageStore images;
}

/// Sobe o app na lista de pranchas, SEM pranchas. O [client] serve à busca E ao
/// download (o SymbolImageStore também recebe o client; sem isso ele criaria um
/// cliente HTTP de verdade).
Future<_FlowApp> _pumpFlowApp(
  WidgetTester tester, {
  required http.Client client,
}) async {
  final speech = FakeSpeechService();
  final sentence = SentenceController();
  final editMode = EditModeController();
  final repository = InMemoryBoardRepository();
  final provider = ArasaacProvider(client: client);
  final root = Directory.systemTemp.createTempSync('privox_flow_');
  addTearDown(() => root.deleteSync(recursive: true));
  final images = SymbolImageStore(
    root: root,
    provider: provider,
    client: client,
  );

  await tester.pumpWidget(
    AppScope(
      settings: SettingsController(),
      boards: repository,
      symbols: provider,
      symbolImages: images,
      speech: speech,
      sentence: sentence,
      editMode: editMode,
      child: const PrifonoApp(),
    ),
  );
  await tester.pumpAndSettle(); // a splash
  return _FlowApp(
    editMode: editMode,
    speech: speech,
    sentence: sentence,
    boards: repository,
    images: images,
  );
}

/// Tablet (ADR-031): o alvo de primeira classe.
void _setView(WidgetTester tester, [Size size = const Size(1280, 800)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Espera o download do pictograma terminar: o botão Salvar volta a ficar ativo
/// e a mensagem "baixando" some. Cada volta espera um pouco de tempo REAL (o
/// I/O de disco) e dá um pump (para o Flutter seguir a partir do I/O).
Future<void> _waitForDownload(WidgetTester tester) async {
  final save = find.widgetWithText(FilledButton, 'Salvar');
  final downloading = find.text(_pt.cardSymbolDownloading);
  for (var i = 0; i < 100; i++) {
    final saveEnabled = tester.widget<FilledButton>(save).onPressed != null;
    if (saveEnabled && downloading.evaluate().isEmpty) return;
    await tester.runAsync<void>(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  fail(
    'O download do pictograma não terminou em ~2 s (laço de runAsync + pump). '
    'Salvar ativo: ${tester.widget<FilledButton>(save).onPressed != null}; '
    'mensagem "baixando" na tela: ${downloading.evaluate().isNotEmpty}; '
    'mensagem de falha na tela: '
    '${find.text(_pt.cardSymbolFailedHint).evaluate().isNotEmpty}.',
  );
}

Finder get _lock => find.byIcon(Icons.lock_outline);

/// A tecla de um dígito do teclado do PIN.
Finder _key(String digit) => find.widgetWithText(FilledButton, digit);

/// Digita [pin] no teclado do PIN. O diálogo rola (scrollable: true): chega
/// até cada tecla antes de tocar. Com 4 dígitos o diálogo confere sozinho.
Future<void> _typePin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.ensureVisible(_key(digit));
    await tester.pump();
    await tester.tap(_key(digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  group('fluxo ponta a ponta', () {
    testWidgets(
      'criar prancha, card com pictograma pela busca, usar, frase e falar',
      (tester) async {
        _setView(tester);
        final requests = <Uri>[];
        final app = await _pumpFlowApp(
          tester,
          client: _arasaacClient(requests),
        );
        const ref = SymbolRef(source: SymbolRef.arasaac, id: '2265');

        // 1) Criar a prancha "Casa" (sem PIN: segurar o cadeado entra em
        // edição).
        await unlockEditMode(tester);
        expect(app.editMode.isEditing, isTrue);
        await tester.tap(find.text('Nova prancha'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), 'Casa');
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();
        expect(find.text('Casa'), findsOneWidget);

        // 2) Abrir a prancha (a edição continua ligada) e tocar no "+".
        await tester.tap(find.text('Casa'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Adicionar card'));
        await tester.pumpAndSettle();
        expect(find.text('Novo card'), findsOneWidget);

        // 3) Buscar o pictograma. O debounce (400 ms) é um Timer: o
        // pumpAndSettle não o avançaria. Sem pumpAndSettle daqui até o fim do
        // download: há indicadores de progresso animando.
        await tester.tap(find.text('Escolher pictograma'));
        await tester.pumpAndSettle();
        expect(find.byType(SymbolSearchPage), findsOneWidget);
        await tester.enterText(
          find.descendant(
            of: find.byType(SymbolSearchPage),
            matching: find.byType(TextField),
          ),
          'água',
        );
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          requests.any(
            (url) =>
                url.host == 'api.arasaac.org' && url.pathSegments.last == 'água',
          ),
          isTrue,
          reason: 'a busca saiu pelo ArasaacProvider',
        );

        // O texto "água" também está no campo de busca: o resultado é o que
        // está dentro da grade.
        final result = find.descendant(
          of: find.byType(GridView),
          matching: find.text('água'),
        );
        expect(result, findsOneWidget);
        await tester.tap(result);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500)); // a transição

        // 4) De volta ao editor: o download começa (Salvar desativado) e o
        // rótulo é preenchido pelo pictograma.
        expect(find.byType(SymbolSearchPage), findsNothing);
        expect(find.text(_pt.cardSymbolDownloading), findsOneWidget);
        await _waitForDownload(tester);
        await tester.pumpAndSettle();
        expect(app.images.isCached(ref), isTrue);
        expect(
          requests.any(
            (url) =>
                url.host == 'static.arasaac.org' &&
                url.path == '/pictograms/2265/2265_500.png',
          ),
          isTrue,
          reason: 'a imagem foi baixada pelo SymbolImageStore',
        );
        expect(find.widgetWithText(TextFormField, 'água'), findsOneWidget);

        // 5) Salvar: o card entra na prancha e foi gravado com o símbolo.
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();
        expect(find.byType(CardEditorPage), findsNothing);
        expect(find.text('água'), findsOneWidget);
        final board = (await app.boards.listBoards()).single;
        final cards = await app.boards.listCards(board.id);
        expect(cards, hasLength(1));
        expect(cards.single.content.label, 'água');
        expect(cards.single.content.symbol, ref);

        // 6) Sair da edição e USAR o card: cada toque fala e entra na frase.
        await tester.tap(find.byIcon(Icons.lock_open_outlined));
        await tester.pumpAndSettle();
        expect(app.editMode.isEditing, isFalse);
        // O centro do card, medido ANTES de a frase ganhar uma ficha com o
        // mesmo texto (depois, find.text('água') acharia duas).
        final cardCenter = tester.getCenter(find.text('água'));

        await tester.tapAt(cardCenter);
        await tester.pump();
        expect(app.speech.spoken, ['água']);
        expect(app.sentence.length, 1);

        await tester.tapAt(cardCenter);
        await tester.pump();
        expect(app.speech.spoken, ['água', 'água']);
        expect(app.sentence.length, 2);

        // 7) Falar: a frase inteira numa só chamada, com as palavras unidas.
        await tester.tap(find.byIcon(Icons.volume_up));
        await tester.pump();
        expect(app.speech.spoken, ['água', 'água', 'água água']);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('editar card com PIN', () {
    testWidgets(
      'PIN errado não destrava; PIN certo destrava, edita e salva',
      (tester) async {
        _setView(tester);
        final app = await pumpEditingApp(
          tester,
          boards: {
            'Casa': const [CardContent(label: 'Água')],
          },
          pin: '1234',
        );
        await tester.tap(find.text('Casa'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Adicionar card'), findsNothing); // em uso

        // PIN errado: um toque no cadeado, 0000, continua em uso. O texto do
        // erro está SEMPRE na árvore (Visibility com maintainSize, E6-3.6):
        // o que prova que ele aparece é o `visible`.
        await tester.tap(_lock);
        await tester.pumpAndSettle();
        expect(find.byType(PinVerifyDialog), findsOneWidget);
        await _typePin(tester, '0000');
        expect(app.editMode.isEditing, isFalse);
        expect(find.byType(PinVerifyDialog), findsOneWidget);
        final errorBox = tester.widget<Visibility>(
          find
              .ancestor(
                of: find.text(_pt.pinWrong),
                matching: find.byType(Visibility),
              )
              .first,
        );
        expect(errorBox.visible, isTrue);
        expect(find.byTooltip('Adicionar card'), findsNothing);

        // Fecha o pedido (toque na barreira) e tenta de novo com o PIN certo.
        // (Digitar de novo NO MESMO diálogo, depois do erro, não é coberto
        // aqui: o teste não depende de o diálogo limpar os dígitos.)
        await tester.tapAt(const Offset(2, 300));
        await tester.pumpAndSettle();
        expect(find.byType(PinVerifyDialog), findsNothing);
        expect(app.editMode.isEditing, isFalse);

        await tester.tap(_lock);
        await tester.pumpAndSettle();
        await _typePin(tester, '1234');
        expect(find.byType(PinVerifyDialog), findsNothing);
        expect(app.editMode.isEditing, isTrue);
        expect(find.byTooltip('Adicionar card'), findsOneWidget);

        // Editar o card: abre o editor, troca o texto e salva.
        await tester.tap(find.text('Água'));
        await tester.pumpAndSettle();
        expect(find.text('Editar card'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).first,
          'Água gelada',
        );
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(find.byType(CardEditorPage), findsNothing);
        expect(find.text('Água gelada'), findsOneWidget);
        expect(find.text('Água'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
