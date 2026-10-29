import 'package:prifono_caa/features/speech/domain/speech_service.dart';

/// Voz que não faz nada. É o padrão do `AppScope`, para que os testes de
/// widget não precisem de plugin nativo.
class SilentSpeechService implements SpeechService {
  const SilentSpeechService();

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}
