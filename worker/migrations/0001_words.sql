-- One row per word: what the background agent suggested and where the word is in review.
CREATE TABLE words (
  -- AUTOINCREMENT: a deleted word's id is never reused, so a stale app cannot review the wrong word.
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  word TEXT NOT NULL UNIQUE COLLATE NOCASE,
  part_of_speech TEXT NOT NULL,
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
  reviewed_at TEXT
);
