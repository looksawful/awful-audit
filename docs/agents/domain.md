# Domain docs

How engineering skills should consume this repository's domain documentation.

Layout: **single-context**.

## Before exploring, read these when present

- `CONTEXT.md` at the repository root.
- Relevant architecture decisions under `docs/adr/`.
- If a future `CONTEXT-MAP.md` exists, follow it to the context relevant to the task.

If any of these files do not exist, proceed silently. Do not flag their absence and do not create empty domain files up front. `/domain-modeling` creates or extends them lazily when real terms or durable decisions are resolved.

## Consumer rules

- Use vocabulary defined by `CONTEXT.md` instead of inventing synonyms.
- If a needed concept is absent, reconsider the wording or record the gap for domain modeling.
- If a proposed change contradicts an ADR, surface the conflict explicitly instead of silently overriding it.
- Repository-local policy and agent instructions override generic domain guidance.
