// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Privox';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Try again';

  @override
  String get themeSectionTitle => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageAutomatic => 'Automatic';

  @override
  String get languageHelp =>
      'The language applies to the app, the pictogram search and the voice.';

  @override
  String get creditsButton => 'About and credits';

  @override
  String get boardsTitle => 'Boards';

  @override
  String get boardsEmptyTitle => 'No boards yet';

  @override
  String get boardsEmptyMessage => 'Create your first communication board.';

  @override
  String get boardsEmptyAction => 'Create first board';

  @override
  String get boardsLoadError => 'Could not load the boards.';

  @override
  String get boardNew => 'New board';

  @override
  String get boardEdit => 'Edit';

  @override
  String get boardDelete => 'Delete';

  @override
  String get boardMoreOptions => 'More options';

  @override
  String boardGridSummary(int columns, int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      columns,
      locale: localeName,
      other: '$columns columns',
      one: '1 column',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows rows',
      one: '1 row',
    );
    return '$_temp0 × $_temp1';
  }

  @override
  String get boardActionFailed =>
      'Could not complete the action. Please try again.';

  @override
  String boardGridTooSmall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'Remove $_temp0 before making the grid smaller.';
  }

  @override
  String get boardEmptyHint => 'Tap + to add the first card.';

  @override
  String boardFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'all $count positions are taken',
      one: 'the only position is taken',
    );
    return 'Board full: $_temp0. Enlarge the grid or free up positions to add more.';
  }

  @override
  String get boardCardsLoadError => 'Could not load the cards.';

  @override
  String get cardAdd => 'Add card';

  @override
  String cardAddAt(int row, int column) {
    return 'Add card in row $row, column $column';
  }

  @override
  String get cardEditorNewTitle => 'New card';

  @override
  String get cardEditorEditTitle => 'Edit card';

  @override
  String get cardLabelLabel => 'Card text';

  @override
  String get cardLabelRequired => 'Write the card text.';

  @override
  String get cardSpeechLabel => 'Spoken text (optional)';

  @override
  String get cardSpeechHelper => 'If left empty, the app says the card text.';

  @override
  String get cardSaving => 'Saving…';

  @override
  String get cardSymbolSectionTitle => 'Pictogram';

  @override
  String get cardSymbolChoose => 'Choose pictogram';

  @override
  String get cardSymbolChange => 'Change pictogram';

  @override
  String get cardSymbolRemove => 'Remove pictogram';

  @override
  String get cardSymbolDownloading => 'Downloading the pictogram…';

  @override
  String get cardSymbolFailedHint =>
      'Try again or remove the pictogram to save with text only.';

  @override
  String get cardClassSectionTitle => 'Word class';

  @override
  String get cardClassHelper =>
      'The card color follows the Fitzgerald Key. Choose the word class.';

  @override
  String get wordClassNone => 'None';

  @override
  String get wordClassPronoun => 'Pronoun';

  @override
  String get wordClassVerb => 'Verb';

  @override
  String get wordClassNoun => 'Noun';

  @override
  String get wordClassAdjective => 'Adjective';

  @override
  String get wordClassPreposition => 'Preposition or social word';

  @override
  String get wordClassQuestion => 'Question';

  @override
  String get wordClassNegation => 'Negation or urgent word';

  @override
  String get wordClassAdverb => 'Adverb';

  @override
  String get wordClassConjunction => 'Conjunction';

  @override
  String get wordClassDeterminer => 'Determiner';

  @override
  String get cardDelete => 'Delete card';

  @override
  String get cardDeleteTitle => 'Delete card?';

  @override
  String cardDeleteMessage(String label) {
    return 'The card “$label” will be deleted. This cannot be undone.';
  }

  @override
  String get boardFormNewTitle => 'New board';

  @override
  String get boardFormEditTitle => 'Edit board';

  @override
  String get boardFormNameLabel => 'Board name';

  @override
  String get boardFormNameRequired => 'Give the board a name.';

  @override
  String get boardFormColumns => 'Columns';

  @override
  String get boardFormRows => 'Rows';

  @override
  String get boardColumnsDecrease => 'Fewer columns';

  @override
  String get boardColumnsIncrease => 'More columns';

  @override
  String get boardRowsDecrease => 'Fewer rows';

  @override
  String get boardRowsIncrease => 'More rows';

  @override
  String boardFormShrinkBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'are $count cards',
      one: 'is 1 card',
    );
    return 'There $_temp0 in the last column or row. To make the grid smaller, clear that space first.';
  }

  @override
  String get boardDeleteTitle => 'Delete board?';

  @override
  String boardDeleteMessage(String name) {
    return 'The board “$name” and all its cards will be deleted. This cannot be undone.';
  }

  @override
  String get searchTitle => 'Search pictograms';

  @override
  String get searchHint => 'Type a word';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchLoading => 'Searching';

  @override
  String get searchIdleMessage => 'Type a word to search for pictograms.';

  @override
  String searchEmptyMessage(String query) {
    return 'No pictogram found for “$query”.';
  }

  @override
  String get searchErrorOffline =>
      'No internet connection. Check the network and try again.';

  @override
  String get searchErrorTimeout =>
      'The search took too long. Please try again.';

  @override
  String get searchErrorServer =>
      'The pictogram service is unavailable right now.';

  @override
  String get searchErrorGeneric =>
      'Could not read the response from the pictogram service.';

  @override
  String get searchRetry => 'Try again';

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get speechVoiceMissing =>
      'There is no English voice on this device. Install one in the device voice settings.';

  @override
  String get speechFailed => 'Could not speak right now. Please try again.';

  @override
  String get attributionShort =>
      'Pictograms: ARASAAC (Government of Aragon), CC BY-NC-SA license. Tap to see the credits.';

  @override
  String get creditsTitle => 'About and credits';

  @override
  String get creditsArasaacTitle => 'Pictograms';

  @override
  String get creditsArasaacOfficial =>
      'Los símbolos pictográficos utilizados son propiedad del Gobierno de Aragón y han sido creados por Sergio Palao para ARASAAC (http://www.arasaac.org), que los distribuye bajo Licencia Creative Commons BY-NC-SA.';

  @override
  String get creditsArasaacBody =>
      'The pictographic symbols used are the property of the Government of Aragon and were created by Sergio Palao for ARASAAC (https://arasaac.org), which distributes them under a Creative Commons license (BY-NC-SA).';

  @override
  String get creditsArasaacTerms =>
      'The pictograms are for non-commercial use. When sharing pictograms or boards made with them, keep the attribution to ARASAAC and use the same license (CC BY-NC-SA).';

  @override
  String get creditsPrivacyTitle => 'Search privacy';

  @override
  String get creditsPrivacyBody =>
      'When you search for pictograms, the word you type and the device IP address are sent to the ARASAAC servers. The app does not send personal data and has no accounts. The pictograms you choose are saved on the device so the app works offline.';

  @override
  String get aboutTagline =>
      'Free communication boards, no account and no ads.';

  @override
  String get aboutMakersTitle => 'Who makes Privox';

  @override
  String get aboutMadeBy => 'Developed by ACP Projects.';

  @override
  String get aboutClinic =>
      'In partnership with the PRIFONO clinic, by speech-language pathologist Priscilla de Sá.';

  @override
  String get aboutPolicyTitle => 'Privacy policy';

  @override
  String get aboutPolicyBody => 'The full privacy policy is at this address:';

  @override
  String get sentenceBarLabel => 'Sentence';

  @override
  String get sentenceHint => 'Tap the cards to build a sentence.';

  @override
  String get sentenceSpeak => 'Say the sentence';

  @override
  String get sentenceDeleteLast => 'Delete the last word';

  @override
  String get sentenceClear => 'Clear the sentence';

  @override
  String get editLockEnter => 'Enter edit mode. Press and hold to unlock.';

  @override
  String get editLockLeave => 'Leave edit mode';

  @override
  String get editLockHoldHint => 'Hold the lock for 1.5 seconds to edit.';

  @override
  String get editModeHint => 'Edit mode: tap a card to edit it.';

  @override
  String get boardEmptyUseHint =>
      'This board is empty. Hold the lock for 1.5 seconds to add cards.';

  @override
  String get cardLinkTitle => 'Open another board when tapped';

  @override
  String get cardLinkNone => 'None (the card only speaks)';

  @override
  String get cardLinkEmpty =>
      'Create another board to be able to link this card to it.';

  @override
  String get cardOpensBoardHint => 'Opens another board';

  @override
  String get sentenceChipHint =>
      'Tap to remove or move. Press and hold, then drag to rearrange.';

  @override
  String get sentenceChipUntitled => 'Word without text';

  @override
  String get sentenceRemoveWord => 'Remove from sentence';

  @override
  String get sentenceMoveLeft => 'Move left';

  @override
  String get sentenceMoveRight => 'Move right';

  @override
  String get pinSectionTitle => 'Edit protection';

  @override
  String get pinSectionHelp =>
      'With a PIN, entering edit mode requires typing 4 numbers. This keeps children from changing the boards.';

  @override
  String get pinSwitchTitle => 'Ask for a PIN to edit';

  @override
  String get pinOn => 'On';

  @override
  String get pinOff => 'Off';

  @override
  String get pinChange => 'Change PIN';

  @override
  String get pinEnterTitle => 'Enter the PIN';

  @override
  String get pinWrong => 'Wrong PIN. Please try again.';

  @override
  String get pinForgot => 'I forgot the PIN';

  @override
  String get pinSetupTitle => 'Choose a 4-number PIN';

  @override
  String get pinSetupHelp =>
      'Write the PIN down somewhere safe. If you forget it, a multiplication problem unlocks editing.';

  @override
  String get pinConfirmTitle => 'Enter the PIN again';

  @override
  String get pinMismatch => 'The PINs do not match. Choose again.';

  @override
  String get pinSaved => 'PIN turned on.';

  @override
  String get pinChanged => 'PIN changed.';

  @override
  String get pinRemoved => 'PIN turned off.';

  @override
  String get pinSaveFailed => 'Could not save the PIN. Please try again.';

  @override
  String get pinBackspace => 'Delete the last number';

  @override
  String pinDotsLabel(int filled, int total) {
    return '$filled of $total numbers entered';
  }

  @override
  String get pinForgotTitle => 'I forgot the PIN';

  @override
  String pinForgotQuestion(int a, int b) {
    return 'To unlock editing, solve this: what is $a × $b?';
  }

  @override
  String get pinForgotAnswer => 'Answer';

  @override
  String get pinForgotWrong => 'Wrong answer. Here is another problem.';

  @override
  String get pinForgotConfirm => 'Unlock';

  @override
  String get commonLoading => 'Loading';

  @override
  String get editLockTapHint => 'see how to unlock';

  @override
  String get editLockLongPressHint => 'unlock editing';

  @override
  String get editModeOnAnnounce => 'Edit mode on.';

  @override
  String get editModeOffAnnounce => 'Edit mode off.';

  @override
  String boardMoreOptionsFor(String name) {
    return 'More options for $name';
  }

  @override
  String get splashSkipHint => 'Tap to skip the intro.';

  @override
  String boardFormCellTooSmall(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max columns',
      one: '1 column',
    );
    return 'On this device, with more than $_temp0 the cards get too small to tap easily. Consider using fewer columns.';
  }

  @override
  String get editIdleSectionTitle => 'Automatic edit lock';

  @override
  String get editIdleHelp =>
      'After this much time without touching the screen, edit mode locks by itself and the app goes back to use mode.';

  @override
  String get editIdleOff => 'Never';

  @override
  String editIdleMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get editIdleLockedNotice => 'Editing locked due to inactivity.';

  @override
  String get cardMove => 'Move…';

  @override
  String get cardMoveTitle => 'Move card';

  @override
  String cardMoveRowOf(int row, int total) {
    return 'Row $row of $total';
  }

  @override
  String cardMoveColumnOf(int column, int total) {
    return 'Column $column of $total';
  }

  @override
  String get cardMoveRowPrev => 'Previous row (up)';

  @override
  String get cardMoveRowNext => 'Next row (down)';

  @override
  String get cardMoveColumnPrev => 'Previous column (left)';

  @override
  String get cardMoveColumnNext => 'Next column (right)';

  @override
  String cardMoveWillMove(int row, int column) {
    return 'Moves to row $row, column $column.';
  }

  @override
  String cardMoveWillSwap(String label) {
    return 'Swaps places with “$label”.';
  }

  @override
  String get cardMoveBlocked => 'It doesn’t fit there.';

  @override
  String get cardMoveUnchanged => 'Already in this position.';

  @override
  String get cardMoveConfirm => 'Move';

  @override
  String get cardMoveDone => 'Card moved.';

  @override
  String get cardSwapDone => 'Cards swapped.';
}
