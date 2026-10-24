---
name: discovery
description: Phase 1 - research a registered idea from every angle in parallel and open the Gate 1 (Idea approval) PR for the CEO.
argument-hint: "<idea-slug>"
disable-model-invocation: true
---

Run **Phase 1 - Discovery & Validation** for idea `$ARGUMENTS`. Act as the `phase-orchestrator`.

## 0. Preconditions
- `git fetch origin`. `ideas/$ARGUMENTS/00-idea.md` must exist on `origin/main` (intake PR merged). If not, stop and say so.
- Branch: `git switch main && git pull && git switch -c idea/$ARGUMENTS-discovery`.

## 1. Parallel research (launch ALL of these subagents at the same time)
Every agent reads `ideas/$ARGUMENTS/00-idea.md` first, uses web search, cites links, marks guesses `[ASSUMPTION]`,
and writes ONLY its own file under `ideas/$ARGUMENTS/research/`:

| Subagent | File | Must answer |
|---|---|---|
| Trend Researcher | `market.md` | Market size (TAM/SAM/SOM with math), growth, trends, timing — why now? |
| Business Strategist | `competitors.md` | Top 5-10 competitors/alternatives, pricing, strengths/weaknesses, our wedge, moat |
| UX Researcher | `customers.md` | Target segments, personas, jobs-to-be-done, top pains, where they are found, interview script for 5 real interviews |
| Feedback Synthesizer | `voice-of-customer.md` | What real users say today (reviews, Reddit, forums, app stores) about the problem and competitors — with quotes and links |
| Pricing Analyst | `pricing.md` | Pricing model options, willingness-to-pay evidence, recommended price points |
| Financial Analyst | `financials.md` | Unit economics (CAC, LTV, gross margin), build + run cost estimate, 12-24 month revenue scenarios (low/base/high), break-even |
| Growth Hacker | `go-to-market.md` | First 100 customers plan, channels ranked by cost/speed, launch experiments |
| Legal Compliance Checker | `legal.md` | Regulations, licences, data/privacy duties (GDPR/CCPA/HIPAA etc.), IP risks, red flags — note "not legal advice; confirm with a lawyer" |
| Software Architect | `feasibility.md` | Can we build an MVP? Rough approach, hard technical risks, third-party dependencies, rough effort (weeks) |

## 2. Synthesis
- Write `ideas/$ARGUMENTS/01-idea-brief.md` from `templates/01-idea-brief.md`, integrating all research.
  Include an **enhanced version of the idea**: what we changed vs. the original and why (sharper segment, better pricing, a different wedge).
- Scoring: fill the scorecard (market, pain, ability to win, economics, feasibility, risk) with evidence.
- Reality Checker reviews the brief → paste verdict into "Reality Check".
- `ceo-liaison` writes the CEO Summary at the top. Recommendation is GO / GO WITH CHANGES / NO-GO.

## 3. Gate 1 PR
- Commit (`docs: discovery and idea brief for $ARGUMENTS (#<tracking issue>)`), push.
- `gh pr create --title "Gate 1 - Idea approval: $ARGUMENTS" --label "gate:1-idea,ceo-approval" --reviewer CEO_GITHUB_USERNAME --body "<CEO Summary + links to every research file + Refs #<issue>>"`
- Add the PR to the project; set Status = **CEO Approval**, Phase = Discovery.
- Comment on the tracking issue with the PR link.
- STOP. Tell the CEO: "Approve = merge the PR. Request changes = I will run /revise. Close = idea parked."
