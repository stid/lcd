# Versioning

- The ecosystem manifest is the single source of truth for the version:
  Node/Bun/TS → `package.json`; Python → `pyproject.toml`; Rust → `Cargo.toml`; Go → git tag.
- If code reads its own version, import it from one dedicated module — never hardcode the string
  in multiple places.
- Branch-prefix bump convention: `feat/` → minor bump; `fix/` → patch bump. Major bumps need
  explicit approval. The bump happens in the **first commit** of the branch.

## Verify the current version before deciding a bump

Before concluding that a branch's first commit does or doesn't need a bump, **read the manifest's
version on the branch base** rather than assuming:

```bash
git show "$(git merge-base HEAD <default-branch>):<manifest>"   # e.g. :package.json
```

A resume or cold session can otherwise mistake a baseline `chore:` commit for a bump and skip a
required `feat/` minor bump. The red-green loop applies this check on the branch's first commit.
