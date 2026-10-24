---
name: sprint
description: Run sprint work in this product repo - take Ready issues, build each on its own branch with tests in parallel, open PRs, and get them reviewed by the Code Reviewer agent.
argument-hint: "[issue numbers, or blank for all Ready issues in the current sprint]"
disable-model-invocation: true
---

Run sprint work. Issues: `$ARGUMENTS` (if blank: all open issues in the earliest open milestone whose project Status is Ready).

1. `git switch main && git pull`. List the issues with `gh issue list --milestone "<sprint>" --state open --json number,title,labels,body`.
   Skip issues already assigned or with an open PR. Pick at most 4 at a time.
2. Order by dependencies. Independent issues run **in parallel**, each in its own git worktree, by the right specialist:
   - `area:frontend` → Frontend Developer (Mobile App Builder for mobile)
   - `area:backend` → Backend Architect (Database Optimizer for schema/query work)
   - `area:infra` → DevOps Automator
   - `type:security` → Application Security Engineer
   Each specialist: branch `feature/<n>-<desc>`, implements to the acceptance criteria, adds tests
   (Test Automation Engineer / API Tester help on test-heavy issues), runs lint + tests until green.
3. For each finished branch: push, open a PR (template, `Closes #<n>`, labels copied from the issue),
   add to the project with Status = In Review, comment on the issue.
4. **Code Reviewer** agent reviews each PR diff (`gh pr diff`) for correctness, security, tests, readability;
   posts findings as a PR comment with Blocking / Non-blocking lists. The author agent fixes blocking items and pushes.
5. When a PR's CI is green and Code Reviewer has no blocking items, add the label `ceo-approval` and request the CEO's review.
6. Report: table of issue → PR → CI status → review status, plus anything blocked (label `status:blocked` with reason).
