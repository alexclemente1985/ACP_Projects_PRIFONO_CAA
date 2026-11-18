import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/about/privox_mark.dart';

// Gerador dos ícones do Privox (ADR-046).
//
// NÃO faz parte da suíte de testes: fica em `tools/` e só roda sob demanda,
// na raiz do projeto:
//
//     flutter test tools/gen_launcher_icons_test.dart
//
// Desenha a `PrivoxMark` (o mesmo painter da splash) e grava:
//  - `mipmap-*/ic_launcher.png`: ícone legado (Android anterior ao 8);
//  - `mipmap-*/ic_launcher_foreground.png`: primeiro plano do ícone
//    adaptativo (108 dp; a marca cabe na zona segura de 66 dp);
//  - `mipmap-anydpi-v26/ic_launcher.xml` e
//    `values/ic_launcher_background.xml`: ícone adaptativo com fundo bege;
//  - `store/play/icon_512.png`: ícone de 512 px da ficha da Play Store.
// Pode ser rodado de novo sem problema (sobrescreve).

const _resRoot = 'android/app/src/main/res';
const _playIconPath = 'store/play/icon_512.png';

/// (sufixo da pasta, fator de densidade em relação ao mdpi).
const _densities = <(String, double)>[
  ('mdpi', 1),
  ('hdpi', 1.5),
  ('xhdpi', 2),
  ('xxhdpi', 3),
  ('xxxhdpi', 4),
];

const _legacyDp = 48;
const _adaptiveDp = 108;
const _playPx = 512;

/// Fração do lado ocupada pela marca em cada composição. No adaptativo, o
/// anel da marca (92% do lado) precisa caber no círculo seguro de 66 dp:
/// 0,66 x 0,92 = 0,607 do lado de 108 dp, menos que 66/108 = 0,611.
const _adaptiveMarkFraction = 0.66;
const _legacyMarkFraction = 0.84;
const _playMarkFraction = 0.80;
const _legacyCornerFraction = 0.2;

void main() {
  testWidgets('gera os ícones do launcher e o ícone da Play', (tester) async {
    expect(
      File('pubspec.yaml').existsSync(),
      isTrue,
      reason: 'Rode na raiz do projeto (onde fica o pubspec.yaml).',
    );

    await tester.runAsync(() async {
      for (final (name, scale) in _densities) {
        final legacyPx = (_legacyDp * scale).round();
        await _writePng(
          File('$_resRoot/mipmap-$name/ic_launcher.png'),
          legacyPx,
          (canvas) => _drawSquareIcon(
            canvas,
            legacyPx.toDouble(),
            markFraction: _legacyMarkFraction,
            cornerFraction: _legacyCornerFraction,
          ),
        );

        final foregroundPx = (_adaptiveDp * scale).round();
        await _writePng(
          File('$_resRoot/mipmap-$name/ic_launcher_foreground.png'),
          foregroundPx,
          (canvas) => _drawMark(
            canvas,
            foregroundPx.toDouble(),
            _adaptiveMarkFraction,
          ),
        );
      }

      final playBytes = await _writePng(
        File(_playIconPath),
        _playPx,
        (canvas) => _drawSquareIcon(
          canvas,
          _playPx.toDouble(),
          markFraction: _playMarkFraction,
        ),
      );
      expect(
        playBytes.length,
        lessThan(1024 * 1024),
        reason: 'A Play aceita o ícone com até 1024 KB.',
      );

      final background = (PrivoxMark.defaultBeige.toARGB32() & 0xFFFFFF)
          .toRadixString(16)
          .padLeft(6, '0')
          .toUpperCase();
      await _writeText(
        File('$_resRoot/values/ic_launcher_background.xml'),
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#$background</color>\n'
        '</resources>\n',
      );
      await _writeText(
        File('$_resRoot/mipmap-anydpi-v26/ic_launcher.xml'),
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon '
        'xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n',
      );

      stdout.writeln(
        'Ícones gerados: ${_densities.length} legados, '
        '${_densities.length} adaptativos, 1 da Play (512 px).',
      );
    });
  });
}

/// Fundo bege em quadrado (com cantos arredondados se [cornerFraction] > 0)
/// e a marca centralizada.
void _drawSquareIcon(
  ui.Canvas canvas,
  double side, {
  required double markFraction,
  double cornerFraction = 0,
}) {
  final rect = ui.Rect.fromLTWH(0, 0, side, side);
  final paint = ui.Paint()..color = PrivoxMark.defaultBeige;
  if (cornerFraction > 0) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        rect,
        ui.Radius.circular(side * cornerFraction),
      ),
      paint,
    );
  } else {
    canvas.drawRect(rect, paint);
  }
  _drawMark(canvas, side, markFraction);
}

/// Desenha a marca completa (progress = 1), centralizada num quadrado de
/// lado [side], ocupando [fraction] do lado.
void _drawMark(ui.Canvas canvas, double side, double fraction) {
  final markSide = side * fraction;
  final offset = (side - markSide) / 2;
  canvas
    ..save()
    ..translate(offset, offset);
  const PrivoxMarkPainter(
    pinkColor: PrivoxMark.defaultPink,
    blueColor: PrivoxMark.defaultBlue,
  ).paint(canvas, ui.Size(markSide, markSide));
  canvas.restore();
}

/// Renderiza [draw] numa imagem quadrada de [px] pixels e grava o PNG.
/// Confere a assinatura PNG e as dimensões lidas do próprio arquivo.
Future<List<int>> _writePng(
  File file,
  int px,
  void Function(ui.Canvas canvas) draw,
) async {
  final recorder = ui.PictureRecorder();
  draw(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  if (data == null) {
    throw StateError('Não foi possível codificar ${file.path} como PNG.');
  }
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

  // Assinatura PNG (89 50 4E 47) e o IHDR: largura e altura em big-endian,
  // nos bytes 16–19 e 20–23.
  expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  expect(_readUint32(bytes, 16), px, reason: 'largura de ${file.path}');
  expect(_readUint32(bytes, 20), px, reason: 'altura de ${file.path}');

  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
  return bytes;
}

int _readUint32(List<int> bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

Future<void> _writeText(File file, String text) async {
  await file.create(recursive: true);
  await file.writeAsString(text);
}
