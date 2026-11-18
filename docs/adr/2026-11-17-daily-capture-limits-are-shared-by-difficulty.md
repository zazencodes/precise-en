# Daily capture limits are shared by difficulty

## Decision

Each difficulty has its own daily allowance for new words. Settings on either device changes the shared allowance immediately. A saved word counts for its whole UTC calendar day, including after archival. The hook checks which categories have room before asking for a suggestion. The Worker enforces the limit when saving.

## Why

A burst of prompts can produce more words than someone can learn. Separate allowances leave room for advanced and rare words. A single day boundary keeps all captures and devices in agreement.

## Rejected

- **A limit on daily reviews.** Captures would continue accumulating in the backlog.
- **Checking only in the hook.** Concurrent prompts could take the same last slot.
