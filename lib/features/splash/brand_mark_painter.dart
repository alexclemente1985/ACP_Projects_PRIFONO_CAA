import 'package:flutter/widgets.dart';

/// Marca PROVISÓRIA: balão de fala com 3 pontos, desenhado em código.
/// Será substituída pelo logo real da PRIFONO.
///
/// [progress] vai de 0.0 a 1.0:
///  - 0.00–0.50: o contorno do balão é traçado;
///  - 0.45–0.95: os 3 pontos surgem em sequência, com leve "pulo".
class BrandMarkPainter extends CustomPainter {
  BrandMarkPainter({
    required this.progress,
    required this.strokeColor,
    required this.dotColors,
  });

  final double progress;
  final Color strokeColor;
  final List<Color> dotColors;

  static const Interval _bubbleInterval =
      Interval(0, 0.5, curve: Curves.easeInOut);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;

    final drawn = _bubbleInterval.transform(progress);
    if (drawn > 0) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.05
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = strokeColor;
      for (final metric in _bubblePath(s).computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * drawn), stroke);
      }
    }

    for (var i = 0; i < dotColors.length; i++) {
      final interval = Interval(
        0.45 + i * 0.1,
        0.75 + i * 0.1,
        curve: Curves.easeOutBack,
      );
      final scale = interval.transform(progress);
      if (scale <= 0) continue;
      canvas.drawCircle(
        Offset(s * (0.32 + 0.18 * i), s * 0.41),
        s * 0.055 * scale,
        Paint()..color = dotColors[i],
      );
    }
  }

  Path _bubblePath(double s) {
    final left = s * 0.08;
    final top = s * 0.10;
    final right = s * 0.92;
    final bottom = s * 0.72;
    final r = s * 0.22;
    final radius = Radius.circular(r);

    return Path()
      ..moveTo(left + r, top)
      ..lineTo(right - r, top)
      ..arcToPoint(Offset(right, top + r), radius: radius)
      ..lineTo(right, bottom - r)
      ..arcToPoint(Offset(right - r, bottom), radius: radius)
      ..lineTo(s * 0.58, bottom)
      ..lineTo(s * 0.38, s * 0.93) // ponta do balão
      ..lineTo(s * 0.38, bottom)
      ..lineTo(left + r, bottom)
      ..arcToPoint(Offset(left, bottom - r), radius: radius)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: radius)
      ..close();
  }

  @override
  bool shouldRepaint(BrandMarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.dotColors != dotColors;
  }
}
