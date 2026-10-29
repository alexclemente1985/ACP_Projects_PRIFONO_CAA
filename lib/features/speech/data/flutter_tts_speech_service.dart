import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:prifono_caa/features/speech/domain/speech_service.dart';

/// Voz do aparelho (pacote `flutter_tts`) em português do Brasil (ADR-033).
///
/// A voz é preparada uma vez, na primeira fala ou em [warmUp]. Se o aparelho
/// não tem voz em pt-BR, [speak] lança [SpeechErrorKind.voiceUnavailable] e
/// tenta preparar de novo no toque seguinte (a pessoa pode instalar a voz com
/// o app aberto). Nunca fala em outro idioma por engano.
class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService({FlutterTts? tts, this.language = defaultLanguage})
      : _tts = tts ?? FlutterTts();

  static const String defaultLanguage = 'pt-BR';

  final FlutterTts _tts;
  final String language;
  bool _ready = false;

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
    if (_ready) return;
    if (Platform.isIOS) {
      // A pessoa que se comunica por voz sintética precisa ser ouvida mesmo com
      // a chave de silêncio do iPhone ligada: categoria "playback".
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, []);
    }
    final available = await _tts.isLanguageAvailable(language);
    if (available != true && available != 1) {
      throw SpeechException(SpeechErrorKind.voiceUnavailable, language);
    }
    await _tts.setLanguage(language);
    _ready = true;
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
