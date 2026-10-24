---
name: release
description: Prepare a release PR for CEO approval, or - if the release PR is already merged - tag and publish the GitHub Release.
argument-hint: "[version, e.g. 1.2.0 - optional]"
disable-model-invocation: true
---

Use the `release-manager` agent. Requested version: `$ARGUMENTS` (blank = decide from Conventional Commits).

- If no open or merged `release: v…` PR exists for this version → run **Prepare**.
- If the release PR is merged → run **Publish**.
- If it is open → report its status and what is blocking it.

Before preparing, have **Reality Checker** review: CI on main, open high/critical bugs, test coverage, and the
test strategy's release gates. Its verdict goes into the release PR body. Also run **Evidence Collector** on the
critical user paths if the app has a UI.
