import 'package:prifono_caa/features/settings/domain/settings_repository.dart';

/// Implementação em memória: usada como padrão e nos testes (um "fake").
class InMemorySettingsRepository implements SettingsRepository {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}