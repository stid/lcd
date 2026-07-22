---
name: recon
description: Ground a LCD work-item in CURRENT best practice before deciding on an approach. Resolves up-to-date library/API/tooling guidance via Context7 and a targeted web search, in a subagent, and returns a few dated bullets. Use at the start of Standard/Deep work that touches a library, framework, SDK, API, or pattern whose current best practice you're not certain of — before writing the plan or choosing a dependency.
user-invocable: true
---

# LCD Recon

Answers "what is the current best way to do X?" *before* the architecture is committed — so the plan
isn't anchored to a stale training cutoff.

## When to run

- At the start of **Standard/Deep** work that involves a library/framework/SDK/API/CLI/cloud
  service, a new dependency choice, or a pattern you're not current on. **Skip for Quick** and skip
  when the work is plainly within well-known, stable territory (don't burn tokens confirming the
  obvious).

## How to run (lean-orchestrator rule)

Run recon **in a subagent** so the token-heavy doc/search dumps never enter the orchestrator's
window. The orchestrator receives only the digest and writes it to the work-item JOURNAL.

**Dispatch the plugin's `lcd-recon` agent** (`agents/lcd-recon.md`) — it is read-only with the
research tools and the method baked in (installed-version check → Context7 → targeted web
search), and its definition carries the digest contract: `{ findings: 3–6 dated bullets,
avoid: [...], recommendation: one line }`, ≤15 lines total. The dispatch prompt therefore only
needs the work-item context: slug, the library/API/pattern in question, and the installed
version if already known.

When recon is dispatched inside a `Workflow` (e.g. the Deep-lane orchestration), pass that
digest shape as the agent's `schema` so the contract is validated at the tool layer rather
than hoped for.

## What the orchestrator does with the result

- Append the bullets to the work-item JOURNAL **LOG** (dated).
- If a finding drives a real architecture/tooling **choice**, record it in `<root>/DECISIONS.md`
  (cite the recon finding as Context) and reference it from `plan.md`'s Architecture section.
- Proceed to plan/build with the current-practice grounding in hand.

## Keep it light

Recon is a check, not a research project. One subagent pass, a handful of dated bullets, a decision.
If the answer is "the approach you already had is still current," that's a valid one-line result —
record it and move on.
