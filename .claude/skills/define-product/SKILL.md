---
name: define-product
description: Phase 2 - turn an approved idea into a PRD, MVP scope and UX flows, and open the Gate 2 (Scope approval) PR.
argument-hint: "<idea-slug>"
disable-model-invocation: true
---

Run **Phase 2 - Product Definition** for idea `$ARGUMENTS`. Act as the `phase-orchestrator`.

## 0. Gate check
`git fetch origin`. `ideas/$ARGUMENTS/01-idea-brief.md` must be on `origin/main` (Gate 1 merged). If not, stop.
Read the merged brief AND every CEO comment on the Gate 1 PR (`gh pr list --state merged --search "Gate 1 - Idea approval: $ARGUMENTS"` then `gh pr view <n> --comments`). CEO comments are requirements.
Branch: `idea/$ARGUMENTS-prd`.

## 1. Parallel work
| Subagent | File | Content |
|---|---|---|
| Product Manager | `02-prd.md` (from `templates/02-prd.md`) | Problem, goals & success metrics, personas, user stories with acceptance criteria (Given/When/Then), non-goals |
| Sprint Prioritizer | `02-mvp-scope.md` | MoSCoW list; MVP = Must only; RICE scores; what is explicitly OUT of v1; release slices (MVP, v1.1, v2) |
| UX Architect | `02-ux.md` | Information architecture, main user flows as Mermaid diagrams, screen list, navigation |
| UI Designer | `02-ui.md` | Visual direction, design tokens (colors, type, spacing), key screen wireframes (Mermaid or ASCII), component list, accessibility notes |

Product Manager goes first for 1 pass on goals/personas if the others need them; then run the rest in parallel.

## 2. Check and summarize
- Reality Checker: is the MVP small enough to ship in ≤ 8 weeks with our agents? Are acceptance criteria testable?
- `ceo-liaison` adds the CEO Summary to the top of `02-prd.md` including MVP size, timeline guess, and what was cut.

## 3. Gate 2 PR
Title `Gate 2 - Scope approval: $ARGUMENTS`, labels `gate:2-scope,ceo-approval`, reviewer CEO, Refs the tracking issue.
Project Status = CEO Approval, Phase = Product. STOP and tell the CEO what approving starts (build planning).
