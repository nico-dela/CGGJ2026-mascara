# CODE_QUALITY.md

See AGENTS.md for how to work in this repo.

## Language

- **English** for GDScript identifiers, comments, commit messages, and agent-authored docs.
- **Spanish** is the source for dialogue files (`content/dialogue/**`). English for players lives in [`locale/dialogue.csv`](locale/dialogue.csv) (CSV translation; keys = Spanish lines).
- When dialogue Spanish changes, update the matching `keys`/`en` rows so English locale stays in sync. Prefer natural English, not word-for-word calques.
- Prefer English names when introducing new scripts/flags (e.g. `hawker.gd`, `hablado_hawker`). Do not mass-rename existing Spanish story ids unless the change is already in scope.

Reply and explain code in English, even when the prompt is in another language. Agent-drafted commit messages are imperative and in English.
