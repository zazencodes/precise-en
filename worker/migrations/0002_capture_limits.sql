CREATE TABLE capture_limits (
  difficulty TEXT PRIMARY KEY CHECK (difficulty IN ('common', 'advanced', 'rare')),
  daily_limit INTEGER NOT NULL CHECK (daily_limit BETWEEN 0 AND 99)
) STRICT;

INSERT INTO capture_limits VALUES ('common', 5), ('advanced', 5), ('rare', 5);
CREATE INDEX words_by_difficulty_and_creation ON words(difficulty, created_at);

CREATE VIEW daily_capture AS
SELECT difficulty, daily_limit, (
  SELECT COUNT(*) FROM words
  WHERE words.difficulty = capture_limits.difficulty
    AND created_at >= strftime('%Y-%m-%dT00:00:00Z', 'now')
    AND created_at < strftime('%Y-%m-%dT00:00:00Z', 'now', '+1 day')
) AS captured_today
FROM capture_limits;
