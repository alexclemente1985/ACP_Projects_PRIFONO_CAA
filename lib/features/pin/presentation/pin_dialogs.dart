import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/pin/domain/pin.dart';
import 'package:prifono_caa/features/pin/presentation/pin_keypad.dart';

/// Pede o PIN. Fecha com `true` se acertou (ou se resolveu a conta do "Esqueci
/// o PIN"); fecha com `false`/`null` se a pessoa cancelou.
class PinVerifyDialog extends StatefulWidget {
  const PinVerifyDialog({super.key});

  @override
  State<PinVerifyDialog> createState() => _PinVerifyDialogState();
}

class _PinVerifyDialogState extends State<PinVerifyDialog> {
  String _entered = '';
  bool _wrong = false;

  void _onDigit(String digit) {
    if (_entered.length >= PinRules.length) return;
    final next = _entered + digit;
    if (next.length < PinRules.length) {
      setState(() {
        _entered = next;
        _wrong = false;
      });
      return;
    }
    if (AppScope.of(context).settings.checkPin(next)) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _entered = '';
      _wrong = true;
    });
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _wrong = false;
    });
  }

  Future<void> _forgot() async {
    final navigator = Navigator.of(context);
    final solved = await showDialog<bool>(
      context: context,
      builder: (_) => const ForgotPinDialog(),
    );
    if (solved ?? false) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.pinEnterTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PinDots(filled: _entered.length),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: _wrong
                ? Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.pinWrong,
                      style: TextStyle(color: scheme.error),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => unawaited(_forgot()),
          child: Text(l10n.pinForgot),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

/// Cria um PIN novo: digita duas vezes. Fecha com o PIN, ou `null` se cancelou.
class PinSetupDialog extends StatefulWidget {
  const PinSetupDialog({super.key});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  /// Primeiro PIN digitado; enquanto for null, estamos no passo 1.
  String? _first;
  String _entered = '';
  bool _mismatch = false;

  void _onDigit(String digit) {
    if (_entered.length >= PinRules.length) return;
    final next = _entered + digit;
    if (next.length < PinRules.length) {
      setState(() {
        _entered = next;
        _mismatch = false;
      });
      return;
    }
    final first = _first;
    if (first == null) {
      // Passo 1 completo: pede de novo para confirmar.
      setState(() {
        _first = next;
        _entered = '';
        _mismatch = false;
      });
    } else if (first == next) {
      Navigator.of(context).pop(next);
    } else {
      setState(() {
        _first = null;
        _entered = '';
        _mismatch = true;
      });
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _mismatch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final confirming = _first != null;

    return AlertDialog(
      scrollable: true,
      title: Text(confirming ? l10n.pinConfirmTitle : l10n.pinSetupTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!confirming) ...[
            Text(
              l10n.pinSetupHelp,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          PinDots(filled: _entered.length),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: _mismatch
                ? Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.pinMismatch,
                      style: TextStyle(color: scheme.error),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

/// "Esqueci o PIN": uma conta de multiplicar. Acertou, fecha com `true`. A cada
/// erro a conta muda (não dá para chutar sempre a mesma).
class ForgotPinDialog extends StatefulWidget {
  const ForgotPinDialog({super.key});

  @override
  State<ForgotPinDialog> createState() => _ForgotPinDialogState();
}

class _ForgotPinDialogState extends State<ForgotPinDialog> {
  final Random _random = Random();
  final TextEditingController _answer = TextEditingController();
  late PinChallenge _challenge = PinChallenge.random(_random);
  bool _wrong = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _submit() {
    if (_challenge.accepts(_answer.text)) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _wrong = true;
      _challenge = PinChallenge.random(_random);
      _answer.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.pinForgotTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pinForgotQuestion(_challenge.a, _challenge.b),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.pinForgotAnswer,
              errorText: _wrong ? l10n.pinForgotWrong : null,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.pinForgotConfirm),
        ),
      ],
    );
  }
}
