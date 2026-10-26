# Company HQ — Operating Rules for All Agents

This repository is the headquarters of an AI-staffed product company.
The **CEO** is the only human. Every agent (subagents from agency-agents and the
company agents in `.claude/agents/`) follows these rules. They are not optional.

- CEO GitHub handle: `@nisarmohammadTPM`
- GitHub organization: `Nithub-IT-Solutions`
- Bot account that agents act as: `nithubceoai`
- Project board: "Company Pipeline" (org-level GitHub Project)

## 1. The pipeline and the gates

Every idea moves through these phases. **Never start a phase whose gate is not approved.**

| Phase | Skill | Output (in `ideas/<slug>/`) | Gate | Gate label |
|---|---|---|---|---|
| 0 Intake | `/new-idea` | `00-idea.md` + GitHub issue | — | `phase:intake` |
| 1 Discovery & validation | `/discovery` | `research/*.md`, `01-idea-brief.md` | **Gate 1 — Idea approval** | `gate:1-idea` |
| 2 Product definition | `/define-product` | `02-prd.md`, `02-mvp-scope.md`, `02-ux.md` | **Gate 2 — Scope approval** | `gate:2-scope` |
| 3 Build planning | `/plan-build` | `03-architecture.md`, `adr/*.md`, `03-threat-model.md`, `03-cloud-cost.md`, `03-test-strategy.md`, `03-project-plan.md` | **Gate 3 — Build plan approval** | `gate:3-plan` |
| 4 Kickoff | `/kickoff` | new product repo + issues + milestones | — | `phase:build` |
| 5 Sprints | `/sprint` | feature PRs in the product repo | PR review (code owners) | `phase:build` |
| 6 Release | `/release` | release PR, tag, GitHub Release | **Release gate** | `gate:release` |

### What "approved" means
A gate is approved **only** when the CEO has merged the gate PR into `main`.
Check with: `git fetch origin && git ls-tree -r origin/main --name-only | grep ideas/<slug>/01-idea-brief.md`
(swap the file name for the gate you are checking). A file on a branch or in an open PR is **not** approved.

- CEO "Request changes" on a gate PR → run `/revise <PR number>`; do not start the next phase.
- CEO closes the gate PR without merging → the idea is **rejected/parked**. Set `status: REJECTED` in `00-idea.md` via a small PR and stop.

## 2. Git and GitHub rules (same as a real engineering org)

- **Never commit or push to `main`.** All work happens on a branch and lands through a pull request.
- **Never merge a PR.** Only the CEO merges (gate PRs) or a human-approved PR is merged by the CEO. Agents may *open*, *update*, and *comment on* PRs.
- **Never force-push** to a branch someone else has reviewed. Never rewrite `main`.
- Branch names:
  - `idea/<slug>-discovery`, `idea/<slug>-prd`, `idea/<slug>-plan` (company-hq)
  - `feature/<issue#>-<short-desc>`, `fix/<issue#>-<short-desc>`, `chore/<short-desc>`, `release/v<x.y.z>` (product repos)
- Commits use **Conventional Commits**: `feat: …`, `fix: …`, `docs: …`, `test: …`, `chore: …`, `refactor: …`, `ci: …`. Subject ≤ 72 chars, imperative mood. Reference the issue: `feat: add signup form (#12)`.
- One PR = one issue/purpose. Aim for < 400 changed lines; split bigger work.
- Every PR uses `.github/pull_request_template.md`, links its issue (`Closes #N`), has the right labels, and is added to the "Company Pipeline" project.
- Gate PRs: add the gate label + `ceo-approval`, request review from `@nithubceoai`, and set the project Status to **CEO Approval**.

## 3. How agents work

- Run independent work **in parallel** with subagents (e.g. all Discovery research at once). Each subagent writes its own file; the coordinator merges results.
- Use the agency-agents specialists by their names (e.g. "Trend Researcher", "Software Architect"). Company agents: `phase-orchestrator`, `ceo-liaison`, `release-manager`.
- Use the templates in `templates/`. Keep every section; write "N/A — reason" rather than deleting one.
- **Evidence over opinion.** Market claims need a source link or are marked `[ASSUMPTION]`. Numbers show how they were calculated.
- The **Reality Checker** reviews every gate document before the CEO sees it. Its verdict goes in the document.
- The CEO reads one page. Every gate document starts with a **CEO Summary** (≤ 1 page) written by `ceo-liaison`: recommendation, why, cost, risk, the decision needed.
- When blocked or uncertain about something only the CEO can decide (money, legal, brand, scope), stop and add it to "Decisions needed from CEO" in the gate PR. Do not guess.

## 4. Never do

- Never commit secrets, API keys, tokens, `.env` files, or customer data. Use GitHub Secrets.
- Never spend money, create paid cloud resources, buy domains, or sign up for services. Put it in the plan for CEO approval.
- Never delete repositories, branches with open PRs, issues, or project items.
- Never change branch protection, CODEOWNERS, or `.github/workflows` without a PR labelled `ceo-approval`.
- Never mark your own work as approved.

## 5. Definition of Done (product repos)

A feature is done when: code + tests on a branch → CI green → Code Reviewer agent approved with no open blocking comments → CEO/code owner approved → merged by the CEO → issue closed automatically → project item moved to Done.
