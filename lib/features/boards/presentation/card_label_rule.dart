/// Rótulo do card depois que a pessoa escolhe um pictograma (ADR-030, item 8).
///
/// Troca o rótulo quando ele está vazio OU ainda é exatamente o texto que o
/// pictograma anterior preencheu ([autoFilled]): assim, trocar de pictograma
/// antes de salvar atualiza o texto. Se a pessoa escreveu ou mudou o rótulo,
/// ele é mantido.
String labelAfterPick({
  required String current,
  required String? autoFilled,
  required String pickLabel,
}) {
  final text = current.trim();
  if (text.isEmpty || text == autoFilled) return pickLabel;
  return current;
}
