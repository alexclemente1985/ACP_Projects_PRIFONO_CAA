/// Lista ordenada de migrações do banco. O índice + 1 é a versão do esquema.
///
/// REGRA DE OURO: uma migração já publicada NUNCA é editada. Para mudar o
/// esquema, acrescente uma nova migração no fim da lista.
const List<List<String>> kMigrations = [
  _v1,
  _v2,
  _v3,
];

const List<String> _v1 = [
  '''
  CREATE TABLE boards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    grid_columns INTEGER NOT NULL DEFAULT 4
      CHECK (grid_columns BETWEEN 1 AND 10),
    grid_rows INTEGER NOT NULL DEFAULT 4
      CHECK (grid_rows BETWEEN 1 AND 10),
    position INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE cards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    board_id INTEGER NOT NULL
      REFERENCES boards(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    label TEXT NOT NULL DEFAULT '',
    speech_text TEXT,
    symbol_source TEXT,
    symbol_id TEXT,
    symbol_locale TEXT,
    image_path TEXT,
    background_color INTEGER,
    link_board_id INTEGER
      REFERENCES boards(id) ON DELETE SET NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ''',
  'CREATE INDEX idx_cards_board_position ON cards (board_id, position)',
  '''
  CREATE TABLE app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
  ''',
];

/// Classe gramatical do card (ADR-038, Chave de Fitzgerald). Texto estável de
/// `WordClass.key`; NULL = sem classe. Cards antigos ficam com NULL.
const List<String> _v2 = [
  'ALTER TABLE cards ADD COLUMN word_class TEXT',
];

/// Posição e tamanho do card na grade (ADR-042, E6b-1). Os nomes são
/// `grid_col` e `grid_row` (e não `col`/`row`) para não depender de `ROW`
/// ser aceita como nome de coluna em todo SQLite.
///
/// Os cards que já existem são posicionados pela ORDEM DE LEITURA que tinham
/// (`position`, desempate por `id`) na largura da grade da própria prancha,
/// com tamanho 1×1: a prancha antiga fica idêntica. O índice de leitura de um
/// card é quantos cards da mesma prancha vêm antes dele. Usa subconsulta
/// correlacionada (e não `ROW_NUMBER()`) para funcionar em SQLite antigo.
///
/// A coluna `position` continua existindo (NOT NULL, sem valor padrão) e o
/// repositório segue gravando um número nela, mas o app não a lê mais.
const List<String> _v3 = [
  'ALTER TABLE cards ADD COLUMN grid_col INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE cards ADD COLUMN grid_row INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE cards ADD COLUMN col_span INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE cards ADD COLUMN row_span INTEGER NOT NULL DEFAULT 1',
  '''
  UPDATE cards SET
    grid_col = (
      SELECT COUNT(*) FROM cards AS earlier
      WHERE earlier.board_id = cards.board_id
        AND (earlier.position < cards.position
          OR (earlier.position = cards.position AND earlier.id < cards.id))
    ) % (SELECT grid_columns FROM boards WHERE boards.id = cards.board_id),
    grid_row = (
      SELECT COUNT(*) FROM cards AS earlier
      WHERE earlier.board_id = cards.board_id
        AND (earlier.position < cards.position
          OR (earlier.position = cards.position AND earlier.id < cards.id))
    ) / (SELECT grid_columns FROM boards WHERE boards.id = cards.board_id)
  ''',
  'CREATE INDEX idx_cards_board_cell ON cards (board_id, grid_row, grid_col)',
];
