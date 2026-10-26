import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';

void main() {
  test('começa seguindo o sistema', () {
    expect(SettingsController().themeMode, ThemeMode.system);
  });

  test('notifica ao mudar o tema', () {
    final controller = SettingsController();
    var calls = 0;
    controller.addListener(() => calls++);

    controller.setThemeMode(ThemeMode.dark);

    expect(controller.themeMode, ThemeMode.dark);
    expect(calls, 1);
  });

  test('não notifica quando o valor é o mesmo', () {
    final controller = SettingsController();
    var calls = 0;
    controller.addListener(() => calls++);

    controller.setThemeMode(ThemeMode.system);

    expect(calls, 0);
  });
}