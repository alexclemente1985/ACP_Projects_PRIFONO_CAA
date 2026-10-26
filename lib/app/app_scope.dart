import 'package:flutter/widgets.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';

/// Disponibiliza dependências para toda a árvore de widgets.
///
/// O próprio [SettingsController] avisa quando muda (ChangeNotifier), então o
/// escopo não precisa notificar: [updateShouldNotify] é sempre false e usamos
/// getInheritedWidgetOfExactType (sem criar dependência de rebuild).
class AppScope extends InheritedWidget {
  const AppScope({
    required this.settings,
    required super.child,
    super.key,
  });

  final SettingsController settings;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado acima na árvore de widgets.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => settings != oldWidget.settings;
}
