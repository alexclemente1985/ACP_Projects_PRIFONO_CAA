// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Privox';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get themeSectionTitle => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageAutomatic => 'Automático';

  @override
  String get languageHelp =>
      'El idioma se aplica a la app, a la búsqueda de pictogramas y a la voz.';

  @override
  String get creditsButton => 'Acerca de y créditos';

  @override
  String get boardsTitle => 'Tableros';

  @override
  String get boardsEmptyTitle => 'Todavía no hay tableros';

  @override
  String get boardsEmptyMessage => 'Crea tu primer tablero de comunicación.';

  @override
  String get boardsEmptyAction => 'Crear primer tablero';

  @override
  String get boardsLoadError => 'No se pudieron cargar los tableros.';

  @override
  String get boardNew => 'Nuevo tablero';

  @override
  String get boardEdit => 'Editar';

  @override
  String get boardDelete => 'Eliminar';

  @override
  String get boardMoreOptions => 'Más opciones';

  @override
  String boardGridSummary(int columns, int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      columns,
      locale: localeName,
      other: '$columns columnas',
      one: '1 columna',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows filas',
      one: '1 fila',
    );
    return '$_temp0 × $_temp1';
  }

  @override
  String get boardActionFailed =>
      'No se pudo completar la acción. Inténtalo de nuevo.';

  @override
  String boardGridTooSmall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas',
      one: '1 tarjeta',
    );
    return 'Quita $_temp0 antes de reducir la cuadrícula.';
  }

  @override
  String get boardEmptyHint => 'Toca el + para añadir la primera tarjeta.';

  @override
  String boardFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'las $count posiciones están ocupadas',
      one: 'la única posición está ocupada',
    );
    return 'Tablero lleno: $_temp0. Aumenta la cuadrícula o libera posiciones para añadir más.';
  }

  @override
  String get boardCardsLoadError => 'No se pudieron cargar las tarjetas.';

  @override
  String get cardAdd => 'Añadir tarjeta';

  @override
  String cardAddAt(int row, int column) {
    return 'Añadir tarjeta en la fila $row, columna $column';
  }

  @override
  String get cardEditorNewTitle => 'Nueva tarjeta';

  @override
  String get cardEditorEditTitle => 'Editar tarjeta';

  @override
  String get cardLabelLabel => 'Texto de la tarjeta';

  @override
  String get cardLabelRequired => 'Escribe el texto de la tarjeta.';

  @override
  String get cardSpeechLabel => 'Texto hablado (opcional)';

  @override
  String get cardSpeechHelper =>
      'Si lo dejas vacío, la app dice el texto de la tarjeta.';

  @override
  String get cardSaving => 'Guardando…';

  @override
  String get cardSymbolSectionTitle => 'Pictograma';

  @override
  String get cardSymbolChoose => 'Elegir pictograma';

  @override
  String get cardSymbolChange => 'Cambiar pictograma';

  @override
  String get cardSymbolRemove => 'Quitar pictograma';

  @override
  String get cardSymbolDownloading => 'Descargando el pictograma…';

  @override
  String get cardSymbolFailedHint =>
      'Inténtalo de nuevo o quita el pictograma para guardar solo con texto.';

  @override
  String get cardClassSectionTitle => 'Clase gramatical';

  @override
  String get cardClassHelper =>
      'El color de la tarjeta sigue el código de colores de Fitzgerald. Elige la clase de la palabra.';

  @override
  String get wordClassNone => 'Ninguna';

  @override
  String get wordClassPronoun => 'Pronombre';

  @override
  String get wordClassVerb => 'Verbo';

  @override
  String get wordClassNoun => 'Sustantivo';

  @override
  String get wordClassAdjective => 'Adjetivo';

  @override
  String get wordClassPreposition => 'Preposición o palabra social';

  @override
  String get wordClassQuestion => 'Pregunta';

  @override
  String get wordClassNegation => 'Negación o urgencia';

  @override
  String get wordClassAdverb => 'Adverbio';

  @override
  String get wordClassConjunction => 'Conjunción';

  @override
  String get wordClassDeterminer => 'Determinante';

  @override
  String get cardDelete => 'Eliminar tarjeta';

  @override
  String get cardDeleteTitle => '¿Eliminar tarjeta?';

  @override
  String cardDeleteMessage(String label) {
    return 'La tarjeta “$label” se eliminará. Esta acción no se puede deshacer.';
  }

  @override
  String get boardFormNewTitle => 'Nuevo tablero';

  @override
  String get boardFormEditTitle => 'Editar tablero';

  @override
  String get boardFormNameLabel => 'Nombre del tablero';

  @override
  String get boardFormNameRequired => 'Ponle un nombre al tablero.';

  @override
  String get boardFormColumns => 'Columnas';

  @override
  String get boardFormRows => 'Filas';

  @override
  String get boardColumnsDecrease => 'Reducir columnas';

  @override
  String get boardColumnsIncrease => 'Aumentar columnas';

  @override
  String get boardRowsDecrease => 'Reducir filas';

  @override
  String get boardRowsIncrease => 'Aumentar filas';

  @override
  String boardFormShrinkBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas',
      one: '1 tarjeta',
    );
    return 'Hay $_temp0 en la última columna o fila. Para reducir más la cuadrícula, vacía ese espacio antes.';
  }

  @override
  String get boardDeleteTitle => '¿Eliminar tablero?';

  @override
  String boardDeleteMessage(String name) {
    return 'El tablero “$name” y todas sus tarjetas se eliminarán. Esta acción no se puede deshacer.';
  }

  @override
  String get searchTitle => 'Buscar pictogramas';

  @override
  String get searchHint => 'Escribe una palabra';

  @override
  String get searchClear => 'Borrar búsqueda';

  @override
  String get searchLoading => 'Buscando';

  @override
  String get searchIdleMessage =>
      'Escribe una palabra para buscar pictogramas.';

  @override
  String searchEmptyMessage(String query) {
    return 'No se encontró ningún pictograma para “$query”.';
  }

  @override
  String get searchErrorOffline =>
      'Sin conexión a internet. Comprueba la red e inténtalo de nuevo.';

  @override
  String get searchErrorTimeout =>
      'La búsqueda tardó demasiado. Inténtalo de nuevo.';

  @override
  String get searchErrorServer =>
      'El servicio de pictogramas no está disponible en este momento.';

  @override
  String get searchErrorGeneric =>
      'No se pudo leer la respuesta del servicio de pictogramas.';

  @override
  String get searchRetry => 'Reintentar';

  @override
  String get imageUnavailable => 'Imagen no disponible';

  @override
  String get speechVoiceMissing =>
      'No hay una voz en español en este dispositivo. Instala una en los ajustes de voz del dispositivo.';

  @override
  String get speechFailed => 'No se pudo hablar ahora. Inténtalo de nuevo.';

  @override
  String get attributionShort =>
      'Pictogramas: ARASAAC (Gobierno de Aragón), licencia CC BY-NC-SA. Toca para ver los créditos.';

  @override
  String get creditsTitle => 'Acerca de y créditos';

  @override
  String get creditsArasaacTitle => 'Pictogramas';

  @override
  String get creditsArasaacOfficial =>
      'Los símbolos pictográficos utilizados son propiedad del Gobierno de Aragón y han sido creados por Sergio Palao para ARASAAC (http://www.arasaac.org), que los distribuye bajo Licencia Creative Commons BY-NC-SA.';

  @override
  String get creditsArasaacBody =>
      'Los símbolos pictográficos utilizados son propiedad del Gobierno de Aragón y han sido creados por Sergio Palao para ARASAAC (https://arasaac.org), que los distribuye bajo licencia Creative Commons (BY-NC-SA).';

  @override
  String get creditsArasaacTerms =>
      'Los pictogramas son para uso no comercial. Al compartir pictogramas o tableros hechos con ellos, mantén la atribución a ARASAAC y usa la misma licencia (CC BY-NC-SA).';

  @override
  String get creditsPrivacyTitle => 'Privacidad de la búsqueda';

  @override
  String get creditsPrivacyBody =>
      'Al buscar pictogramas, la palabra escrita y la dirección IP del dispositivo se envían a los servidores de ARASAAC. La app no envía datos personales ni usa cuenta. Los pictogramas que eliges se guardan en el dispositivo para funcionar sin internet.';

  @override
  String get aboutTagline =>
      'Tableros de comunicación gratuitos, sin cuenta y sin anuncios.';

  @override
  String get aboutMakersTitle => 'Quién hace Privox';

  @override
  String get aboutMadeBy => 'Desarrollado por ACP Projects.';

  @override
  String get aboutClinic =>
      'En colaboración con la consulta PRIFONO, de la logopeda Priscilla de Sá.';

  @override
  String get aboutPolicyTitle => 'Política de privacidad';

  @override
  String get aboutPolicyBody =>
      'La política de privacidad completa está en esta dirección:';

  @override
  String get sentenceBarLabel => 'Frase';

  @override
  String get sentenceHint => 'Toca las tarjetas para formar una frase.';

  @override
  String get sentenceSpeak => 'Decir la frase';

  @override
  String get sentenceDeleteLast => 'Borrar la última palabra';

  @override
  String get sentenceClear => 'Borrar la frase';

  @override
  String get editLockEnter =>
      'Entrar en el modo de edición. Mantén pulsado para desbloquear.';

  @override
  String get editLockLeave => 'Salir del modo de edición';

  @override
  String get editLockHoldHint =>
      'Mantén pulsado el candado 1,5 segundos para editar.';

  @override
  String get editModeHint => 'Modo de edición: toca una tarjeta para editarla.';

  @override
  String get boardEmptyUseHint =>
      'Este tablero está vacío. Mantén pulsado el candado 1,5 segundos para añadir tarjetas.';

  @override
  String get cardLinkTitle => 'Abrir otro tablero al tocar';

  @override
  String get cardLinkNone => 'Ninguno (la tarjeta solo habla)';

  @override
  String get cardLinkEmpty =>
      'Crea otro tablero para poder enlazar esta tarjeta con él.';

  @override
  String get cardOpensBoardHint => 'Abre otro tablero';

  @override
  String get sentenceChipHint =>
      'Toca para quitar o mover. Mantén pulsado y arrastra para reorganizar.';

  @override
  String get sentenceChipUntitled => 'Palabra sin texto';

  @override
  String get sentenceRemoveWord => 'Quitar de la frase';

  @override
  String get sentenceMoveLeft => 'Mover a la izquierda';

  @override
  String get sentenceMoveRight => 'Mover a la derecha';

  @override
  String get pinSectionTitle => 'Protección de la edición';

  @override
  String get pinSectionHelp =>
      'Con PIN, entrar en el modo de edición exige escribir 4 números. Así los niños no pueden cambiar los tableros.';

  @override
  String get pinSwitchTitle => 'Pedir PIN para editar';

  @override
  String get pinOn => 'Activado';

  @override
  String get pinOff => 'Desactivado';

  @override
  String get pinChange => 'Cambiar PIN';

  @override
  String get pinEnterTitle => 'Escribe el PIN';

  @override
  String get pinWrong => 'PIN incorrecto. Inténtalo de nuevo.';

  @override
  String get pinForgot => 'He olvidado el PIN';

  @override
  String get pinSetupTitle => 'Elige un PIN de 4 números';

  @override
  String get pinSetupHelp =>
      'Apunta el PIN en un lugar seguro. Si lo olvidas, una multiplicación desbloquea la edición.';

  @override
  String get pinConfirmTitle => 'Escribe el PIN otra vez';

  @override
  String get pinMismatch => 'Los PIN no coinciden. Elige uno de nuevo.';

  @override
  String get pinSaved => 'PIN activado.';

  @override
  String get pinChanged => 'PIN cambiado.';

  @override
  String get pinRemoved => 'PIN desactivado.';

  @override
  String get pinSaveFailed => 'No se pudo guardar el PIN. Inténtalo de nuevo.';

  @override
  String get pinBackspace => 'Borrar el último número';

  @override
  String pinDotsLabel(int filled, int total) {
    return '$filled de $total números escritos';
  }

  @override
  String get pinForgotTitle => 'He olvidado el PIN';

  @override
  String pinForgotQuestion(int a, int b) {
    return 'Para desbloquear la edición, resuelve: ¿cuánto es $a × $b?';
  }

  @override
  String get pinForgotAnswer => 'Respuesta';

  @override
  String get pinForgotWrong => 'Respuesta incorrecta. Esta es otra cuenta.';

  @override
  String get pinForgotConfirm => 'Desbloquear';

  @override
  String get commonLoading => 'Cargando';

  @override
  String get editLockTapHint => 'ver cómo desbloquear';

  @override
  String get editLockLongPressHint => 'desbloquear la edición';

  @override
  String get editModeOnAnnounce => 'Modo de edición activado.';

  @override
  String get editModeOffAnnounce => 'Modo de edición desactivado.';

  @override
  String boardMoreOptionsFor(String name) {
    return 'Más opciones de $name';
  }

  @override
  String get splashSkipHint => 'Toca para omitir la introducción.';

  @override
  String boardFormCellTooSmall(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max columnas',
      one: '1 columna',
    );
    return 'En este dispositivo, con más de $_temp0 las tarjetas quedan demasiado pequeñas para tocarlas con facilidad. Considera usar menos columnas.';
  }

  @override
  String get editIdleSectionTitle => 'Bloqueo automático de la edición';

  @override
  String get editIdleHelp =>
      'Si pasa este tiempo sin tocar la pantalla, el modo de edición se bloquea solo y la app vuelve al modo de uso.';

  @override
  String get editIdleOff => 'Nunca';

  @override
  String editIdleMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get editIdleLockedNotice => 'Edición bloqueada por inactividad.';
}
