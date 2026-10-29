/// Lista ordenada de migrações do banco. O índice + 1 é a versão do esquema.
///
/// REGRA DE OURO: uma migração já publicada NUNCA é editada. Para mudar o
/// esquema, acrescente uma nova migração no fim da lista.
const List<List<String>> kMigrations = [
  _v1,
  _v2,
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
