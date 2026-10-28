import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';

/// Texto de cada tipo de falha ao falar com o serviço de pictogramas.
String symbolErrorText(AppLocalizations l10n, SymbolErrorKind? kind) {
  switch (kind) {
    case SymbolErrorKind.offline:
      return l10n.searchErrorOffline;
    case SymbolErrorKind.timeout:
      return l10n.searchErrorTimeout;
    case SymbolErrorKind.server:
      return l10n.searchErrorServer;
    case SymbolErrorKind.badResponse:
    case null:
      return l10n.searchErrorGeneric;
  }
}

