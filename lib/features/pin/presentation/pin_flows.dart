import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/pin/presentation/pin_dialogs.dart';

/// Pede o PIN. `true` = acertou (ou resolveu a conta do "Esqueci o PIN").
Future<bool> showPinVerifyDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const PinVerifyDialog(),
  );
  return ok ?? false;
}

/// Entrar no modo de edição: se há PIN, pede antes; só então liga (ADR-040).
/// Sem PIN, liga na hora (no mesmo instante, sem esperar nada).
Future<void> requestEditUnlock(BuildContext context) async {
  final scope = AppScope.of(context);
  if (!scope.settings.hasPin) {
    scope.editMode.enter();
    return;
  }
  if (await showPinVerifyDialog(context)) scope.editMode.enter();
}

/// Ligar o PIN (ou, com [changing], trocar por outro). Não pede o PIN atual:
/// quem chama [changePinFlow] já pediu.
Future<void> enablePinFlow(BuildContext context, {bool changing = false}) async {
  final settings = AppScope.of(context).settings;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);

  final pin = await showDialog<String>(
    context: context,
    builder: (_) => const PinSetupDialog(),
  );
  if (pin == null) return;
  try {
    await settings.setPin(pin);
    messenger.showSnackBar(
      SnackBar(content: Text(changing ? l10n.pinChanged : l10n.pinSaved)),
    );
  } on Exception {
    messenger.showSnackBar(SnackBar(content: Text(l10n.pinSaveFailed)));
  }
}

/// Trocar o PIN: pede o atual e depois o novo.
Future<void> changePinFlow(BuildContext context) async {
  if (!await showPinVerifyDialog(context)) return;
  if (!context.mounted) return;
  await enablePinFlow(context, changing: true);
}

/// Desligar o PIN: pede o atual antes.
Future<void> disablePinFlow(BuildContext context) async {
  final settings = AppScope.of(context).settings;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);

  if (!await showPinVerifyDialog(context)) return;
  try {
    await settings.clearPin();
    messenger.showSnackBar(SnackBar(content: Text(l10n.pinRemoved)));
  } on Exception {
    messenger.showSnackBar(SnackBar(content: Text(l10n.pinSaveFailed)));
  }
}
