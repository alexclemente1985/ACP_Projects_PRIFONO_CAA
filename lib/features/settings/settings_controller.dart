import 'package:flutter/material.dart';
import 'package:prifono_caa/features/pin/domain/pin.dart';
import 'package:prifono_caa/features/settings/data/in_memory_settings_repository.dart';
import 'package:prifono_caa/features/settings/domain/app_language.dart';
import 'package:prifono_caa/features/settings/domain/edit_idle_timeout.dart';
import 'package:prifono_caa/features/settings/domain/settings_repository.dart';

/// Configurações do app. Tema e idioma atualizam a tela primeiro (otimista) e
/// gravam depois; o PIN só vale depois de gravado (ADR-040).
class SettingsController extends ChangeNotifier {
  /// [defaultLanguage] vale quando nada foi gravado. O `main.dart` passa
  /// [AppLanguage.system] (segue o aparelho, ADR-034); o padrão em português
  /// mantém os testes de widget estáveis, independentes do idioma da máquina.
  /// [deviceLocales] são os idiomas preferidos do aparelho, do mais para o
  /// menos preferido (o `main.dart` informa os reais; depois o app avisa as
  /// mudanças por [deviceLocalesChanged]). Sem informar, vale inglês.
  SettingsController({
    SettingsRepository? repository,
    this.defaultLanguage = AppLanguage.portuguese,
    List<Locale>? deviceLocales,
  })  : _repository = repository ?? InMemorySettingsRepository(),
        _language = defaultLanguage,
        _deviceLocales = deviceLocales ?? const [Locale('en')];

  static const String themeModeKey = 'theme_mode';

  /// Idioma escolhido: system, portuguese, spanish ou english.
  static const String languageKey = 'app_language';

  /// PIN do modo de edição em texto (4 dígitos). Vazio = sem PIN.
  static const String editPinKey = 'edit_pin';

  /// Minutos sem toque até a edição travar sozinha (0 = desligado; E6-5).
  static const String editIdleMinutesKey = 'edit_idle_minutes';

  final SettingsRepository _repository;
  final AppLanguage defaultLanguage;
  ThemeMode _themeMode = ThemeMode.system;
  String? _pin;
  int _editIdleMinutes = EditIdleTimeout.defaultMinutes;
  AppLanguage _language;
  List<Locale> _deviceLocales;

  ThemeMode get themeMode => _themeMode;

  /// A ESCOLHA da pessoa (pode ser o Automático).
  AppLanguage get language => _language;

  /// O idioma em uso agora, nunca o Automático: segue o aparelho quando a
  /// escolha é [AppLanguage.system]. Textos, busca e voz leem este valor.
  AppLanguage get effectiveLanguage => _language == AppLanguage.system
      ? AppLanguage.fromLocales(_deviceLocales)
      : _language;

  /// O modo de edição pede PIN?
  bool get hasPin => _pin != null;

  /// Minutos sem toque até a edição travar sozinha; 0 = nunca.
  int get editIdleMinutes => _editIdleMinutes;

  /// O mesmo valor como tempo de espera; `null` = o bloqueio está desligado.
  Duration? get editIdleTimeout => EditIdleTimeout.toDuration(_editIdleMinutes);

  /// Carrega as preferências salvas. Chamar uma vez, antes do primeiro frame.
  Future<void> load() async {
    final stored = await _repository.read(themeModeKey);
    // Valor desconhecido ou corrompido cai no padrão, nunca quebra o app.
    final loaded = ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
    // PIN gravado errado vale como "sem PIN": melhor não travar a pessoa fora
    // do próprio app.
    final storedPin = await _repository.read(editPinKey);
    final loadedPin = PinRules.isValid(storedPin) ? storedPin : null;
    final loadedLanguage = AppLanguage.fromStorage(
          await _repository.read(languageKey),
        ) ??
        defaultLanguage;
    final loadedIdle = EditIdleTimeout.fromStorage(
      await _repository.read(editIdleMinutesKey),
    );
    if (loaded == _themeMode &&
        loadedPin == _pin &&
        loadedLanguage == _language &&
        loadedIdle == _editIdleMinutes) {
      return;
    }
    _themeMode = loaded;
    _pin = loadedPin;
    _language = loadedLanguage;
    _editIdleMinutes = loadedIdle;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    try {
      await _repository.write(languageKey, language.storageValue);
    } on Exception catch (error) {
      // Mesma regra do tema: a escolha vale nesta sessão mesmo sem gravar.
      debugPrint('Falha ao salvar o idioma: $error');
    }
  }

  /// O aparelho mudou de idioma com o app aberto. Só notifica se isso muda o
  /// idioma em uso (escolha Automático e outro idioma traduzido).
  void deviceLocalesChanged(List<Locale> locales) {
    final before = effectiveLanguage;
    _deviceLocales = List.unmodifiable(locales);
    if (effectiveLanguage != before) notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return; // não notifica sem mudança real
    _themeMode = mode;
    notifyListeners();
    try {
      await _repository.write(themeModeKey, mode.name);
    } on Exception catch (error) {
      // Não conseguir salvar uma preferência não pode derrubar o app.
      debugPrint('Falha ao salvar o tema: $error');
    }
  }

  /// Escolhe em quantos minutos sem toque a edição trava sozinha (0 = nunca).
  /// Atualiza a tela primeiro e grava depois, como o tema (E6-5).
  Future<void> setEditIdleMinutes(int minutes) async {
    if (!EditIdleTimeout.options.contains(minutes)) {
      throw ArgumentError.value(minutes, 'minutes', 'fora das opções');
    }
    if (minutes == _editIdleMinutes) return;
    _editIdleMinutes = minutes;
    notifyListeners();
    try {
      await _repository.write(editIdleMinutesKey, minutes.toString());
    } on Exception catch (error) {
      debugPrint('Falha ao salvar o bloqueio por inatividade: $error');
    }
  }

  /// O [entered] é o PIN? Sem PIN ligado, nada confere.
  bool checkPin(String entered) => _pin != null && entered == _pin;

  /// Liga (ou troca) o PIN. Só passa a valer depois de gravado: se a gravação
  /// falhar, a exceção sobe e o PIN anterior continua valendo.
  Future<void> setPin(String pin) async {
    if (!PinRules.isValid(pin)) {
      throw ArgumentError.value(pin, 'pin', 'deve ter exatamente 4 dígitos');
    }
    await _repository.write(editPinKey, pin);
    _pin = pin;
    notifyListeners();
  }

  /// Desliga o PIN. Mesma regra de [setPin]: falhou ao gravar, continua ligado.
  Future<void> clearPin() async {
    if (_pin == null) return;
    await _repository.write(editPinKey, '');
    _pin = null;
    notifyListeners();
  }
}
