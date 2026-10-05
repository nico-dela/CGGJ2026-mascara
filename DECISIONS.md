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

## 2026-10-04 20:50:00 — Football evidence is a lead, not an arrest
- What: Reframed the American football as a muddy sole print proving the bartender was in the woods; police refuses to jail him on that alone (no body / no complaint). Confession still needs bear mask + Talk.
- Why: Clear fingerprints that identify the bartender made “why isn’t he arrested?” feel broken.
- Rejected: Keeping courtroom-grade fingerprint framing; making arrest the case climax.
- Pending: None.

## 2026-10-04 19:45:00 — Hybrid item puzzles and hawker rename
- What: Case pacing starts after bar + comisario briefing; football from hawker post-briefing; optional duck from fisherman; bear mask and log always in forest (Take gated); removed NPC mask-swap stretch; renamed road police → hawker (`hablado_hawker`); Gilbert-style mask/routine ending; English code convention noted in AGENTS/CODE_QUALITY.
- Why: Teleport-spawn pickups felt gamey; hawker should seed mystery first; only the bear mask advances plot; ending needed a thematic punchline.
- Rejected: Forest pop-in for pelota/patito/oso; football on first hawker talk; duck as hard gate; keeping bartender/police/hawker mask swaps.
- Pending: Playtest full critical path after bar → briefing → hawker ball → huellas → oso → axe → expose → ending.

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
