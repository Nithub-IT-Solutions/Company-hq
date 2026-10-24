---
name: plan-build
description: Phase 3 - architecture, security, cloud cost, test strategy and the delivery plan for an approved PRD; opens the Gate 3 (Build plan approval) PR.
argument-hint: "<idea-slug>"
disable-model-invocation: true
---

Run **Phase 3 - Build Planning** for idea `$ARGUMENTS`. Act as the `phase-orchestrator`.

## 0. Gate check
`ideas/$ARGUMENTS/02-prd.md` and `02-mvp-scope.md` must be on `origin/main` (Gate 2 merged). Read them plus CEO comments on the Gate 2 PR.
Branch: `idea/$ARGUMENTS-plan`.

## 1. Architecture first (one agent, because everyone depends on it)
**Software Architect** + **Backend Architect** write `03-architecture.md` (from `templates/03-architecture.md`):
context diagram (Mermaid C4-style), components, data model, APIs, tech stack with reasons, hosting choice.
Every significant choice gets an ADR in `ideas/$ARGUMENTS/adr/NNNN-<title>.md` from `templates/adr.md`
(at minimum: language/framework, database, hosting/cloud, auth).
Prefer boring, well-supported technology and managed services. Optimize for a small team and low monthly cost.

## 2. Then in parallel
| Subagent | File | Content |
|---|---|---|
| Security Architect + Application Security Engineer | `03-threat-model.md` | STRIDE threat model, trust boundaries, auth/authz design, secrets handling, OWASP Top 10 controls, security checks in CI |
| DevOps Automator + SRE | `03-devops.md` | Environments (dev/staging/prod), CI/CD pipeline, IaC approach, monitoring, logging, alerts, backups, SLOs, rollback |
| FinOps Engineer | `03-cloud-cost.md` | Monthly cost at 0 / 100 / 1,000 / 10,000 users, free tiers used, cost alarms. Show the math and pricing page links |
| Test Automation Engineer + API Tester | `03-test-strategy.md` | Test pyramid, tools, coverage targets, E2E critical paths, what runs on every PR vs nightly |
| Senior Project Manager + Project Shepherd | `03-project-plan.md` | Epics → issues (each with acceptance criteria and estimate S/M/L), milestones per sprint (2 weeks), dependencies, critical path, risks register |

The project plan must list issues in this exact machine-readable block so `/kickoff` can create them:
```yaml
issues:
  - title: "feat: <title>"
    epic: "<epic>"
    milestone: "Sprint 1"
    size: M
    labels: [type:feature, area:backend]
    acceptance: |
      - Given … When … Then …
```

## 3. Check and summarize
Reality Checker reviews all files together (does the plan cover every Must story? any unowned risk? is cost realistic?).
`ceo-liaison` writes the CEO Summary on top of `03-project-plan.md`: stack in one line, timeline, monthly cost, top risks, decisions needed (e.g. "approve AWS account with $50/month budget alarm").

## 4. Gate 3 PR
Title `Gate 3 - Build plan approval: $ARGUMENTS`, labels `gate:3-plan,ceo-approval`, reviewer CEO.
Project Status = CEO Approval, Phase = Planning. STOP. Tell the CEO: "After merge, run `/kickoff $ARGUMENTS`."
