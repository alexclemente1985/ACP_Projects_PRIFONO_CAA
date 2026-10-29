import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Marca do Privox: um selo circular (como o espaço da identidade do
/// consultório) com um anel rosa, um disco branco e dois balões de fala de três
/// pontos com fundo bege, um de contorno rosa e outro azul (a conversa entre
/// duas pessoas).
///
/// Desenhada em código, sem imagem e sem texto (ADR-013, ADR-032).
///
/// [progress] vai de 0.0 a 1.0 e segue a ideia da animação da splash (primeiro
/// os contornos são traçados, depois os pontos surgem em sequência):
///  - 0.00–0.20: o disco branco aparece;
///  - 0.00–0.40: o anel rosa é traçado a partir do topo;
///  - 0.25–0.60: o balão rosa é traçado;
///  - 0.40–0.75: o balão azul é traçado (o fundo bege de cada balão surge na
///    segunda metade do traçado);
///  - 0.60–1.00: os 6 pontos surgem um a um, com leve "pulo".
/// Com o valor padrão (1.0) a marca aparece completa e parada.
///
/// É decorativa: o nome do app aparece em texto ao lado e leitores de tela
/// ignoram o desenho.
class PrivoxMark extends StatelessWidget {
  const PrivoxMark({
    super.key,
    this.size = 96,
    this.progress = 1,
    this.pinkColor = defaultPink,
    this.blueColor = defaultBlue,
    this.discColor = defaultWhite,
    this.bubbleFillColor = defaultBeige,
  });

  /// Rosa da marca (ADR-007).
  static const Color defaultPink = Color(0xFFFBB7C4);

  /// Azul da marca (ADR-007).
  static const Color defaultBlue = Color(0xFF56B2CB);

  /// Bege da marca (ADR-007): fundo dos balões.
  static const Color defaultBeige = Color(0xFFFEFEE9);

  /// Branco da marca (ADR-007): fundo do disco.
  static const Color defaultWhite = Color(0xFFFFFFFF);

  final double size;
  final double progress;
  final Color pinkColor;
  final Color blueColor;
  final Color discColor;
  final Color bubbleFillColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: PrivoxMarkPainter(
            progress: progress,
            pinkColor: pinkColor,
            blueColor: blueColor,
            discColor: discColor,
            bubbleFillColor: bubbleFillColor,
          ),
        ),
      ),
    );
  }
}

/// Desenha a marca num círculo inscrito no quadrado do widget; todas as
/// medidas são frações do lado do quadrado.
class PrivoxMarkPainter extends CustomPainter {
  const PrivoxMarkPainter({
    required this.pinkColor,
    required this.blueColor,
    this.discColor = PrivoxMark.defaultWhite,
    this.bubbleFillColor = PrivoxMark.defaultBeige,
    this.progress = 1,
  });

  final double progress;
  final Color pinkColor;
  final Color blueColor;
  final Color discColor;
  final Color bubbleFillColor;

  static const double _ringRadius = 0.46;
  static const double _discRadius = 0.44;

  // Balão rosa (em cima, à esquerda) e balão azul (embaixo, à direita).
  static const Rect _boxPink = Rect.fromLTRB(0.22, 0.23, 0.56, 0.44);
  static const Rect _boxBlue = Rect.fromLTRB(0.44, 0.47, 0.78, 0.68);

  double _segment(double begin, double end, Curve curve) {
    return Interval(begin, end, curve: curve).transform(progress);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas
      ..save()
      // Centraliza o quadrado de desenho se o espaço não for quadrado.
      ..translate((size.width - s) / 2, (size.height - s) / 2);

    final center = Offset(s / 2, s / 2);

    final fade = _segment(0, 0.2, Curves.easeOut);
    if (fade > 0) {
      canvas.drawCircle(
        center,
        s * _discRadius,
        Paint()..color = discColor.withValues(alpha: fade),
      );
    }

    final ringProgress = _segment(0, 0.4, Curves.easeInOut);
    if (ringProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: s * _ringRadius),
        -math.pi / 2,
        2 * math.pi * ringProgress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.014
          ..strokeCap = StrokeCap.round
          ..color = pinkColor,
      );
    }

    _paintBubble(
      canvas,
      s,
      color: pinkColor,
      box: _boxPink,
      tailLeft: 0.28,
      tailRight: 0.37,
      tip: const Offset(0.25, 0.53),
      traced: _segment(0.25, 0.6, Curves.easeInOut),
    );
    _paintBubble(
      canvas,
      s,
      color: blueColor,
      box: _boxBlue,
      tailLeft: 0.63,
      tailRight: 0.72,
      tip: const Offset(0.75, 0.77),
      traced: _segment(0.4, 0.75, Curves.easeInOut),
    );

    var k = 0;
    for (final (box, color) in [(_boxPink, pinkColor), (_boxBlue, blueColor)]) {
      final dotPaint = Paint()..color = color;
      final gap = box.width * 0.22;
      for (var i = -1; i <= 1; i++) {
        final begin = 0.6 + k * 0.055;
        final scale = _segment(
          begin,
          math.min(1.0, begin + 0.125),
          Curves.easeOutBack,
        );
        k++;
        if (scale <= 0) continue;
        canvas.drawCircle(
          Offset(s * (box.center.dx + i * gap), s * box.center.dy),
          s * 0.022 * scale,
          dotPaint,
        );
      }
    }

    canvas.restore();
  }

  /// Traça o contorno do balão até a fração [traced] (0 a 1).
  void _paintBubble(
    Canvas canvas,
    double s, {
    required Color color,
    required Rect box,
    required double tailLeft,
    required double tailRight,
    required Offset tip,
    required double traced,
  }) {
    if (traced <= 0) return;

    final left = s * box.left;
    final top = s * box.top;
    final right = s * box.right;
    final bottom = s * box.bottom;
    final r = s * 0.075;
    final radius = Radius.circular(r);

    final outline = Path()
      ..moveTo(left + r, top)
      ..lineTo(right - r, top)
      ..arcToPoint(Offset(right, top + r), radius: radius)
      ..lineTo(right, bottom - r)
      ..arcToPoint(Offset(right - r, bottom), radius: radius)
      ..lineTo(s * tailRight, bottom)
      ..lineTo(s * tip.dx, s * tip.dy) // ponta do balão
      ..lineTo(s * tailLeft, bottom)
      ..lineTo(left + r, bottom)
      ..arcToPoint(Offset(left, bottom - r), radius: radius)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: radius)
      ..close();

    // O fundo bege surge na segunda metade do traçado.
    final fillAlpha = ((traced - 0.5) * 2).clamp(0.0, 1.0).toDouble();
    if (fillAlpha > 0) {
      canvas.drawPath(
        outline,
        Paint()..color = bubbleFillColor.withValues(alpha: fillAlpha),
      );
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final metric in outline.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * traced), stroke);
    }
  }

  @override
  bool shouldRepaint(PrivoxMarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pinkColor != pinkColor ||
        oldDelegate.blueColor != blueColor ||
        oldDelegate.discColor != discColor ||
        oldDelegate.bubbleFillColor != bubbleFillColor;
  }
}
