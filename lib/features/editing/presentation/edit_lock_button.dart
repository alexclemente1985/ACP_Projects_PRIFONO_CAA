import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';

/// Cadeado da AppBar.
///
/// Em USO: é preciso SEGURAR por [holdDuration] para entrar em edição (um
/// anel mostra o progresso; soltar antes só mostra uma dica). Em EDIÇÃO: um
/// toque volta ao modo de uso.
///
/// Usa `Listener` (eventos brutos) e não `GestureDetector`/`Tooltip`: o
/// reconhecedor de toque longo do Tooltip cancelaria a contagem aos 500 ms.
class EditLockButton extends StatelessWidget {
  const EditLockButton({super.key});

  @override
  Widget build(BuildContext context) {
    final editMode = AppScope.of(context).editMode;
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: editMode,
      builder: (context, _) {
        if (editMode.isEditing) {
          return IconButton(
            tooltip: l10n.editLockLeave,
            icon: const Icon(Icons.lock_open_outlined),
            onPressed: editMode.lock,
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
    AppScope.of(context).editMode.enter();
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
  void _unlockForAccessibility() => AppScope.of(context).editMode.enter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.editLockEnter,
      onTap: _showHint,
      onLongPress: _unlockForAccessibility,
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
