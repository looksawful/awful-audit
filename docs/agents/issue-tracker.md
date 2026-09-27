# Issue tracker: GitHub

GitHub Issues are the engineering work tracker for `looksawful/awful-audit`.

## Harness and tool choice

The tracker is the source of truth, not a particular client.

- GPT/OpenClo should use an authenticated GitHub connector/API when available.
- An authenticated `gh` CLI inside the repository clone is an equivalent operation surface.
- Do not create a parallel local-markdown tracker merely because one operation surface is unavailable.

## Conventions

Use GitHub Issues to create, read, list, comment on, label, assign and close work items. When reading an issue, include its body, comments and current labels.

A bare `#<number>` may refer to either an issue or a pull request. Resolve the entity type before mutating it.

## Pull requests as a triage surface

PRs as a request surface: no.

External pull requests are not part of the normal `/triage` queue unless this flag is deliberately changed. Explicitly named PRs may still be reviewed or triaged when requested.

## Skill operations

- **Publish to the issue tracker:** create a GitHub issue.
- **Fetch the relevant ticket:** read the issue including comments and labels.
- **Apply/remove a triage role:** use `docs/agents/triage-labels.md`.

## Wayfinding operations

- **Map:** one issue labelled `wayfinder:map`, holding Notes / Decisions-so-far / Fog.
- **Child ticket:** use a GitHub sub-issue when available; otherwise link it from the map task list and put `Part of #<map>` at the top of the child.
- **Type labels:** `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task`.
- **Blocking:** prefer native GitHub issue dependencies; otherwise use a leading `Blocked by: #<n>, #<n>` line.
- **Frontier:** first open child in map order with no open blocker and no assignee.
- **Claim:** assign the ticket to the current operator; claiming is the session's first write.
- **Resolve:** post the durable answer/evidence, close the child, then record the resulting decision/context pointer on the map.
