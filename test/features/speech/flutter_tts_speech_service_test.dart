import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/speech/data/flutter_tts_speech_service.dart';
import 'package:prifono_caa/features/speech/domain/speech_service.dart';

/// Testa a NOSSA lógica (preparar a voz uma vez, pt-BR, avisos) trocando o
/// canal nativo do plugin por um falso. O motor de voz de verdade só se testa
/// no aparelho (checklist do E5-1).
const MethodChannel _channel = MethodChannel('flutter_tts');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late bool languageAvailable;
  late Object speakResult;

  setUp(() {
    calls = [];
    languageAvailable = true;
    speakResult = 1;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      if (call.method == 'isLanguageAvailable') return languageAvailable;
      if (call.method == 'speak') return speakResult;
      return 1;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  int count(String method) => calls.where((c) => c.method == method).length;

  test('prepara a voz em pt-BR uma vez e fala cada texto', () async {
    final service = FlutterTtsSpeechService();

    await service.speak('Oi');
    await service.speak('Tchau');

    expect(count('isLanguageAvailable'), 1);
    expect(count('setLanguage'), 1);
    expect(count('speak'), 2);
    final setLanguage = calls.firstWhere((c) => c.method == 'setLanguage');
    expect(setLanguage.arguments.toString(), contains('pt-BR'));
    final lastSpeak = calls.lastWhere((c) => c.method == 'speak');
    expect(lastSpeak.arguments.toString(), contains('Tchau'));
  });

  test('texto vazio não chama a voz', () async {
    final service = FlutterTtsSpeechService();

    await service.speak('   ');

    expect(calls.where((c) => c.method == 'speak'), isEmpty);
  });

  test('sem voz pt-BR lança voiceUnavailable e tenta de novo depois', () async {
    languageAvailable = false;
    final service = FlutterTtsSpeechService();

    await expectLater(
      service.speak('Oi'),
      throwsA(
        isA<SpeechException>().having(
          (e) => e.kind,
          'kind',
          SpeechErrorKind.voiceUnavailable,
        ),
      ),
    );
    expect(count('speak'), 0);

    // A pessoa instalou a voz com o app aberto.
    languageAvailable = true;
    await service.speak('Oi');
    expect(count('speak'), 1);
  });

  test('warmUp não lança mesmo sem voz pt-BR', () async {
    languageAvailable = false;
    final service = FlutterTtsSpeechService();

    await service.warmUp();

    expect(count('speak'), 0);
  });

  test('falha do plugin vira SpeechException(failed)', () async {
    speakResult = 0;
    final service = FlutterTtsSpeechService();

    await expectLater(
      service.speak('Oi'),
      throwsA(
        isA<SpeechException>().having(
          (e) => e.kind,
          'kind',
          SpeechErrorKind.failed,
        ),
      ),
    );
  });
}
