#!/usr/bin/env bash
# Usage: bash scripts/protect-branch.sh <owner/repo> [required-check ...]
# Run as the CEO (repo admin). Protects main like a real company:
#  - changes only through PRs, 1 approval, code owners (CEO) must approve
#  - new pushes dismiss old approvals; last pusher can't approve their own push
#  - required CI checks, conversations resolved, linear history, no force-push/deletion
# Requires a public repo, or GitHub Pro/Team for private repos.
set -euo pipefail
REPO="${1:?usage: protect-branch.sh owner/repo [check-name ...]}"; shift || true
CHECKS=("$@"); [ ${#CHECKS[@]} -eq 0 ] && CHECKS=("gate-check")
contexts=$(printf '"%s",' "${CHECKS[@]}"); contexts="[${contexts%,}]"
gh api -X PUT "repos/$REPO/branches/main/protection" \
  -H "Accept: application/vnd.github+json" --input - <<JSON
{
  "required_status_checks": { "strict": true, "contexts": $contexts },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": true,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
# Squash-merge only, delete branches after merge, suggest updating PR branches
gh api -X PATCH "repos/$REPO" -F allow_squash_merge=true -F allow_merge_commit=false \
  -F allow_rebase_merge=false -F delete_branch_on_merge=true -F allow_update_branch=true >/dev/null
echo "main is protected on $REPO (required checks: ${CHECKS[*]})"
