import 'package:flutter/material.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/pin/domain/pin.dart';

/// As bolinhas que mostram quantos dígitos já foram digitados (sem mostrar
/// quais).
class PinDots extends StatelessWidget {
  const PinDots({required this.filled, super.key});

  final int filled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Theme.of(context).colorScheme.onSurface;

    // liveRegion: o leitor de tela avisa "1 de 4 números digitados" a cada toque.
    return Semantics(
      liveRegion: true,
      label: l10n.pinDotsLabel(filled, PinRules.length),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < PinRules.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < filled ? color : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: const SizedBox.square(dimension: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Teclado numérico grande (teclas de 64 dp).
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const double keySize = 64;

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          _KeyRow(
            children: [
              for (final digit in row)
                _DigitKey(digit: digit, onPressed: () => onDigit(digit)),
            ],
          ),
        _KeyRow(
          children: [
            const SizedBox.square(dimension: keySize),
            _DigitKey(digit: '0', onPressed: () => onDigit('0')),
            SizedBox.square(
              dimension: keySize,
              child: IconButton.outlined(
                tooltip: l10n.pinBackspace,
                icon: const Icon(Icons.backspace_outlined),
                iconSize: 26,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(keySize),
                ),
                onPressed: onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final child in children)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.digit, required this.onPressed});

  final String digit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: PinKeypad.keySize,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: Text(digit, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
