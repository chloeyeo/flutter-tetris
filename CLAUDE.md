# CLAUDE.md

Guidance for Claude Code when working in this repository (Flutter Tetris game).

## Git discipline — single-purpose commits (operator directive, MANDATORY)

Operator: "깃에는 같은 성격만 커밋하는게 나중에 revert하기도 좋아요" — every
commit must be revertable ALONE when it turns out to be the problem.

1. **One concern per commit.** Exactly one bug, one feature, or one refactor
   per commit; two unrelated concerns = two commits, even in one session.
   The test: "if this change is wrong, can the operator revert THIS commit
   without losing an unrelated fix?" If no, split.
2. **A fix + its regression test = ONE concern** — same commit, so reverting
   the fix reverts its guard. Tests for OTHER behaviors, invariant suites,
   or test refactors are separate commits.
3. **No drive-by changes.** No cosmetic fixes, renames, formatting, typos,
   or "while I'm here" improvements inside a functional commit — even
   one-liners. Spotted something? Register it as a follow-up or commit it
   separately after.
4. **Messages: concise, scoped, mechanism-first.** `type: <what changed,
   naming the actual mechanism>` (fix/feat/refactor/test/docs/chore) — e.g.
   "fix: run per-keyword wiki-search fallback so contradiction arm receives
   candidates", never "fix wiki bug". One line, imperative, ≤72 chars where
   possible; body only when the WHY isn't obvious. Describe what the commit
   DOES, not the session's goal.
5. **Scope shifted mid-work? The message follows reality.** If the real fix
   differs from the assigned hypothesis (assigned as routing, landed as
   retrieval), name what was ACTUALLY changed — never describe the plan.
6. **Ask before bundling.** If a split seems genuinely impossible (e.g. an
   atomic many-file rename), propose the split explicitly BEFORE committing
   — never decide unilaterally to bundle.
