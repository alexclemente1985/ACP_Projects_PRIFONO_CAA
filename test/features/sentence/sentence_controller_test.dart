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

  group('SentenceController: remover de qualquer posição e mover (ADR-039)', () {
    SentenceController frase(List<String> labels) {
      final controller = SentenceController();
      for (final label in labels) {
        controller.add(_item(label));
      }
      return controller;
    }

    List<String> labelsOf(SentenceController c) =>
        c.items.map((i) => i.label).toList();

    test('removeAt tira o item da posição, no começo, no meio ou no fim', () {
      final controller = frase(['A', 'B', 'C', 'D'])
        ..removeAt(1)
        ..removeAt(0)
        ..removeAt(1);

      expect(labelsOf(controller), ['C']);
      expect(controller.length, 1);
    });

    test('removeAt com posição inexistente não faz nada nem avisa', () {
      final controller = frase(['A', 'B']);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller
        ..removeAt(-1)
        ..removeAt(2)
        ..removeAt(99);

      expect(labelsOf(controller), ['A', 'B']);
      expect(notifications, 0);
    });

    test('move leva o item para a posição final pedida', () {
      expect((frase(['A', 'B', 'C', 'D'])..move(0, 3)).items.map((i) => i.label),
          ['B', 'C', 'D', 'A']);
      expect((frase(['A', 'B', 'C', 'D'])..move(3, 0)).items.map((i) => i.label),
          ['D', 'A', 'B', 'C']);
      expect((frase(['A', 'B', 'C', 'D'])..move(1, 2)).items.map((i) => i.label),
          ['A', 'C', 'B', 'D']);
      expect((frase(['A', 'B', 'C', 'D'])..move(2, 1)).items.map((i) => i.label),
          ['A', 'C', 'B', 'D']);
    });

    test('move muda também a ordem da fala', () {
      final controller = frase(['Eu', 'quero', 'água'])..move(2, 0);

      expect(controller.text, 'água Eu quero');
    });

    test('move com posições iguais ou inexistentes não faz nada nem avisa', () {
      final controller = frase(['A', 'B', 'C']);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller
        ..move(1, 1)
        ..move(-1, 0)
        ..move(0, 3)
        ..move(5, 1);

      expect(labelsOf(controller), ['A', 'B', 'C']);
      expect(notifications, 0);
    });

    test('removeAt e move avisam uma vez cada', () {
      final controller = frase(['A', 'B', 'C']);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.move(0, 2);
      expect(notifications, 1);
      controller.removeAt(0);
      expect(notifications, 2);
    });

    test('cada entrada tem um id próprio que acompanha o item ao mover', () {
      final controller = frase(['Quero', 'Água', 'Quero']);
      final ids = controller.entries.map((e) => e.id).toList();

      expect(ids.toSet(), hasLength(3)); // até palavras iguais têm ids diferentes

      controller.move(0, 2);
      expect(
        controller.entries.map((e) => e.id).toList(),
        [ids[1], ids[2], ids[0]],
      );
    });

    test('um id removido não é reaproveitado', () {
      final controller = frase(['A', 'B']);
      final removedId = controller.entries.last.id;

      controller
        ..removeAt(1)
        ..add(_item('C'));

      expect(controller.entries.map((e) => e.id), isNot(contains(removedId)));
    });

    test('as entradas não podem ser alteradas por fora', () {
      final controller = frase(['A']);

      expect(
        () => controller.entries.add(controller.entries.first),
        throwsUnsupportedError,
      );
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
