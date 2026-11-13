/// Opções do bloqueio automático do modo de edição por inatividade (E6-5,
/// ADR-041, decisão 5).
///
/// O valor é guardado em MINUTOS; 0 significa "desligado". Um valor guardado
/// que não esteja nas opções (arquivo antigo, corrompido, editado à mão) volta
/// ao padrão em vez de travar a edição em um tempo estranho.
abstract final class EditIdleTimeout {
  /// Minutos oferecidos em Ajustes (0 = desligado).
  static const List<int> options = [0, 2, 5, 10];

  /// Padrão: 5 minutos, tempo para quem ajuda a pessoa a montar a prancha sem
  /// ser interrompido o tempo todo, e curto o bastante para a criança não achar
  /// o app esquecido em modo de edição.
  static const int defaultMinutes = 5;

  /// Converte o texto guardado em minutos válidos.
  static int fromStorage(String? stored) {
    final minutes = int.tryParse(stored ?? '');
    if (minutes != null && options.contains(minutes)) return minutes;
    return defaultMinutes;
  }

  /// Minutos como tempo de espera; `null` quando o bloqueio está desligado.
  static Duration? toDuration(int minutes) =>
      minutes <= 0 ? null : Duration(minutes: minutes);
}
