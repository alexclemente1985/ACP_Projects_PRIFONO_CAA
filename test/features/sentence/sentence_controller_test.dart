import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/sentence/domain/sentence_item.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_controller.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

SentenceItem _item(String label, [String? speech]) =>
    SentenceItem(label: label, speech: speech ?? label);

void main() {
  group('SentenceItem', () {
    test('fromContent usa o texto falado, ou o rótulo quando não há', () {
      final withSpeech = SentenceItem.fromContent(
        const CardContent(label: 'Água', speechText: 'Quero beber água'),
      );
      final withoutSpeech = SentenceItem.fromContent(
        const CardContent(label: 'Sim'),
      );

      expect(withSpeech.label, 'Água');
      expect(withSpeech.speech, 'Quero beber água');
      expect(withoutSpeech.speech, 'Sim');
    });

    test('fromContent copia símbolo e cor', () {
      const symbol = SymbolRef(source: SymbolRef.arasaac, id: '2265');
      final item = SentenceItem.fromContent(
        const CardContent(
          label: 'Água',
          symbol: symbol,
          backgroundColor: 0xFFFBB7C4,
        ),
      );

      expect(item.symbol, symbol);
      expect(item.backgroundColor, 0xFFFBB7C4);
    });

    test('igualdade por campos', () {
      expect(_item('Sim'), _item('Sim'));
      expect(_item('Sim').hashCode, _item('Sim').hashCode);
      expect(_item('Sim'), isNot(_item('Não')));
      expect(_item('Sim'), isNot(_item('Sim', 'Sim, por favor')));
    });
  });

  group('SentenceController', () {
    test('começa vazio, sem nada para falar', () {
      final controller = SentenceController();

      expect(controller.isEmpty, isTrue);
      expect(controller.items, isEmpty);
      expect(controller.text, '');
      expect(controller.canSpeak, isFalse);
    });

    test('add mantém a ordem e text junta os textos falados com espaço', () {
      final controller = SentenceController()
        ..add(_item('Eu', 'Eu quero'))
        ..add(_item('Água'));

      expect(controller.items.map((i) => i.label), ['Eu', 'Água']);
      expect(controller.text, 'Eu quero Água');
      expect(controller.canSpeak, isTrue);
    });

    test('itens sem texto ficam fora da fala', () {
      final controller = SentenceController()
        ..add(_item('', '   '))
        ..add(_item('Oi'));

      expect(controller.items, hasLength(2));
      expect(controller.text, 'Oi');
    });

    test('só itens sem texto: não há o que falar', () {
      final controller = SentenceController()..add(_item('', ''));

      expect(controller.isEmpty, isFalse);
      expect(controller.canSpeak, isFalse);
    });

    test('removeLast apaga só o último', () {
      final controller = SentenceController()
        ..add(_item('Eu'))
        ..add(_item('Quero'))
        ..removeLast();

      expect(controller.items.map((i) => i.label), ['Eu']);
    });

    test('clear esvazia a frase', () {
      final controller = SentenceController()
        ..add(_item('Eu'))
        ..add(_item('Quero'))
        ..clear();

      expect(controller.isEmpty, isTrue);
      expect(controller.text, '');
    });

    test('avisa os ouvintes a cada mudança, e só quando muda', () {
      final controller = SentenceController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.add(_item('Eu'));
      expect(notifications, 1);
      controller.removeLast();
      expect(notifications, 2);

      // Sem nada para apagar ou limpar: não avisa.
      controller
        ..removeLast()
        ..clear();
      expect(notifications, 2);
    });

    test('a lista de itens não pode ser alterada por fora', () {
      final controller = SentenceController()..add(_item('Eu'));

      expect(() => controller.items.add(_item('X')), throwsUnsupportedError);
      expect(controller.items, hasLength(1));
    });
  });
}
