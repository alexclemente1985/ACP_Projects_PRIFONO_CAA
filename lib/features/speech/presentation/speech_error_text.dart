import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/speech/domain/speech_service.dart';

/// Texto de aviso para cada tipo de falha de voz.
String speechErrorText(AppLocalizations l10n, SpeechErrorKind kind) {
  switch (kind) {
    case SpeechErrorKind.voiceUnavailable:
      return l10n.speechVoiceMissing;
    case SpeechErrorKind.failed:
      return l10n.speechFailed;
  }
}
