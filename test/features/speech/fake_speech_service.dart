import 'package:prifono_caa/features/speech/domain/speech_service.dart';

/// Voz falsa para testes: guarda o que foi "falado" e pode falhar de propósito.
/// (O nome do arquivo não termina em `_test` de propósito: é só um apoio.)
class FakeSpeechService implements SpeechService {
  final List<String> spoken = [];
  int stopCount = 0;

  /// Se não for nulo, [speak] lança esta exceção em vez de "falar".
  SpeechException? failure;

  @override
  Future<void> speak(String text) async {
    final error = failure;
    if (error != null) throw error;
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }
}
