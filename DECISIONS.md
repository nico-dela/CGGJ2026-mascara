# DECISIONS.md

Work-session log. A short entry when closing each non-trivial session. It does not replace git history.

New entries are in English.

## Entry format

```markdown
## YYYY-MM-DD HH:MM:ss — <short title>
- What:
- Why:
- Rejected:
- Pending:
```

## 2026-10-02 19:55:00 — Sync feature/gilbert-progression to origin
- What: Fast-forwarded local branch 15 commits to origin tip `288ef13`; removed ~186 `*.from-home` snapshots and colliding untracked copies; restored English `AGENTS.md` plus local-only `CODE_QUALITY.md` / `DECISIONS.md` / `MCP_USAGE.md` / `.cursor/rules/respond-in-english.mdc`; deleted local ref `feature/gilbert-progression.from-home`.
- Why: Working tree mixed an old road-guard checkout with a home-machine dump; gameplay and docs no longer matched memory or remote.
- Rejected: Re-applying hop/river/`player.gd` experiments from from-home (not on origin).
- Pending: Commit English agent docs when desired.

## 2026-10-02 20:02:00 — Match live Netlify via origin/main
- What: Fast-forwarded `feature/gilbert-progression` to `origin/main` (`5523bbf`): river stone hops, Y-depth scale, fisherman approach/hitbox, axe art, credits typography, matching `build/index.pck` (21346460). Restored English agent docs afterward.
- Why: [elcasodellenador.netlify.app](https://elcasodellenador.netlify.app/) deploys `main`, which is 8 commits ahead of `origin/feature/gilbert-progression` after the feature PR merge.
- Rejected: Switching the working branch to `main` (kept feature branch).
- Pending: Push feature branch if remote should track this tip; commit English agent docs when desired.
