---
name: revise
description: Address the CEO's review comments (or "Request changes") on a pull request, push fixes to the same branch, and reply to each comment.
argument-hint: "<PR number>"
disable-model-invocation: true
---

Revise pull request #$ARGUMENTS based on review feedback.

1. `gh pr view $ARGUMENTS --comments` and `gh api repos/{owner}/{repo}/pulls/$ARGUMENTS/comments` to collect every review and inline comment.
2. `gh pr checkout $ARGUMENTS`. Make a numbered list of every requested change. CEO comments are requirements, not suggestions.
3. Route each change to the specialist who owns that file (same agents that wrote it). Run independent fixes in parallel.
4. If a change affects other sections (e.g. new price → financials), update those too and say so.
5. Re-run the Reality Checker on the changed parts; update the CEO Summary.
6. Commit (`docs: address CEO review on #$ARGUMENTS` or `fix: …` for code), push to the same branch (no force-push).
7. Reply to each review comment saying what changed (`gh pr comment`), then re-request review from the CEO:
   `gh pr edit $ARGUMENTS --add-reviewer nisarmohammadTPM`.
8. Report a short "what changed" list.
