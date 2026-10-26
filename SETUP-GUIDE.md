# Company HQ — Setup Guide (Windows + VS Code + Claude Code + GitHub)


Follow the parts in order. Total time is about 60-90 minutes, done once.
Commands marked **PowerShell** run in Windows PowerShell. Commands marked **Git Bash** run in Git Bash (installed with Git).

**Who's who**
| Role | GitHub account | Does what |
|---|---|---|
| CEO (you) | your normal account, **Owner** of `Nithub-IT-Solutions` | submits ideas, reviews and **approves and merges** gate PRs and code PRs |
| Agents | a second account, e.g. `nithubceoai`, **Member with Write** | commits, pushes branches, opens PRs, comments. Can never merge to `main` |
| Claude GitHub App | `claude[bot]` | automatic PR reviews, answers `@claude` comments |

> **Why a bot account?** GitHub never lets the author of a PR approve their own PR. If the agents used *your* login, every PR would be "yours" and you could not approve it. Real companies use a service account for automation for the same reason.

---

## Part A — Install the tools on your PC (15 min)

1. **VS Code**: install from https://code.visualstudio.com.
2. **Git for Windows**: install from https://git-scm.com/download/win. Keep the defaults. This also gives you **Git Bash**, which Claude Code uses as its shell.
3. **GitHub CLI**: install from https://cli.github.com. Then in PowerShell:
   ```powershell
   gh auth login        # GitHub.com → HTTPS → Login with a web browser → sign in as YOU (the CEO)
   gh auth setup-git    # lets git use gh for passwords
   ```
4. **Claude Code**: in PowerShell:
   ```powershell
   irm https://claude.ai/install.ps1 | iex
   claude --version
   ```
   Close and reopen PowerShell if `claude` is not found. Then run `claude` once and sign in with your Claude account (Pro, Max, Team or Enterprise).
5. **VS Code extension**: in VS Code, open Extensions (Ctrl+Shift+X), search **Claude Code** (publisher Anthropic), and install it. A Claude icon appears in the sidebar.
6. Tell git who you are (PowerShell):
   ```powershell
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   ```
7. **Python 3.12** is used by the product-template CI and is needed for local Python product work. After cloning the repository in Part C, run `.\scripts\setup-windows.ps1` from PowerShell to install/check Python and verify the local tools.

---

## Part B — Create the bot account (10 min)

1. Sign out of GitHub in a private browser window and **sign up** for a new account, e.g. `nithubceoai`.
   Gmail tip: `yourname+bot@gmail.com` delivers to your normal inbox and counts as a separate email for GitHub.
2. As the CEO: go to **github.com/orgs/Nithub-IT-Solutions/people → Invite member** → `nithubceoai` → role **Member**. Accept the invite in the bot's browser window.
3. As the CEO: give members Write access to every repo, now and future:
   **Org Settings → Member privileges → Base permissions → Write**.
   (Alternative: add `nithubceoai` as a **Write** collaborator on each repo.)
4. As the bot: go to **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**:
   - Resource owner: **Nithub-IT-Solutions** (if it isn't listed, the org owner must allow fine-grained tokens: Org Settings → Personal access tokens → Allow)
   - Repository access: **All repositories**
   - Permissions: **Contents** Read and write · **Pull requests** Read and write · **Issues** Read and write · **Metadata** Read · **Workflows** Read and write
   - Organization permissions: **Projects** Read and write
   - Expiration: 90 days (set a reminder to renew)
   - Copy the token (starts with `github_pat_`). **Don't paste it anywhere except Part H.**
5. As the bot: go to **Settings → Emails** and copy the `…@users.noreply.github.com` address (used for commits).

---

## Part C — Put this kit into your Company-hq repo (5 min)

**Git Bash:**
```bash
cd ~
git clone https://github.com/Nithub-IT-Solutions/Company-hq.git
cd Company-hq
# Unzip the kit somewhere, e.g. ~/Downloads/company-hq-kit, then copy everything INCLUDING hidden folders:
cp -r ~/Downloads/company-hq-kit/company-hq/. .
git status          # you should see CLAUDE.md, .claude/, .github/, templates/, scripts/, product-template/ ...
```
Replace the placeholders. You need the project number from Part E, so create the project first, or use `1` and fix it later:
```bash
bash scripts/personalize.sh <YOUR_GITHUB_USERNAME> nithubceoai <PROJECT_NUMBER>
git diff --stat
git add -A
git commit -m "chore: company HQ operating system (agents, skills, templates, workflows)"
git push origin main     # allowed now: protection is not switched on yet
```

---

## Part D — Protect the repo like a real company (10 min)

> **Plan check:** branch protection on **private** repos needs a paid org plan (**GitHub Team**). On the Free plan it only works on **public** repos. Upgrade at **Org Settings → Billing and plans** if Company-hq is private. The bot is a member, so it counts as a seat.

**Git Bash** (inside Company-hq, signed in to gh as the CEO):
```bash
bash scripts/setup-labels.sh Nithub-IT-Solutions/Company-hq
bash scripts/protect-branch.sh Nithub-IT-Solutions/Company-hq gate-check
```
What this turns on for `main`: PR required · 1 approval · **Code Owner (you) must approve** · new pushes dismiss old approvals · the last pusher can't self-approve · `gate-check` CI must pass · all conversations resolved · linear history · no force-push or deletion · squash merge only · branches auto-deleted after merge.

Check it: **Repo → Settings → Branches** shows a rule on `main`. **Settings → Code security**: turn on **Dependabot alerts** and **Secret scanning** (where your plan offers them).

**How CODEOWNERS works:** `.github/CODEOWNERS` names you as the owner of everything. With "Require review from Code Owners" on, no PR can merge until **you** approve it. That approval is your CEO sign-off on every gate.

---

## Part E — Create the CEO dashboard (GitHub Project) (15 min)

1. **github.com/orgs/Nithub-IT-Solutions/projects → New project → Board** → name it **Company Pipeline**.
   The number in the URL (`…/projects/1`) is your `PROJECT_NUMBER`.
2. Run the setup script as an organization owner. In **Git Bash**:
   ```bash
   bash scripts/setup-project.sh Nithub-IT-Solutions 1 nithubceoai Company-hq
   ```
   Or in **PowerShell**:
   ```powershell
   & "C:\Program Files\Git\bin\bash.exe" scripts/setup-project.sh Nithub-IT-Solutions 1 nithubceoai Company-hq
   ```
   Replace `1` with the number from your project URL and `nithubceoai` with your bot account's username if different. The script creates missing custom fields, links the Company-hq repository, and grants the bot write access. The `project` token scope is required.
3. **Status column**: click the **⋯** on the Status field → Edit options so they are, in this order:
   `Backlog` · `Ready` · `In Progress` · `In Review` · `CEO Approval` · `Done` · `Rejected`
4. **Add the Sprint field** (top-right **⋯ → Settings → + New field**; the CLI does not support iteration fields):
   - **Sprint** — Iteration — 2 weeks
5. **Views** (tabs at the top, **+ New view**):
   - **Pipeline** (Board): group by Status. Your main screen.
   - **CEO Approval** (Table): filter `label:ceo-approval is:open`, sort by created date, oldest first. **Your inbox.**
   - **By Idea** (Board): group by Phase, filter `label:type:idea`.
   - **Sprint** (Board): filter `iteration:@current`, group by Status.
   - **Roadmap** (Roadmap layout): by Sprint.
6. **Automations** (**⋯ → Workflows**): enable
   - *Item added to project* → Status **Backlog**
   - *Item closed* → **Done**
   - *Pull request merged* → **Done**
   - *Auto-add to project* → repository **Company-hq**, filter `is:issue,pr is:open` (add one rule per product repo later)
7. **Project settings → Manage access**: verify your bot account has **Write** access.
8. If you used a placeholder project number in Part C, run `bash scripts/personalize.sh` again or edit the files, then commit through a PR.

---

## Part F — Install the agent employees (5 min)

**Git Bash** (inside Company-hq):
```bash
bash scripts/install-agents.sh
```
This clones `msitarzewski/agency-agents` to `~/agency-agents` and installs the curated roster in `setup/agency-roster.txt` (37 specialists) into `~/.claude/agents`.
Check it: open Claude Code and type `/agents`. You should see Trend Researcher, Product Manager, Software Architect, Code Reviewer, Reality Checker, and the rest, plus the company agents `phase-orchestrator`, `ceo-liaison` and `release-manager` (these come from this repo's `.claude/agents/`).

To add more specialists later, add a line to `setup/agency-roster.txt` (the file name without `.md`) and re-run the script.

---

## Part G — Connect Claude to GitHub for automatic PR reviews (10 min)

1. Install the **Claude GitHub App** on the org: https://github.com/apps/claude → **Install** → **Nithub-IT-Solutions** → **All repositories**.
2. Create a token from your Claude subscription. In **PowerShell**:
   ```powershell
   claude setup-token
   ```
   Copy the token it prints.
3. Save it as an **organization secret** so every product repo gets it. In **Git Bash**:
   ```bash
   gh secret set CLAUDE_CODE_OAUTH_TOKEN --org Nithub-IT-Solutions --visibility all
   # paste the token when asked
   ```
   (Using an API key instead? Name the secret `ANTHROPIC_API_KEY` and change `claude_code_oauth_token:` to `anthropic_api_key:` in both workflow files.)
4. The workflows are already in `.github/workflows/`:
   - `claude-code-review.yml` reviews every PR automatically with inline comments.
   - `claude.yml` answers when anyone writes `@claude …` in an issue or PR comment.
   - `gate-check.yml` blocks gate documents with missing sections or obvious secrets.

   (`/install-github-app` inside Claude Code does steps 1-4 for a single repo. Use it if you prefer, but choose **not** to overwrite these workflow files.)

---

## Part H — Make agents work as the bot (5 min)

In VS Code, open the `Company-hq` folder, copy `.claude/settings.local.json.example` to `.claude/settings.local.json`, and fill in:
- `GH_TOKEN` → the bot's fine-grained token from Part B
- `BOT_GITHUB_USERNAME` → `nithubceoai`
- `BOT_NOREPLY_EMAIL` → the bot's noreply email

`settings.local.json` is in `.gitignore`, so it is never committed. Claude Code now runs `git` and `gh` as the bot. Your own terminal stays signed in as you.
Do the same in each product repo after `/kickoff`.

Check it: in Claude Code, ask "run `gh api user --jq .login`". It must print `nithubceoai`.

---

## Part I — Daily operation (how you run the company)

Open **VS Code → File → Open Folder → Company-hq**, then click the **Claude** icon (or run `claude` in the VS Code terminal).

| You want to… | You do | What happens |
|---|---|---|
| Submit an idea | `/new-idea A marketplace where…` | idea folder, tracking issue, intake PR; card on board |
| Validate it | merge intake PR → `/discovery <slug>` | 9 specialists research in parallel → **Gate 1 PR** in your CEO Approval view |
| Approve / reject | review the PR on GitHub: **Approve + Squash and merge**, **Request changes**, or **Close** | merge = approved; changes → run `/revise <PR#>`; close = parked |
| Define the product | `/define-product <slug>` | PRD, MVP scope, UX, UI → **Gate 2 PR** |
| Plan the build | `/plan-build <slug>` | architecture + ADRs, threat model, DevOps, cloud cost, test strategy, issue plan → **Gate 3 PR** |
| Start building | `/kickoff <slug>` | creates `product-<slug>` repo from `product-template/`, milestones, issues on the board |
| Run a sprint | open the product repo in VS Code → `/sprint` | parallel feature branches → PRs → Claude CI review + Code Reviewer agent → `ceo-approval` |
| Approve code | review each PR → Approve → Squash and merge | issue closes, card moves to Done |
| Ship | `/release` → merge the release PR → `/release` again | changelog, tag, GitHub Release |
| Get a report | `/ceo-status` | "Waiting for you", progress, blockers |
| Ask for anything on GitHub | comment `@claude …` on an issue or PR | Claude replies or pushes fixes |

**Your rule as CEO:** you never write the documents or code. You read the CEO Summary, approve, or comment. Comments are requirements for the agents.

---

## Part J — Dry run (do this before a real idea)

1. `/new-idea A simple app that reminds small-business owners to send invoices on time` → merge the intake PR.
2. `/discovery invoice-reminder` → open the Gate 1 PR, leave one inline comment ("lower the price"), click **Request changes**.
3. `/revise <PR#>` → check that the agents addressed your comment → **Approve** → **Squash and merge**.
4. Confirm the board shows the card in Done and the idea folder is on `main`.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `claude` not found | reopen PowerShell; or `winget install Anthropic.ClaudeCode` |
| Claude Code uses PowerShell, not Bash | install Git for Windows; or set `CLAUDE_CODE_GIT_BASH_PATH` to `C:\Program Files\Git\bin\bash.exe` in settings `env` |
| You can't approve a PR ("authors can't approve") | the PR was opened by you, not the bot. Check Part H (`gh api user` must say nithubceoai) |
| Merge button disabled | waiting for your approval, CI (`gate-check`), or unresolved conversations |
| Claude review didn't run | secret missing (Part G.3), app not installed on the repo, or the PR is a draft |
| Branch protection API returns 403 / "Upgrade" | private repo on the Free plan (see Part D) |
| `gh project` errors on scopes | as yourself: `gh auth refresh -s project`; for the bot, check the token's Projects permission |
| Agents tried to push to main | blocked by `.claude/settings.json` deny rules and by branch protection. That's working as intended |
