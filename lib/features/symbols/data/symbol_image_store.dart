import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

/// Guarda no aparelho as imagens dos símbolos que o usuário ESCOLHEU.
///
/// Cache mínimo (exigência do modelo ARASAAC): miniaturas de busca não
/// passam por aqui. Estrutura: `<root>/<fonte>/<id>_<pixels>.png`
class SymbolImageStore {
  SymbolImageStore({
    required this.root,
    required this._provider,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final Directory root;
  final Duration timeout;
  final SymbolProvider _provider;
  final http.Client _client;

  /// Downloads em andamento, por caminho de arquivo (evita baixar 2x).
  final Map<String, Future<File>> _inFlight = {};

  static const List<int> _pngSignature = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  ];

  /// Valida a referência e devolve a URL de origem.
  /// A validação do id (só dígitos) impede caminho malicioso vindo de um
  /// arquivo importado.
  Uri _validatedUri(SymbolRef ref, SymbolImageSize size) {
    if (ref.source != _provider.sourceId) {
      throw ArgumentError.value(ref.source, 'ref.source', 'fonte desconhecida');
    }
    return _provider.imageUri(ref.id, size: size);
  }

  /// Onde o arquivo fica (existindo ou não).
  File fileFor(SymbolRef ref, {SymbolImageSize size = SymbolImageSize.medium}) {
    _validatedUri(ref, size);
    return File(p.join(root.path, ref.source, '${ref.id}_${size.pixels}.png'));
  }

  bool isCached(
    SymbolRef ref, {
    SymbolImageSize size = SymbolImageSize.medium,
  }) {
    return fileFor(ref, size: size).existsSync();
  }

  /// Devolve o arquivo local, baixando se ainda não existir.
  /// Lança [SymbolProviderException] se a rede falhar.
  Future<File> ensure(
    SymbolRef ref, {
    SymbolImageSize size = SymbolImageSize.medium,
  }) async {
    final uri = _validatedUri(ref, size);
    final file = fileFor(ref, size: size);
    if (file.existsSync()) return file;

    final key = file.path;
    return _inFlight[key] ??= _download(uri, file).whenComplete(() {
      // Chaves { }: se fosse `=> _inFlight.remove(key)`, o whenComplete
      // esperaria o próprio Future que está removendo (travaria).
      _inFlight.remove(key);
    });
  }

  Future<File> _download(Uri uri, File file) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const SymbolProviderException(SymbolErrorKind.timeout);
    } on IOException catch (error) {
      throw SymbolProviderException(SymbolErrorKind.offline, '$error');
    } on http.ClientException catch (error) {
      throw SymbolProviderException(SymbolErrorKind.offline, error.message);
    }

    if (response.statusCode != 200) {
      throw SymbolProviderException(
        response.statusCode >= 500
            ? SymbolErrorKind.server
            : SymbolErrorKind.badResponse,
        'HTTP ${response.statusCode}',
      );
    }
    if (!_looksLikePng(response.bodyBytes)) {
      throw const SymbolProviderException(
        SymbolErrorKind.badResponse,
        'o conteúdo não é uma imagem PNG',
      );
    }

    // Escrita atômica: grava num .tmp e renomeia. Se o app for fechado no meio,
    // nunca sobra um PNG pela metade com o nome final.
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(response.bodyBytes, flush: true);
    await temp.rename(file.path);
    return file;
  }

  bool _looksLikePng(List<int> bytes) {
    if (bytes.length < _pngSignature.length) return false;
    for (var i = 0; i < _pngSignature.length; i++) {
      if (bytes[i] != _pngSignature[i]) return false;
    }
    return true;
  }

  void close() => _client.close();
}
