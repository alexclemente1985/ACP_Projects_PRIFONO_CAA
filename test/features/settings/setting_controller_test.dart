import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/settings/data/in_memory_settings_repository.dart';
import 'package:prifono_caa/features/settings/domain/settings_repository.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';

/// Fake que sempre falha ao gravar.
class _FailingRepository implements SettingsRepository {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {
    throw Exception('disco cheio');
  }
}

void main() {
  test('começa seguindo o sistema', () {
    expect(SettingsController().themeMode, ThemeMode.system);
  });

  test('notifica ao mudar o tema', () async {
    final controller = SettingsController();
    var calls = 0;
    controller.addListener(() => calls++);

    await controller.setThemeMode(ThemeMode.dark);

    expect(controller.themeMode, ThemeMode.dark);
    expect(calls, 1);
  });

  test('não notifica quando o valor é o mesmo', () async {
    final controller = SettingsController();
    var calls = 0;
    controller.addListener(() => calls++);

    await controller.setThemeMode(ThemeMode.system);

    expect(calls, 0);
  });

  test('persiste e recarrega em uma nova instância', () async {
    final repository = InMemorySettingsRepository();
    await SettingsController(repository: repository)
        .setThemeMode(ThemeMode.dark);

    final reloaded = SettingsController(repository: repository);
    await reloaded.load();

    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('valor salvo inválido volta para "sistema"', () async {
    final repository = InMemorySettingsRepository();
    await repository.write(SettingsController.themeModeKey, 'roxo');

    final controller = SettingsController(repository: repository);
    await controller.load();

    expect(controller.themeMode, ThemeMode.system);
  });

  test('falha ao salvar não desfaz a escolha nem derruba o app', () async {
    final controller = SettingsController(repository: _FailingRepository());

    await controller.setThemeMode(ThemeMode.light);

    expect(controller.themeMode, ThemeMode.light);
  });
}