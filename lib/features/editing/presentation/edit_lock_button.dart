import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/pin/presentation/pin_flows.dart';

/// Cadeado da AppBar.
///
/// Em USO: é preciso SEGURAR por [holdDuration] para entrar em edição (um
/// anel mostra o progresso; soltar antes só mostra uma dica); se houver PIN, ele
/// é pedido em seguida (ADR-040). Em EDIÇÃO: um toque volta ao modo de uso.
///
/// Usa `Listener` (eventos brutos) e não `GestureDetector`/`Tooltip`: o
/// reconhecedor de toque longo do Tooltip cancelaria a contagem aos 500 ms.
///
/// Com leitor de tela ligado, entrar e sair da edição é ANUNCIADO (E6-2): uma
/// `SnackBar` (que o Flutter já trata como região viva) diz o novo estado. Sem
/// leitor de tela nada muda: a tela já mostra o estado.
class EditLockButton extends StatefulWidget {
  const EditLockButton({super.key});

  @override
  State<EditLockButton> createState() => _EditLockButtonState();
}

class _EditLockButtonState extends State<EditLockButton> {
  // `AppScope.of` usa getInheritedWidgetOfExactType, que pode ser chamado no
  // initState.
  late final _editMode = AppScope.of(context).editMode;
  late bool _wasEditing;

  @override
  void initState() {
    super.initState();
    _wasEditing = _editMode.isEditing;
    _editMode.addListener(_onEditModeChanged);
  }

  @override
  void dispose() {
    _editMode.removeListener(_onEditModeChanged);
    super.dispose();
  }

  void _onEditModeChanged() {
    final editing = _editMode.isEditing;
    if (editing == _wasEditing) return;
    _wasEditing = editing;
    if (!mounted) return;
    // Só a tela do topo anuncia (há um cadeado em cada tela da pilha) e só
    // quando há leitor de tela.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (!MediaQuery.accessibleNavigationOf(context)) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            editing ? l10n.editModeOnAnnounce : l10n.editModeOffAnnounce,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: _editMode,
      builder: (context, _) {
        if (_editMode.isEditing) {
          return IconButton(
            tooltip: l10n.editLockLeave,
            icon: const Icon(Icons.lock_open_outlined),
            onPressed: _editMode.lock,
          );
        }
        return const HoldToUnlock();
      },
    );
  }
}

/// A parte "segurar para destravar" do [EditLockButton].
class HoldToUnlock extends StatefulWidget {
  const HoldToUnlock({super.key});

  /// Tempo que o cadeado precisa ficar pressionado.
  static const Duration holdDuration = Duration(milliseconds: 1500);

  @override
  State<HoldToUnlock> createState() => _HoldToUnlockState();
}

class _HoldToUnlockState extends State<HoldToUnlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: HoldToUnlock.holdDuration,
  )..addStatusListener(_onStatus);

  bool _holding = false;

  /// Já há um pedido de PIN na tela? (segurar de novo não abre outro).
  bool _asking = false;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_holding) return;
    _holding = false;
    unawaited(_buzz());
    _hold.reset();
    unawaited(_unlock());
  }

  /// Liga a edição; com PIN, só depois de digitá-lo (ADR-040).
  Future<void> _unlock() async {
    if (_asking) return;
    _asking = true;
    try {
      await requestEditUnlock(context);
    } finally {
      _asking = false;
    }
  }

  /// Vibração curta ao destravar. Aparelhos sem vibração não são problema.
  Future<void> _buzz() async {
    try {
      await HapticFeedback.mediumImpact();
    } on Exception {
      // Sem vibração: o cadeado destrava do mesmo jeito.
    }
  }

  void _onDown(PointerDownEvent event) {
    _holding = true;
    unawaited(_hold.forward(from: 0));
  }

  void _onUp(PointerUpEvent event) {
    if (!_holding) return;
    _holding = false;
    _hold.reset();
    _showHint();
  }

  void _onCancel(PointerCancelEvent event) {
    _holding = false;
    _hold.reset();
  }

  void _showHint() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.editLockHoldHint)));
  }

  /// Leitores de tela: "tocar e segurar" do TalkBack/VoiceOver é uma ação
  /// própria, então destrava direto.
  void _unlockForAccessibility() => unawaited(_unlock());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      container: true,
      button: true,
      label: l10n.editLockEnter,
      onTap: _showHint,
      // Os "hints" dizem o que cada gesto FAZ: o leitor de tela fala, por
      // exemplo, "toque duas vezes e segure para destravar a edição".
      onTapHint: l10n.editLockTapHint,
      onLongPress: _unlockForAccessibility,
      onLongPressHint: l10n.editLockLongPressHint,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: 48,
            child: AnimatedBuilder(
              animation: _hold,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_hold.value > 0)
                      SizedBox.square(
                        dimension: 40,
                        child: CircularProgressIndicator(
                          value: _hold.value,
                          strokeWidth: 3,
                        ),
                      ),
                    const Icon(Icons.lock_outline),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
