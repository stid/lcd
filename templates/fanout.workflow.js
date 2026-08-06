// LCD Deep-lane parallel-surface fan-out (reference Workflow script).
//
// The OPT-IN path for triage's Deep lane when a feature has 2+ independent surfaces.
// Drives one worktree-isolated implementer per surface (boundary violations are structurally
// impossible), schema-validates each digest, then runs a cross-surface review.
//
// Run it with the Workflow tool, passing `args`:
//   { slug, testCmd, surfaces: [{ surface, boundary: [paths...], acs: ["AC-1 (CLI)", ...] }, ...] }
//
// Launch the workflow IN THE BACKGROUND and keep working: while the implementers run, the
// orchestrator preps reconciliation (merge order, full-suite command, the audit step) and watches
// the phase digests as they land — if an implementer's digest reports an out-of-boundary need or
// AC drift, intervene on that surface instead of waiting for the whole fan-out to finish. The
// `parallel` stage below already runs the implementers concurrently; the orchestrator's job during
// that window is monitoring and prep, not idling on the slowest surface.
//
// Reconciliation (merging the surface branches onto the baseline) and the full-suite + audit gate
// happen AFTER this returns — they need git/shell, which workflow scripts don't have. The returned
// `branchesToMerge` + `nextSteps` tell the orchestrator exactly what to do.

export const meta = {
  name: 'lcd-fanout',
  description: 'LCD Deep-lane parallel-surface fan-out: worktree-isolated implementers + review, schema-checked digests',
  phases: [
    { title: 'Implement', detail: 'one worktree-isolated implementer per surface' },
    { title: 'Review', detail: 'cross-surface consistency check' },
  ],
}

const { slug, surfaces, testCmd } = args

// Shared per-surface digest contract (see skills/triage/references/fanout.md "Per-surface implementer digest").
const DIGEST = {
  type: 'object',
  required: ['surface', 'filesChanged', 'acsCovered', 'notes', 'worktreeBranch'],
  additionalProperties: false,
  properties: {
    surface: { type: 'string' },
    filesChanged: { type: 'array', items: { type: 'string' } },
    acsCovered: { type: 'array', items: { type: 'string' } },
    notes: { type: 'array', items: { type: 'string' }, maxItems: 6 },
    worktreeBranch: { type: 'string' },
  },
}

const REVIEW = {
  type: 'object',
  required: ['consistent', 'findings'],
  additionalProperties: false,
  properties: {
    consistent: { type: 'boolean' },
    findings: { type: 'array', items: { type: 'string' } },
  },
}

phase('Implement')
const manifests = (await parallel(surfaces.map(s => () =>
  agent(
    `You implement ONLY the ${s.surface} surface of LCD work-item "${slug}".\n` +
    `EDIT BOUNDARY — touch only these files: ${s.boundary.join(', ')}.\n` +
    `Make ONLY these tests pass: ${s.acs.join(', ')}.\n` +
    `Reuse shared primitives — never reimplement core logic a none-surface AC owns.\n` +
    `Commit your boundary-scoped work on this worktree's branch, then report the digest: ` +
    `surface, filesChanged, acsCovered, notes (<=6 bullets), and worktreeBranch ` +
    `(the output of \`git rev-parse --abbrev-ref HEAD\`).`,
    { label: `impl:${s.surface}`, phase: 'Implement', isolation: 'worktree', schema: DIGEST }
  )
))).filter(Boolean)

phase('Review')
const review = await agent(
  `Review these parallel per-surface implementations of "${slug}" for cross-surface consistency ` +
  `(same input -> same result; shared contracts honored; no surface reimplemented shared logic). ` +
  `Manifests:\n${JSON.stringify(manifests, null, 2)}\nReport { consistent, findings }.`,
  { label: 'review', phase: 'Review', schema: REVIEW }
)

return {
  slug,
  manifests,
  branchesToMerge: manifests.map(m => m.worktreeBranch),
  review,
  // Orchestrator does this AFTER the workflow returns (git/shell, not available in-script):
  nextSteps: [
    'merge each branchesToMerge entry onto the baseline (disjoint boundaries -> clean; conflict = scoping error)',
    `run the FULL suite: ${testCmd}`,
    `/lcd:audit ${slug}`,
  ],
}
