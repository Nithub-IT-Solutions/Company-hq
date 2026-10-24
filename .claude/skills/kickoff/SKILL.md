---
name: kickoff
description: After Gate 3 is merged - create the product repository from the product template, apply protection, labels and milestones, and create every planned issue on the project board.
argument-hint: "<idea-slug>"
disable-model-invocation: true
---

Kick off the build for `$ARGUMENTS`.

1. **Gate check:** `ideas/$ARGUMENTS/03-project-plan.md` must be on `origin/main`. If not, stop.
2. **Confirm with the CEO before creating anything**: show the repo name `product-$ARGUMENTS`, visibility (private),
   the number of issues and milestones you will create. Wait for "yes".
3. Create the repo: `gh repo create Nithub-IT-Solutions/product-$ARGUMENTS --private --description "<one line from PRD>"`.
4. In a temp folder: copy everything in `product-template/` (including hidden `.github` and `.claude` folders),
   replace the `PRODUCT_NAME` placeholder with the product name, copy `ideas/$ARGUMENTS/03-architecture.md`
   and `adr/` into `docs/`, write a README from the PRD. Initial commit `chore: initial scaffold from company template`
   and push to `main` — this single initial push is the only allowed direct push, and only into the brand-new empty repo.
   (If the deny rule blocks it, ask the CEO to run the push command themselves.)
5. Ask the CEO to run `bash scripts/protect-branch.sh Nithub-IT-Solutions/product-$ARGUMENTS` and `bash scripts/setup-labels.sh Nithub-IT-Solutions/product-$ARGUMENTS`
   (protection changes are CEO-only).
6. Create milestones for each sprint: `gh api repos/Nithub-IT-Solutions/product-$ARGUMENTS/milestones -f title="Sprint 1" -f due_on=<date>`.
7. Parse the `issues:` YAML block in `03-project-plan.md`; for each item `gh issue create` with title, body
   (acceptance criteria + link to PRD story), labels and milestone; add each to the "Company Pipeline" project
   with Status = Backlog (Sprint 1 items = Ready), Phase = Build.
8. Update `00-idea.md` (`status: BUILDING`, `repo: <url>`) via a small PR in company-hq; comment on the tracking issue.
9. Tell the CEO: "Open `product-$ARGUMENTS` in VS Code and run `/sprint` to start Sprint 1."
