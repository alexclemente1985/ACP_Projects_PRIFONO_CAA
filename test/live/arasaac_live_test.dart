// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:prifono_caa/features/symbols/data/arasaac_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';

final bool _live = Platform.environment['ARASAAC_LIVE'] == '1';

void main() {
  // O flutter test troca o HttpClient por um falso que responde 400 a tudo.
  // Aqui queremos a rede de verdade.
  setUpAll(() => HttpOverrides.global = null);

  test(
    'busca real em br e pt e baixa uma imagem',
    () async {
      final br = ArasaacProvider();
      final pt = ArasaacProvider(locale: 'pt');

      for (final word in ['casa', 'ônibus', 'autocarro', 'criança']) {
        final inBr = await br.search(word);
        final inPt = await pt.search(word);
        final first = inBr.isEmpty ? '-' : '${inBr.first.id} ${inBr.first.keywords}';
        print('"$word": br=${inBr.length} pt=${inPt.length} | br[0]=$first');
      }

      final results = await br.search('casa');
      expect(results, isNotEmpty);

      final response = await http.get(
        br.imageUri(results.first.id, size: SymbolImageSize.small),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('image/png'));
      expect(response.bodyBytes.take(4).toList(), [0x89, 0x50, 0x4E, 0x47]);
      print('imagem ok: ${response.bodyBytes.length} bytes');
    },
    skip: _live ? false : 'defina ARASAAC_LIVE=1 para rodar',
  );
}
