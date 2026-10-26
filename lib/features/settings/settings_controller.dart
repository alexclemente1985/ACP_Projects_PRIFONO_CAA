import 'package:flutter/material.dart';
import 'package:prifono_caa/features/settings/data/in_memory_settings_repository.dart';
import 'package:prifono_caa/features/settings/domain/settings_repository.dart';

/// Configurações do app. Atualiza a tela primeiro (otimista) e grava depois.
class SettingsController extends ChangeNotifier {
  SettingsController({SettingsRepository? repository})
      : _repository = repository ?? InMemorySettingsRepository();

  static const String themeModeKey = 'theme_mode';

  final SettingsRepository _repository;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Carrega as preferências salvas. Chamar uma vez, antes do primeiro frame.
  Future<void> load() async {
    final stored = await _repository.read(themeModeKey);
    // Valor desconhecido ou corrompido cai no padrão, nunca quebra o app.
    final loaded = ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
    if (loaded == _themeMode) return;
    _themeMode = loaded;
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
}