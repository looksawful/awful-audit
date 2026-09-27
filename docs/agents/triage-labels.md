# Triage labels

The engineering skills use five canonical triage roles. This file maps those roles to the actual GitHub label strings used in this repository.

| Canonical role | GitHub label | Meaning |
| --- | --- | --- |
| `needs-triage` | `needs-triage` | Maintainer needs to evaluate the item |
| `needs-info` | `needs-info` | Waiting on reporter for more information |
| `ready-for-agent` | `ready-for-agent` | Fully specified and ready for an agent |
| `ready-for-human` | `ready-for-human` | Requires human implementation or judgment |
| `wontfix` | `wontfix` | Will not be actioned |

When a skill names a canonical role, use the corresponding label string from this table.

This file is a mapping only. SetupMatt does not create repository labels. If a configured label is missing, surface the setup defect instead of silently substituting another label.
