import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/speech/data/flutter_tts_speech_service.dart';
import 'package:prifono_caa/features/speech/domain/speech_service.dart';

/// Idioma da voz (ADR-034). Mesma técnica do teste principal: o canal nativo
/// do plugin é trocado por um falso. A voz de verdade só se testa no aparelho.
const MethodChannel _channel = MethodChannel('flutter_tts');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late Set<String> installedVoices;

  setUp(() {
    calls = [];
    installedVoices = {'pt-BR', 'es-ES', 'en-US'};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      if (call.method == 'isLanguageAvailable') {
        return installedVoices.contains(call.arguments);
      }
      if (call.method == 'speak') return 1;
      return 1;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  List<String> languagesSet() => calls
      .where((c) => c.method == 'setLanguage')
      .map((c) => c.arguments.toString())
      .toList();

  int count(String method) => calls.where((c) => c.method == method).length;

  test('languageSource define o idioma da voz', () async {
    final service = FlutterTtsSpeechService(languageSource: () => 'es-ES');

    await service.speak('Hola');

    expect(service.language, 'es-ES');
    expect(languagesSet(), ['es-ES']);
  });

  test('trocar o idioma prepara a voz de novo, só uma vez por idioma',
      () async {
    var language = 'pt-BR';
    final service = FlutterTtsSpeechService(languageSource: () => language);

    await service.speak('Oi');
    await service.speak('Tchau'); // mesmo idioma: não prepara de novo
    language = 'en-US';
    await service.speak('Hello');
    await service.speak('Bye');

    expect(languagesSet(), ['pt-BR', 'en-US']);
    expect(count('isLanguageAvailable'), 2);
    expect(count('speak'), 4);
  });

  test('voltar a um idioma anterior reconfigura a voz', () async {
    var language = 'pt-BR';
    final service = FlutterTtsSpeechService(languageSource: () => language);

    await service.speak('Oi');
    language = 'es-ES';
    await service.speak('Hola');
    language = 'pt-BR';
    await service.speak('Oi de novo');

    expect(languagesSet(), ['pt-BR', 'es-ES', 'pt-BR']);
  });

  test('sem voz no idioma novo avisa e não fala em outro idioma', () async {
    var language = 'pt-BR';
    final service = FlutterTtsSpeechService(languageSource: () => language);
    await service.speak('Oi');
    installedVoices.remove('es-ES');
    language = 'es-ES';

    await expectLater(
      service.speak('Hola'),
      throwsA(
        isA<SpeechException>()
            .having((e) => e.kind, 'kind', SpeechErrorKind.voiceUnavailable)
            .having((e) => e.detail, 'detail', 'es-ES'),
      ),
    );

    expect(count('speak'), 1); // só a primeira fala, em português
    expect(languagesSet(), ['pt-BR']);
  });

  test('instalar a voz depois do aviso funciona no toque seguinte', () async {
    installedVoices.remove('es-ES');
    final service = FlutterTtsSpeechService(languageSource: () => 'es-ES');
    await expectLater(service.speak('Hola'), throwsA(isA<SpeechException>()));

    installedVoices.add('es-ES');
    await service.speak('Hola');

    expect(count('speak'), 1);
    expect(languagesSet(), ['es-ES']);
  });

  test('sem languageSource continua em pt-BR', () async {
    final service = FlutterTtsSpeechService();

    await service.speak('Oi');

    expect(service.language, 'pt-BR');
    expect(languagesSet(), ['pt-BR']);
  });
}
