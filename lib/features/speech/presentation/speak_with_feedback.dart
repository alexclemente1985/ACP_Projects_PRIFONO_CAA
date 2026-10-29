import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/speech/domain/speech_service.dart';
import 'package:prifono_caa/features/speech/presentation/speech_error_text.dart';

/// Fala [text] com a voz do app e, se falhar, avisa na tela (SnackBar).
///
/// Usada pelo toque no card e pelo botão Falar da barra de frase.
Future<void> speakWithFeedback(BuildContext context, String text) async {
  // Capturados ANTES do await (o context pode não valer depois dele).
  final speech = AppScope.of(context).speech;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await speech.speak(text);
  } on SpeechException catch (error) {
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(speechErrorText(l10n, error.kind))),
      );
  }
}
