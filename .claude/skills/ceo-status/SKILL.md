---
name: ceo-status
description: CEO status report across all ideas and product repos - what is waiting for the CEO, progress, blockers, risks.
disable-model-invocation: true
---

Produce the CEO status report. Use the `ceo-liaison` agent's status format.

1. Gather (read-only):
   - `gh pr list --search "org:Nithub-IT-Solutions is:open label:ceo-approval" --json number,title,url,createdAt,repository` — **waiting for CEO**
   - `gh search prs --owner Nithub-IT-Solutions --state open --json title,url,repository,updatedAt` — all open PRs
   - `gh search issues --owner Nithub-IT-Solutions --state open --label "status:blocked" --json title,url,repository`
   - `gh project item-list 7 --owner Nithub-IT-Solutions --format json` — board status per item
   - For each folder in `ideas/`: the `status:` line of `00-idea.md`
   - PRs merged in the last 7 days per repo.
2. Write `reports/status-<YYYY-MM-DD>.md` and print it.
3. Lead with "Waiting for you (N)" — oldest first, each with a one-line ask and link.
4. Do not commit the report unless the CEO asks.
