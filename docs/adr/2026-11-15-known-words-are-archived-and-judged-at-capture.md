# Known words are archived rather than deleted, and judged for difficulty at capture

## Decision

- Swiping a word away marks it archived instead of deleting it. An archived word leaves review and active lists, stays in the shared word list so the capture hook never suggests it again, and can be restored.
- Every word carries a difficulty (common, advanced or rare), judged by the background agent at capture alongside the suggestion.

## Why

Deleting a word Alex already knows would let the capture hook suggest the same word on a future prompt. Keeping it in the one word list as archived remembers that he knows it without keeping it in review. Judging difficulty when the word is first captured avoids maintaining a separate dictionary or a second model pass over saved words.

## Rejected

- **Deleting words and keeping a separate blocklist.** Splits one list into two stores that can drift apart and complicates restoring a word archived by mistake.
- **Hiding archived words from the capture list.** Would defeat archiving by letting the hook re-suggest words Alex already marked as known.
- **Computing difficulty from word-frequency tables or a second pass.** Frequency lists miss engineering register (words like idempotent or canonical), and a second pass spends extra model calls.
