import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/features/boards/domain/word_class.dart';

/// Nome da classe gramatical no idioma do app.
String wordClassName(AppLocalizations l10n, WordClass wordClass) {
  return switch (wordClass) {
    WordClass.pronoun => l10n.wordClassPronoun,
    WordClass.verb => l10n.wordClassVerb,
    WordClass.noun => l10n.wordClassNoun,
    WordClass.adjective => l10n.wordClassAdjective,
    WordClass.preposition => l10n.wordClassPreposition,
    WordClass.question => l10n.wordClassQuestion,
    WordClass.negation => l10n.wordClassNegation,
    WordClass.adverb => l10n.wordClassAdverb,
    WordClass.conjunction => l10n.wordClassConjunction,
    WordClass.determiner => l10n.wordClassDeterminer,
  };
}
