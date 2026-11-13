import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anel de foco do app inteiro (ADR-041, E6-5b), para quem usa teclado externo
/// ou uma chave (switch) que se comporta como teclado.
///
/// Fica em `MaterialApp.builder`, ACIMA do Navigator, e desenha por cima de tudo
/// um contorno em volta do controle que tem o foco. Assim cards, fichas, botões,
/// chips, itens de lista e menus ganham o mesmo anel sem que cada tela precise
/// saber disso. Decisões (ADR-041, E6-5b):
///
/// - SÓ aparece com `FocusHighlightMode.traditional` (a última interação foi uma
///   tecla). Tocar na tela apaga o anel; leitores de tela desenham o foco deles.
/// - É um anel EXTERNO ([gap] de folga, [strokeWidth] de espessura, cor
///   `onSurface`). Por ser de fora, não se confunde com a borda grossa que marca
///   a SELEÇÃO de chips e fichas (E6-4.2): um chip selecionado e focado mostra
///   as duas coisas ao mesmo tempo.
/// - Campos de texto ficam de fora: têm borda de foco própria (tema).
/// - Não segue a forma exata do controle: é sempre um retângulo de cantos
///   arredondados em volta da caixa do controle (um botão redondo ganha um anel
///   quadrado arredondado).
///
/// Como acompanha a posição do controle: o anel é calculado na hora de PINTAR
/// (a posição já é a do quadro atual). Um `AnimationController` curto
/// ([trackingWindow]) mantém o repintar ligado depois de cada evento (foco,
/// rolagem, tamanho da janela), para cobrir animações de diálogos e menus. Não há
/// relógio permanente: sem eventos, nenhum quadro é agendado.
///
/// E6-5c: o nó em foco pode ter sido REMOVIDO da árvore no quadro atual (por
/// exemplo, o cadeado troca de widget ao destravar). Até o fim do quadro o
/// elemento fica "inativo": `mounted` ainda é verdadeiro, mas `findRenderObject`
/// e as buscas por ancestral lançam erro (em debug). Por isso o anel só é
/// calculado para elementos ativos ([_isLive]).
class FocusRingOverlay extends StatefulWidget {
  const FocusRingOverlay({required this.child, super.key});

  final Widget child;

  /// Espessura (dp) do traço.
  static const double strokeWidth = 3;

  /// Folga (dp) entre o controle e o traço.
  static const double gap = 2;

  /// Raio (dp) assumido para os cantos do controle.
  static const double cornerRadius = 12;

  /// Distância (dp) do contorno do controle até o CENTRO do traço.
  static const double outset = gap + strokeWidth / 2;

  /// Depois de cada evento, o anel é recalculado a cada quadro por este tempo.
  static const Duration trackingWindow = Duration(milliseconds: 400);

  /// Chave do `CustomPaint` do anel, para os testes.
  static const Key paintKey = ValueKey<String>('focus-ring-paint');

  @override
  State<FocusRingOverlay> createState() => _FocusRingOverlayState();
}

/// Desenha o anel. Guarda o último retângulo desenhado em [lastRing] (centro do
/// traço, em coordenadas do app; null = sem anel) para os testes.
final class FocusRingPainter extends CustomPainter {
  FocusRingPainter({
    required this.measure,
    required this.color,
    required Listenable repaint,
  }) : super(repaint: repaint);

  /// Devolve a caixa do controle em foco (coordenadas do app) ou null.
  final Rect? Function() measure;
  final Color color;

  Rect? lastRing;

  @override
  void paint(Canvas canvas, Size size) {
    final target = measure();
    if (target == null) {
      lastRing = null;
      return;
    }
    final ring = target.inflate(FocusRingOverlay.outset);
    lastRing = ring;
    final radius = math.min(
      FocusRingOverlay.cornerRadius + FocusRingOverlay.outset,
      ring.shortestSide / 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(ring, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = FocusRingOverlay.strokeWidth
        ..color = color
        ..isAntiAlias = true,
    );
  }

  // Sempre repinta: o retângulo depende do estado do foco, não só dos campos.
  @override
  bool shouldRepaint(FocusRingPainter oldDelegate) => true;

  // O anel nunca captura toques.
  @override
  bool? hitTest(Offset position) => false;
}

class _FocusRingOverlayState extends State<FocusRingOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _tracking = AnimationController(
    vsync: this,
    duration: FocusRingOverlay.trackingWindow,
    // A janela de acompanhamento não é enfeite: com "reduzir movimento" o modo
    // padrão a encurtaria para milissegundos.
    animationBehavior: AnimationBehavior.preserve,
  );

  /// Nó que merece o anel agora (null = nenhum).
  FocusNode? _target;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChanged);
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    FocusManager.instance.removeListener(_onFocusChanged);
    _tracking.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() => _track();

  void _onFocusChanged() {
    _target = _eligible(FocusManager.instance.primaryFocus);
    _track();
  }

  void _onHighlightModeChanged(FocusHighlightMode mode) => _track();

  /// Liga o acompanhamento por [FocusRingOverlay.trackingWindow].
  void _track() {
    if (!mounted) return;
    unawaited(_tracking.forward(from: 0));
  }

  /// O contexto ainda faz parte da árvore ATIVA? `mounted` não basta: um
  /// elemento removido neste quadro fica "inativo" até o fim do quadro (ainda
  /// `mounted`), e nele `findRenderObject` e as buscas por ancestral lançam
  /// erro em debug (E6-5c).
  static bool _isLive(BuildContext target) {
    if (!target.mounted) return false;
    return target is! Element || target.debugIsActive;
  }

  /// Escopos de foco (telas, diálogos) e campos de texto não ganham anel.
  FocusNode? _eligible(FocusNode? node) {
    if (node == null || node is FocusScopeNode) return null;
    final nodeContext = node.context;
    if (nodeContext == null || !_isLive(nodeContext)) return null;
    if (nodeContext.findAncestorWidgetOfExactType<EditableText>() != null) {
      return null;
    }
    return node;
  }

  /// A caixa do controle em foco, em coordenadas deste overlay (que cobre o app
  /// inteiro). Chamado na hora de pintar: o layout do quadro já está pronto.
  Rect? _measureTarget() {
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return null;
    }
    final node = _target;
    final nodeContext = node?.context;
    if (node == null ||
        nodeContext == null ||
        !_isLive(nodeContext) ||
        !node.hasPrimaryFocus) {
      return null;
    }
    final box = nodeContext.findRenderObject();
    final self = context.findRenderObject();
    if (box is! RenderBox ||
        self is! RenderBox ||
        !box.attached ||
        !box.hasSize ||
        !self.hasSize) {
      return null;
    }
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(self),
      Offset.zero & box.size,
    );
    // Um nó que cobre a tela quase inteira (uma página focada como um todo) não
    // tem o que destacar.
    if (rect.width >= self.size.width * 0.95 &&
        rect.height >= self.size.height * 0.9) {
      return null;
    }
    return rect;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return NotificationListener<ScrollNotification>(
      // Rolar move o controle em foco: o anel precisa acompanhar.
      onNotification: (_) {
        if (_target != null) _track();
        return false;
      },
      child: CustomPaint(
        key: FocusRingOverlay.paintKey,
        foregroundPainter: FocusRingPainter(
          measure: _measureTarget,
          color: color,
          repaint: _tracking,
        ),
        child: widget.child,
      ),
    );
  }
}