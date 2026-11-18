-- Reviews are pass/fail with one fixed ease for every word, so no word keeps its own.
ALTER TABLE words DROP COLUMN ease;
