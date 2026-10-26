import 'package:flutter/material.dart';

/// Configurações do app em memória.
/// Na E2 passa a persistir em SQLite; a interface pública não muda.
class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return; // não notifica sem mudança real
    _themeMode = mode;
    notifyListeners();
  }
}
