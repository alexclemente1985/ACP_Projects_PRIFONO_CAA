import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_result.dart';

/// Provider do ARASAAC.
///
/// Rotas e formato verificados na especificação OpenAPI oficial
/// (repositório Arasaac/public-api, config/openapi_v1.yml, 17/09/2026).
class ArasaacProvider implements SymbolProvider {
  ArasaacProvider({
    http.Client? client,
    this.locale = defaultLocale,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  /// 'br' parece ser português do Brasil (inferência: o código do ARASAAC o
  /// trata como 'pt' na busca textual). Confirmado pelo teste live.
  static const String defaultLocale = 'br';

  static const String _apiHost = 'api.arasaac.org';
  static const String _apiVersion = 'v1';
  static const String _staticHost = 'static.arasaac.org';
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  final http.Client _client;
  final String locale;
  final Duration timeout;

  @override
  String get sourceId => SymbolRef.arasaac;

  @override
  Future<List<SymbolResult>> search(
    String text, {
    bool includeSensitive = false,
  }) async {
    final query = text.trim();
    if (query.isEmpty) return const [];

    // pathSegments codifica cada trecho (acentos, espaços, "/" etc.).
    final uri = Uri(
      scheme: 'https',
      host: _apiHost,
      pathSegments: [_apiVersion, 'pictograms', locale, 'search', query],
    );

    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw const SymbolProviderException(SymbolErrorKind.timeout);
    } on IOException catch (error) {
      throw SymbolProviderException(SymbolErrorKind.offline, '$error');
    } on http.ClientException catch (error) {
      throw SymbolProviderException(SymbolErrorKind.offline, error.message);
    }

    // A API responde 404 com [] quando não há resultado.
    if (response.statusCode == 404) return const [];
    if (response.statusCode >= 500 || response.statusCode == 429) {
      throw SymbolProviderException(
        SymbolErrorKind.server,
        'HTTP ${response.statusCode}',
      );
    }
    if (response.statusCode != 200) {
      throw SymbolProviderException(
        SymbolErrorKind.badResponse,
        'HTTP ${response.statusCode}',
      );
    }

    final Object? decoded;
    try {
      // UTF-8 explícito: response.body assumiria latin1 sem charset.
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      throw SymbolProviderException(SymbolErrorKind.badResponse, error.message);
    }
    if (decoded is! List<Object?>) {
      throw const SymbolProviderException(
        SymbolErrorKind.badResponse,
        'resposta não é uma lista',
      );
    }

    final results = <SymbolResult>[];
    for (final item in decoded) {
      final result = _parse(item);
      if (result == null) continue; // item malformado é ignorado
      if (result.isSensitive && !includeSensitive) continue;
      results.add(result);
    }
    return results;
  }

  @override
  Uri imageUri(
    String symbolId, {
    SymbolImageSize size = SymbolImageSize.medium,
  }) {
    if (!_digitsOnly.hasMatch(symbolId)) {
      throw ArgumentError.value(
        symbolId,
        'symbolId',
        'deve conter apenas dígitos',
      );
    }
    return Uri.https(
      _staticHost,
      '/pictograms/$symbolId/${symbolId}_${size.pixels}.png',
    );
  }

  void close() => _client.close();

  /// Leitura defensiva: a API não é nossa, então nada é presumido.
  SymbolResult? _parse(Object? item) {
    if (item is! Map<String, Object?>) return null;

    final id = item['_id'];
    if (id is! int) return null;

    final keywords = <String>[];
    final rawKeywords = item['keywords'];
    if (rawKeywords is List<Object?>) {
      for (final entry in rawKeywords) {
        if (entry is! Map<String, Object?>) continue;
        final word = entry['keyword'];
        if (word is String && word.trim().isNotEmpty) {
          keywords.add(word.trim());
        }
      }
    }

    return SymbolResult(
      id: id.toString(),
      keywords: keywords,
      isSensitive: item['sex'] == true || item['violence'] == true,
    );
  }
}
