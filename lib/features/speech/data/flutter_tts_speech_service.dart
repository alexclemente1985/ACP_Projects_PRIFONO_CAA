import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:prifono_caa/features/speech/domain/speech_service.dart';

/// Voz do aparelho (pacote `flutter_tts`) (ADR-033, ADR-034).
///
/// O idioma da voz é o [language] fixo (padrão pt-BR) ou, se informado, o que
/// [languageSource] devolve no momento da fala: assim a troca de idioma nos
/// Ajustes vale no toque seguinte. A voz é preparada uma vez por idioma, na
/// primeira fala ou em [warmUp]. Se o aparelho não tem voz no idioma,
/// [speak] lança [SpeechErrorKind.voiceUnavailable] e tenta preparar de novo
/// no toque seguinte (a pessoa pode instalar a voz com o app aberto). Nunca
/// fala em outro idioma por engano.
class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService({
    FlutterTts? tts,
    String language = defaultLanguage,
    this.languageSource,
  })  : _tts = tts ?? FlutterTts(),
        _fixedLanguage = language;

  static const String defaultLanguage = 'pt-BR';

  final FlutterTts _tts;
  final String _fixedLanguage;
  final String Function()? languageSource;

  /// Idioma da voz em uso agora, ex.: 'pt-BR', 'es-ES', 'en-US'.
  String get language => languageSource?.call() ?? _fixedLanguage;

  bool _iosConfigured = false;
  String? _preparedLanguage;

  /// Prepara a voz antes do primeiro toque, para a primeira fala não esperar o
  /// motor iniciar. Erros são só registrados: o aviso aparece no primeiro toque.
  Future<void> warmUp() async {
    try {
      await _prepare();
    } on Exception catch (error) {
      debugPrint('Voz: não foi possível preparar agora: $error');
    }
  }

  Future<void> _prepare() async {
    // Lido uma vez: o idioma não pode mudar no meio da preparação.
    final wanted = language;
    if (_preparedLanguage == wanted) return;
    if (!_iosConfigured && Platform.isIOS) {
      // A pessoa que se comunica por voz sintética precisa ser ouvida mesmo com
      // a chave de silêncio do iPhone ligada: categoria "playback".
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, []);
      _iosConfigured = true;
    }
    final available = await _tts.isLanguageAvailable(wanted);
    if (available != true && available != 1) {
      throw SpeechException(SpeechErrorKind.voiceUnavailable, wanted);
    }
    await _tts.setLanguage(wanted);
    _preparedLanguage = wanted;
  }

  @override
  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    try {
      await _prepare();
      // Sem isto, no iOS toques seguidos entrariam numa fila de falas.
      await _tts.stop();
      final result = await _tts.speak(clean);
      if (result == 0) {
        throw const SpeechException(SpeechErrorKind.failed, 'speak devolveu 0');
      }
    } on PlatformException catch (error) {
      throw SpeechException(SpeechErrorKind.failed, error.message);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on PlatformException catch (error) {
      debugPrint('Voz: falha ao interromper: $error');
    }
  }
}
