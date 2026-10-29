import 'package:flutter/widgets.dart';
import 'package:prifono_caa/features/boards/domain/board_repository.dart';
import 'package:prifono_caa/features/sentence/presentation/sentence_controller.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/speech/data/silent_speech_service.dart';
import 'package:prifono_caa/features/speech/domain/speech_service.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';

/// Disponibiliza dependências para toda a árvore de widgets.
///
/// Os controllers avisam sozinhos quando mudam (ChangeNotifier), então o
/// escopo não precisa notificar: [updateShouldNotify] só reage à troca das
/// próprias dependências, e usamos getInheritedWidgetOfExactType (sem criar
/// dependência de rebuild).
class AppScope extends InheritedWidget {
  AppScope({
    required this.settings,
    required this.boards,
    required this.symbols,
    required this.symbolImages,
    required super.child,
    this.speech = const SilentSpeechService(),
    SentenceController? sentence,
    super.key,
  }) : sentence = sentence ?? SentenceController();

  final SettingsController settings;
  final BoardRepository boards;
  final SymbolProvider symbols;
  final SymbolImageStore symbolImages;

  /// Voz do app. O padrão é silencioso (testes não precisam passar nada);
  /// o `main.dart` entrega a voz real (ADR-033).
  final SpeechService speech;

  /// Frase em montagem (E5-2). Vive aqui para sobreviver à navegação entre
  /// pranchas. Se ninguém passar uma, o escopo cria a sua: o `AppScope` é
  /// criado uma vez só no `main.dart` e nunca reconstruído, então a frase
  /// não se perde.
  final SentenceController sentence;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado acima na árvore de widgets.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return settings != oldWidget.settings ||
        boards != oldWidget.boards ||
        symbols != oldWidget.symbols ||
        symbolImages != oldWidget.symbolImages ||
        speech != oldWidget.speech ||
        sentence != oldWidget.sentence;
  }
}