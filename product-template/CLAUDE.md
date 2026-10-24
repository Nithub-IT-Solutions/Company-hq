# PRODUCT_NAME — Engineering Rules for All Agents

Product repo of Nithub-IT-Solutions. Company rules in `Nithub-IT-Solutions/Company-hq/CLAUDE.md` apply here too.
Specs: `docs/` (architecture, ADRs) and the PRD in Company-hq `ideas/<slug>/02-prd.md`.

## Workflow (GitHub Flow)
1. Pick an issue from the "Company Pipeline" board with Status = Ready (current sprint milestone).
2. Branch from latest main: `feature/<issue#>-<desc>` or `fix/<issue#>-<desc>`.
3. Write the test first when practical, then the code. Keep PRs < 400 changed lines.
4. Run lint + tests locally before pushing. CI must be green.
5. Open a PR: template filled, `Closes #<issue>`, labels, project Status = In Review.
6. The **Code Reviewer** agent reviews (plus automatic Claude review in CI). Fix every blocking comment.
7. The CEO (code owner) approves and merges (squash). Agents never merge.

## Code standards
- Conventional Commits. Small, focused commits.
- Follow the stack choices in `docs/adr/`. New dependency or pattern = new ADR in the PR.
- Every feature has tests; every bug fix has a regression test.
- No secrets in code. Config via environment variables; document them in `.env.example`.
- Handle errors explicitly; log with context; never log secrets or personal data.
- Accessibility: WCAG 2.1 AA for all UI.
- Update README/docs when behavior or setup changes.

## Never
Push to main · merge PRs · force-push reviewed branches · disable or skip tests/CI · commit secrets ·
create paid cloud resources · change `.github/` or CODEOWNERS without a `ceo-approval` PR.
