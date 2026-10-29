/// Classe gramatical de um card: base do código de cores da Chave de
/// Fitzgerald (ADR-038).
///
/// A COR de cada classe não fica aqui (domínio não conhece cores): ela está em
/// `CardColors.forWordClass`.
enum WordClass {
  pronoun('pronoun'),
  verb('verb'),
  noun('noun'),
  adjective('adjective'),
  preposition('preposition'),
  question('question'),
  negation('negation'),
  adverb('adverb'),
  conjunction('conjunction'),
  determiner('determiner');

  const WordClass(this.key);

  /// Texto estável gravado no banco (coluna `word_class`) e, no futuro, nos
  /// arquivos de backup. NUNCA mude um valor já publicado: os cards salvos
  /// perderiam a classe.
  final String key;

  /// Volta do texto gravado para a classe. Chave desconhecida (ou nula) vira
  /// `null` = sem classe, em vez de derrubar o app (ex.: banco vindo de uma
  /// versão futura).
  static WordClass? fromKey(String? key) {
    if (key == null) return null;
    for (final value in values) {
      if (value.key == key) return value;
    }
    return null;
  }
}
