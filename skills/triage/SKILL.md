---
name: triage
description: Lean Context Development triage. Use when starting non-trivial new work in any LCD-onboarded project — a new feature, a multi-file change, a refactor that alters architecture, or anything you'd want a fresh session to pick up cold. Scores the work, picks a lane (Quick / Standard / Deep), states it in one line, and routes. Not for typo fixes, single-line edits, dependency bumps, formatting, or a bug fix whose cause is already known.
user-invocable: true
---

# LCD Triage (the front door)

The single entry point for new work under Lean Context Development: score the work, pick a lane,
route. Guiding principle — spend the minimum process the work needs, and write down exactly
enough that a cold session resumes cheaply.

## Step 0 — resolve project context (cheap)

Read `.claude/rules/lcd-conventions.md`'s `<!-- lcd-conventions:v1 -->` block for `artifact-root`
(default `docs/lcd`). If the project has no `lcd-conventions.md`, it isn't onboarded — say so and
suggest `/lcd:onboard` (then proceed in Quick lane for the immediate ask, since you have no MAP yet).
Glance at `<artifact-root>/MAP.md` Zones/Invariants only if the work is clearly Standard/Deep —
skip it for obviously-Quick work (don't pay for context you won't use).

If the block has `living-spec: on` and the work is Standard/Deep, also read **only the SPEC
section for the work's surface(s)** in `<artifact-root>/SPEC.md` (not the whole file — the same
selective discipline as resume reading DECISIONS headers). This is what the system already does in
that area, so you don't re-implement or contradict an existing capability. Skip for Quick work and
when `living-spec` is off.

## Step 1 — score the work (six signals)

Count how many signals fire toward the heavier columns:

| Signal | Quick | Standard | Deep |
|---|---|---|---|
| Files touched | 1–2 | 3–8 | 9+ |
| Architecture impact | none | local/contained | new module · cross-cutting · new dependency |
| Surfaces (CLI/HTTP/MCP/RENDER/DB/EVAL) | 0–1 | 1, or 2 sharing one path | 2+ parallel, or any EVAL |
| Reversibility | trivial revert | one-commit revert | schema/migration/public API |
| Cold-pickup plausibility | one sitting | may span a session | multi-session / multi-phase |
| Silently-wrong risk | none | low | scorer/ranker/LLM-output → EVAL |

File count is a soft proxy, not a hard Deep trigger — the rationale lives in the `lcd` rule
(`rules/lcd.md`); the cap in Step 2 is what keeps pure file-count accumulation from reaching Deep.

## Step 2 — route

Two terms decide the heavy lane:

- A **hard trigger** is any Deep-column hit on **architecture / parallel-surfaces / EVAL /
  irreversibility** (schema/migration/public API).
- A **risk signal** is **multi-session cold-pickup** — the one soft signal whose downstream cost
  warrants the full pipeline on its own. (Deep-level irreversibility is already a hard trigger, so
  it can never reach the count-based branch below.)

Then:

- **Any hard trigger → Deep** (regardless of count).
- **Otherwise, count the signals firing toward heavier columns:**
  - **0–1 → Quick.**
  - **2–3 → Standard.**
  - **4+ → Standard, UNLESS a risk signal is among them → Deep.** Pure soft-signal accumulation
    (no hard trigger, no risk signal) **caps at Standard**.
- **Ties round DOWN** (anti-overengineering). The user may override in one word ("make it deep", "just do it").

## Step 3 — state the verdict in ONE line, then proceed

Format: `LCD → <Lane> (<n> signals): <artifact note>. <one-clause reason>.`
e.g. `LCD → Standard (3 signals): single JOURNAL at docs/lcd/work/export-csv/. 4 files, 1 surface, reversible, may span a session.`
Do not over-explain. One line, then act.

## Step 4 — log the routing decision (telemetry)

One append per triage — this is how LCD measures its own lane distribution instead of asserting
it. After stating the verdict, append the line via the plugin's writer script (ships in
`bin/`, on PATH; it validates the shape and creates the log with its header if missing):

```bash
lcd-triage-log.sh triage --root <artifact-root> --desc "<slug-or-3–5-word-desc>" \
  --signals <n> --lane <Lane> --hard <yes|no> --risk <yes|no>
```

This single shared line is the **only** durable trace **Quick** lane leaves — it is *not* a
per-work-item artifact, so Quick's "no work-item folder" identity is unchanged. `/lcd:tidy`
summarizes the distribution. If the project isn't onboarded yet (no `lcd-conventions.md` /
artifact-root), skip the log — there's nowhere to put it.

**Closeout (the other half of the loop):** when a Standard/Deep work-item reaches its finish
line (audit PASS, or the JOURNAL NOW flips to done for surface-less work), read
`${CLAUDE_PLUGIN_ROOT}/skills/triage/references/closeout.md` at that moment and follow it —
one scripted action. Quick lane gets no closeout; its triage line is its whole trace.

---

## Execute the lane

Read `${CLAUDE_PLUGIN_ROOT}/skills/triage/references/lanes.md` **for the lane the verdict
picked** — it carries the Quick / Standard / Deep execution contracts (artifacts, TDD order,
audit, fan-out gate). It lives outside this skill so scoring never pays for the two lanes not
taken. Don't execute a lane from memory of it.

## Resuming, refining, re-routing

- A context reset mid-work-item → `/lcd:resume <slug>` rebuilds from MAP + the JOURNAL
  resume block + DECISIONS headers (target <~2k tokens).
- A STEP/task/MAP entry that proved wrong mid-flight → invoke `lcd:refine`; it corrects the
  artifact and logs the change without waiting to be asked.
- The **lane itself** proved wrong → read
  `${CLAUDE_PLUGIN_ROOT}/skills/triage/references/rerouting.md` and correct the lane (escalate
  or de-escalate) — don't restart, don't soldier on in the wrong one.

## Keep it light (the whole point)

The lanes exist so the large feature is organized and resumable — not so every task carries
ceremony. When in doubt, the lower lane.
