---
name: new-idea
description: Register a new business idea from the CEO - creates the idea folder, the tracking issue, and adds it to the Company Pipeline board.
argument-hint: "<describe the business idea in plain words>"
disable-model-invocation: true
---

The CEO submitted this business idea:

$ARGUMENTS

Do the following, in order:

1. Make a short kebab-case slug (2-4 words) for the idea. Check `ideas/` so it is unique.
2. `git switch main && git pull`, then `git switch -c idea/<slug>-intake`.
3. Create `ideas/<slug>/00-idea.md` from `templates/00-idea.md`. Fill in the CEO's words verbatim under
   "Original idea", then fill the remaining fields with your best reading, marking guesses `[ASSUMPTION]`.
   Set `status: INTAKE`.
4. Create the tracking issue:
   `gh issue create --title "Idea: <short name>" --label "phase:intake,type:idea" --body-file ideas/<slug>/00-idea.md`
   Record the issue number in `00-idea.md` (`tracking_issue: #N`).
5. Commit (`docs: register idea <slug> (#N)`), push the branch, and open a PR titled
   `Idea intake: <short name>` that closes nothing (use `Refs #N`). Labels: `phase:intake`.
   Request review from the CEO. This PR is a light check that the idea was understood; it is not a gate.
6. Add the issue and the PR to the "Company Pipeline" project:
   `gh project item-add <PROJECT_NUMBER> --owner Nithub-IT-Solutions --url <issue url>` (and the same for the PR).
7. Reply to the CEO with: the slug, issue link, PR link, the 3 clarifying questions that would most change
   the research (if any), and: "When the intake PR is merged, run `/discovery <slug>`."
