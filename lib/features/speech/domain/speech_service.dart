/// Fala textos em voz alta. O resto do app só conhece esta interface; o pacote
/// de voz fica isolado em `FlutterTtsSpeechService` (ADR-005, ADR-033).
abstract interface class SpeechService {
  /// Fala [text], interrompendo qualquer fala em andamento. Texto vazio não
  /// faz nada. Lança [SpeechException] se não foi possível falar.
  Future<void> speak(String text);

  /// Interrompe a fala em andamento.
  Future<void> stop();
}

enum SpeechErrorKind {
  /// Não há voz em português do Brasil instalada no aparelho.
  voiceUnavailable,

  /// A voz existe, mas a fala falhou.
  failed,
}

class SpeechException implements Exception {
  const SpeechException(this.kind, [this.detail]);

  final SpeechErrorKind kind;
  final String? detail;

  @override
  String toString() {
    return 'SpeechException($kind${detail == null ? '' : ': $detail'})';
  }
}
