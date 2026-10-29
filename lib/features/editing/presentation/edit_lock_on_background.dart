import 'package:flutter/widgets.dart';
import 'package:prifono_caa/app/app_scope.dart';

/// Trava o modo de edição quando o app deixa de ser visível (vai para
/// segundo plano). Fica uma vez só, em volta da tela inicial.
class EditLockOnBackground extends StatefulWidget {
  const EditLockOnBackground({required this.child, super.key});

  final Widget child;

  @override
  State<EditLockOnBackground> createState() => _EditLockOnBackgroundState();
}

class _EditLockOnBackgroundState extends State<EditLockOnBackground> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // getInheritedWidgetOfExactType (usado pelo AppScope.of) pode ser chamado
    // no initState; dependOn... não poderia.
    final editMode = AppScope.of(context).editMode;
    // Ao sair do app o sistema passa por "oculto" e depois "pausado"; travar
    // nos dois é inofensivo (lock é idempotente) e não depende da ordem.
    _lifecycle = AppLifecycleListener(
      onHide: editMode.lock,
      onPause: editMode.lock,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
