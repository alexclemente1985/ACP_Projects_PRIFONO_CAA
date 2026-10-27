import 'package:flutter/widgets.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';

/// Disponibiliza dependências para toda a árvore de widgets.
///
/// Os controllers avisam sozinhos quando mudam (ChangeNotifier), então o
/// escopo não precisa notificar: [updateShouldNotify] só reage à troca das
/// próprias dependências, e usamos getInheritedWidgetOfExactType (sem criar
/// dependência de rebuild).
class AppScope extends InheritedWidget {
  const AppScope({
    required this.settings,
    required this.symbols,
    required this.symbolImages,
    required super.child,
    super.key,
  });

  final SettingsController settings;
  final SymbolProvider symbols;
  final SymbolImageStore symbolImages;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado acima na árvore de widgets.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return settings != oldWidget.settings ||
        symbols != oldWidget.symbols ||
        symbolImages != oldWidget.symbolImages;
  }
}