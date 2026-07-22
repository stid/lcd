# No Feature Downgrade Without Approval

Never reduce the capability of an existing feature without explicit approval — even as a side
effect of another change, and even if the simpler version seems better.

Downgrades that require sign-off:
- Replacing a richer implementation with a simpler one.
- Removing parameters, options, or configuration callers rely on.
- Returning a partial/stub where a full result existed.
- Reducing output detail (dropped fields/columns) or replacing a specific error with a generic one.

When you notice your next edit would downgrade something: stop, name what would be lost, ask, and
proceed only on an explicit yes.
