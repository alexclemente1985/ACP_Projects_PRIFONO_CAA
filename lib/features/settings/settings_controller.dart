import 'package:flutter/material.dart';
import 'package:prifono_caa/features/pin/domain/pin.dart';
import 'package:prifono_caa/features/settings/data/in_memory_settings_repository.dart';
import 'package:prifono_caa/features/settings/domain/settings_repository.dart';

/// Configurações do app. O tema atualiza a tela primeiro (otimista) e grava
/// depois; o PIN só vale depois de gravado (ADR-040).
class SettingsController extends ChangeNotifier {
  SettingsController({SettingsRepository? repository})
      : _repository = repository ?? InMemorySettingsRepository();

  static const String themeModeKey = 'theme_mode';

  /// PIN do modo de edição em texto (4 dígitos). Vazio = sem PIN.
  static const String editPinKey = 'edit_pin';

  final SettingsRepository _repository;
  ThemeMode _themeMode = ThemeMode.system;
  String? _pin;

  ThemeMode get themeMode => _themeMode;

  /// O modo de edição pede PIN?
  bool get hasPin => _pin != null;

  /// Carrega as preferências salvas. Chamar uma vez, antes do primeiro frame.
  Future<void> load() async {
    final stored = await _repository.read(themeModeKey);
    // Valor desconhecido ou corrompido cai no padrão, nunca quebra o app.
    final loaded = ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
    // PIN gravado errado vale como "sem PIN": melhor não travar a pessoa fora
    // do próprio app.
    final storedPin = await _repository.read(editPinKey);
    final loadedPin = PinRules.isValid(storedPin) ? storedPin : null;
    if (loaded == _themeMode && loadedPin == _pin) return;
    _themeMode = loaded;
    _pin = loadedPin;
    notifyListeners();
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
