import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/editing/presentation/edit_mode_controller.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';

/// Vigia do modo de edição (E6-5, ADR-041, decisão 5). Fica ACIMA do Navigator
/// (no `builder` do `MaterialApp`) e cuida de duas coisas:
///
/// 1. Bloqueio por inatividade: enquanto se edita, cada toque, tecla ou
///    digitação reinicia uma contagem; se ela chega ao fim, a edição trava e o
///    app avisa em um SnackBar.
/// 2. Ao travar, por QUALQUER motivo (cadeado, segundo plano, inatividade),
///    fecha menus, diálogos e folhas abertos. Sem isso, um diálogo de
///    "Excluir" esquecido aberto poderia ser confirmado com a edição travada.
///    (Telas inteiras abertas por cima, como o editor de card, se fecham sozinhas.)
///
/// A contagem fica PARADA com leitor de tela ligado: TalkBack e VoiceOver
/// ativam botões por ações de acessibilidade, que não geram toques na tela, e
/// travar a edição no meio de uma tarefa seria pior do que não travar.
/// (Suposição a validar com TalkBack em aparelho real.)
///
/// O [Timer] mora no State de propósito: é cancelado em `dispose`, e um Timer
/// solto em um objeto fora da árvore ficaria pendente nos testes.
class EditIdleGuard extends StatefulWidget {
  const EditIdleGuard({
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  /// Navigator do app (o vigia está acima dele e não o enxerga pelo contexto).
  final GlobalKey<NavigatorState> navigatorKey;

  final Widget child;

  @override
  State<EditIdleGuard> createState() => _EditIdleGuardState();
}

class _EditIdleGuardState extends State<EditIdleGuard> {
  // `AppScope.of` usa getInheritedWidgetOfExactType, que pode ser chamado no
  // initState.
  late final EditModeController _editMode = AppScope.of(context).editMode;
  late final SettingsController _settings = AppScope.of(context).settings;

  Timer? _timer;
  late bool _wasEditing;
  bool _screenReaderOn = false;

  @override
  void initState() {
    super.initState();
    _wasEditing = _editMode.isEditing;
    _editMode.addListener(_onEditModeChanged);
    _editMode.activity.addListener(_restart);
    _settings.addListener(_restart);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenReaderOn = MediaQuery.accessibleNavigationOf(context);
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _editMode.removeListener(_onEditModeChanged);
    _editMode.activity.removeListener(_restart);
    _settings.removeListener(_restart);
    super.dispose();
  }

  /// (Re)arma a contagem, se ela fizer sentido agora.
  void _restart() {
    _timer?.cancel();
    _timer = null;
    if (!_editMode.isEditing || _screenReaderOn) return;
    final timeout = _settings.editIdleTimeout;
    if (timeout == null) return;
    _timer = Timer(timeout, _editMode.lockForInactivity);
  }

  void _onEditModeChanged() {
    final editing = _editMode.isEditing;
    final changed = editing != _wasEditing;
    _wasEditing = editing;
    _restart();
    if (!changed || editing || !mounted) return;

    // Travou: nada de menu ou diálogo aberto sobrevive ao bloqueio.
    widget.navigatorKey.currentState?.popUntil(
      (route) => route is! PopupRoute<dynamic>,
    );

    if (_editMode.lastLockWasIdle) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.editIdleLockedNotice)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _editMode.registerActivity(),
      onPointerUp: (_) => _editMode.registerActivity(),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          _editMode.registerActivity();
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }
}
