-- One row per word: what the background agent suggested and where the word is in review.
CREATE TABLE words (
  -- AUTOINCREMENT: a word's id is never reused, so a stale app cannot act on the wrong word.
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  word TEXT NOT NULL UNIQUE COLLATE NOCASE,
  part_of_speech TEXT NOT NULL,
  difficulty TEXT NOT NULL CHECK (difficulty IN ('common', 'advanced', 'rare')),
  definition TEXT NOT NULL,
  -- The writer's own wording that the word replaces, copied from the prompt.
  phrase TEXT NOT NULL,
  -- The prompt restated concisely with the word.
  rewrite TEXT NOT NULL,
  created_at TEXT NOT NULL,
  -- NULL until the word is first opened in an app: a new word.
  seen_at TEXT,
  due_at TEXT NOT NULL,
  interval_days INTEGER NOT NULL,
  ease REAL NOT NULL,
  reps INTEGER NOT NULL,
  lapses INTEGER NOT NULL,
  reviewed_at TEXT,
  -- NULL while in review; set when swiped away as known so it stays saved and is never suggested again.
  archived_at TEXT
);
