import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/pin/presentation/pin_flows.dart';

/// Cadeado da AppBar.
///
/// Em USO, SEM PIN: é preciso SEGURAR por [HoldToUnlock.holdDuration] para
/// entrar em edição (um anel e uma barra mostram o progresso; soltar antes só
/// mostra uma dica). Em USO, COM PIN: um toque já abre o pedido de PIN, que é a
/// proteção (ADR-041, decisão 6; ver [TapToUnlock]). Em EDIÇÃO: um toque volta
/// ao modo de uso.
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
  late final _settings = AppScope.of(context).settings;
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

    // O PIN pode ser ligado ou desligado em Ajustes com esta tela na pilha:
    // por isso o cadeado também escuta as configurações.
    return ListenableBuilder(
      listenable: Listenable.merge([_editMode, _settings]),
      builder: (context, _) {
        if (_editMode.isEditing) {
          return IconButton(
            tooltip: l10n.editLockLeave,
            icon: const Icon(Icons.lock_open_outlined),
            onPressed: _editMode.lock,
          );
        }
        return _settings.hasPin ? const TapToUnlock() : const HoldToUnlock();
      },
    );
  }
}

/// A parte "tocar para destravar" do [EditLockButton], usada quando há PIN
/// (ADR-041, decisão 6): o PIN já é a proteção, então um toque basta. Segurar o
/// cadeado também funciona: não há `Tooltip`, cujo toque longo cancelaria o
/// toque de quem segura por hábito.
class TapToUnlock extends StatefulWidget {
  const TapToUnlock({super.key});

  @override
  State<TapToUnlock> createState() => _TapToUnlockState();
}

class _TapToUnlockState extends State<TapToUnlock> {
  /// Já há um pedido de PIN na tela? (outro toque não abre um segundo).
  bool _asking = false;

  Future<void> _unlock() async {
    if (_asking) return;
    _asking = true;
    try {
      await requestEditUnlock(context);
    } finally {
      _asking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      onPressed: () => unawaited(_unlock()),
      // Sem `tooltip` de propósito; o nome do botão vem do rótulo do ícone.
      icon: Icon(Icons.lock_outline, semanticLabel: l10n.editLockEnter),
    );
  }
}

/// A parte "segurar para destravar" do [EditLockButton].
///
/// Enquanto a pessoa segura (E6-4.3, ADR-041), o app dá três sinais, porque em
/// alguns aparelhos o dedo cobre o cadeado inteiro:
/// - o anel em volta do cadeado;
/// - uma barra no fundo da AppBar que cresce do lado do cadeado (o fim da
///   linha) para o lado oposto, longe do dedo;
/// - uma vibração leve quando a contagem começa e outra, média, quando termina.
///
/// Só existe SEM PIN (com PIN o cadeado é o [TapToUnlock]). Com teclado externo
/// o cadeado recebe foco e Enter ou Espaço destravam direto (E6-5). O anel de
/// FOCO do teclado é o global (`FocusRingOverlay`, E6-5b); este widget não
/// desenha um anel próprio.
class HoldToUnlock extends StatefulWidget {
  const HoldToUnlock({super.key});

  /// Tempo que o cadeado precisa ficar pressionado.
  static const Duration holdDuration = Duration(milliseconds: 1500);

  /// Altura (dp) da barra de progresso.
  static const double progressBarHeight = 6;

  /// Chaves da barra (a faixa inteira e a parte já preenchida), para os testes.
  static const Key progressTrackKey = ValueKey<String>(
    'edit-lock-progress-track',
  );
  static const Key progressFillKey = ValueKey<String>(
    'edit-lock-progress-fill',
  );

  @override
  State<HoldToUnlock> createState() => _HoldToUnlockState();
}

class _HoldToUnlockState extends State<HoldToUnlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: HoldToUnlock.holdDuration,
    // A contagem é uma regra de SEGURANÇA, não um enfeite. O padrão (`normal`)
    // encurta a duração quando o sistema pede "reduzir movimento", e qualquer
    // toque rápido destravaria a edição. `preserve` mantém os 1,5 s.
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_onStatus);

  /// Mostra/esconde a barra de progresso numa camada acima da página.
  final OverlayPortalController _bar = OverlayPortalController();

  /// Distância (dp) do topo da camada até o topo da barra.
  double _barTop = 0;

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
    _hideBar();
    unawaited(_vibrate(HapticFeedback.mediumImpact));
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

  /// Vibra uma vez. Aparelhos sem vibração não são problema.
  Future<void> _vibrate(Future<void> Function() feedback) async {
    try {
      await feedback();
    } on Exception {
      // Sem vibração: o cadeado funciona do mesmo jeito.
    }
  }

  /// Calcula onde a barra fica: colada no fundo da AppBar.
  ///
  /// O cadeado é centralizado na faixa da AppBar (altura `kToolbarHeight`),
  /// então o fundo da faixa fica meia faixa abaixo do centro do cadeado. As
  /// AppBars do app usam a altura padrão e não têm `bottom`; um teste confere.
  void _placeBar() {
    final box = context.findRenderObject();
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    if (box is! RenderBox || overlay is! RenderBox || !box.hasSize) return;
    final center = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: overlay,
    );
    _barTop = center.dy + kToolbarHeight / 2 - HoldToUnlock.progressBarHeight;
  }

  void _hideBar() {
    if (_bar.isShowing) _bar.hide();
  }

  void _onDown(PointerDownEvent event) {
    // Um segundo dedo não reinicia a contagem nem vibra de novo.
    if (_holding) return;
    _holding = true;
    _placeBar();
    _bar.show();
    unawaited(_vibrate(HapticFeedback.lightImpact));
    unawaited(_hold.forward(from: 0));
  }

  void _onUp(PointerUpEvent event) {
    if (!_holding) return;
    _holding = false;
    _hideBar();
    _hold.reset();
    _showHint();
  }

  void _onCancel(PointerCancelEvent event) {
    _holding = false;
    _hideBar();
    _hold.reset();
  }

  void _showHint() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.editLockHoldHint)));
  }

  /// Leitores de tela ("tocar e segurar" do TalkBack/VoiceOver é uma ação
  /// própria) e teclado externo (Enter ou Espaço no cadeado focado) não têm como
  /// segurar: destravam direto (ADR-041, E6-5). Com PIN ligado no meio do
  /// caminho, o pedido de PIN continua sendo a proteção.
  void _unlockForAccessibility() => unawaited(_unlock());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Anel e barra usam a cor do tema para indicadores de progresso
    // (`AppTheme`): azulForte no claro e bege no escuro, com contraste de pelo
    // menos 3:1 sobre a AppBar nos dois temas (conferido em teste, E6-4.1).
    final progressColor =
        ProgressIndicatorTheme.of(context).color ?? scheme.primary;
    final trackColor = scheme.onSurface.withValues(alpha: 0.12);

    return OverlayPortal(
      controller: _bar,
      overlayChildBuilder: (_) => Positioned(
        top: _barTop,
        left: 0,
        right: 0,
        height: HoldToUnlock.progressBarHeight,
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: ColoredBox(
              key: HoldToUnlock.progressTrackKey,
              color: trackColor,
              child: AnimatedBuilder(
                animation: _hold,
                builder: (context, _) {
                  // Cresce do FIM da linha (o lado do cadeado) para o começo.
                  return FractionallySizedBox(
                    alignment: AlignmentDirectional.centerEnd,
                    widthFactor: _hold.value,
                    child: ColoredBox(
                      key: HoldToUnlock.progressFillKey,
                      color: progressColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      child: Semantics(
        container: true,
        button: true,
        label: l10n.editLockEnter,
        onTap: _showHint,
        // Os "hints" dizem o que cada gesto FAZ: o leitor de tela fala, por
        // exemplo, "toque duas vezes e segure para destravar a edição".
        onTapHint: l10n.editLockTapHint,
        onLongPress: _unlockForAccessibility,
        onLongPressHint: l10n.editLockLongPressHint,
        // Teclado externo (tablet): o cadeado recebe foco e Enter ou Espaço
        // destravam, já que não há como "segurar" uma tecla (E6-5). O anel de
        // foco é desenhado pelo FocusRingOverlay (E6-5b).
        child: FocusableActionDetector(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _unlockForAccessibility();
                return null;
              },
            ),
          },
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
                              color: progressColor,
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
        ),
      ),
    );
  }
}
