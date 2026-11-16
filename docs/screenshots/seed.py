"""Turns the words from `wrangler d1 execute --remote --json` (on stdin) into SQL for a local copy.

The chosen word becomes the first card in Review, and its phrase and rewrite are replaced with
invented ones, since every real card quotes one of your prompts.

Usage: seed.py WORD PHRASE REWRITE < words.json > seed.sql
"""
import json
import sys

word, phrase, rewrite = sys.argv[1:]
if word.lower() not in rewrite.lower():
    sys.exit(f"seed.py: the rewrite must use {word!r}, which the card shows in pink")

rows = json.load(sys.stdin)[0]["results"]
chosen = [row for row in rows if row["word"].lower() == word.lower()]
if not chosen:
    sys.exit(f"seed.py: {word!r} is not in your word list")
chosen[0].update(phrase=phrase, rewrite=rewrite, due_at="2000-01-01T00:00:00Z", archived_at=None)


def sql(value):
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


for row in rows:
    print(f"INSERT INTO words ({', '.join(row)}) VALUES ({', '.join(sql(v) for v in row.values())});")
