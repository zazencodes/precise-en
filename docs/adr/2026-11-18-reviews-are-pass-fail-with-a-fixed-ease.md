# Reviews are pass/fail, with one fixed ease for every word

## Decision

- A revealed card has two ratings: Again when you didn't recall the meaning, Good when you did. On the Mac, Again is 1 and Good is Space, Anki's keys, so a word you knew takes Space twice.
- Every word grows by the same fixed ease. Again sends a word back to relearning without lowering how fast it grows afterwards.

## Why

Alex asked for two buttons and for the conventions the Japanese-learning Anki community settled on (AJATT/Tatsumoto, Refold, MIA, "low-key Anki"): grade only Again and Good, and keep ease constant. Hard and Easy are judged inconsistently and only move ease. With pass/fail grading, an ease that only Again can change can only fall, sinking forgotten words into ever shorter intervals ("ease hell").

## Rejected

- **Again and Easy.** Easy means a word was trivial, which is what Archive is for; the community's pass button is Good.
- **Keeping four ratings and hiding two.** Leaves two ways to pass and dead schedule code.
- **Pass/fail with per-word ease that falls on Again.** Ease hell, as above.
- **FSRS.** A larger model whose benefit needs far more review history than a personal word list builds.
