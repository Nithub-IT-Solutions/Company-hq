#!/usr/bin/env bash
# Usage: bash scripts/personalize.sh <CEO_GITHUB_USERNAME> <BOT_GITHUB_USERNAME> <PROJECT_NUMBER>
# Replaces placeholders in every text file of this repo. Run once, review `git diff`, commit via PR.
set -euo pipefail
CEO="${1:?CEO GitHub username}"; BOT="${2:?bot GitHub username}"; PROJ="${3:?project number}"
grep -rlE 'CEO_GITHUB_USERNAME|BOT_GITHUB_USERNAME|<PROJECT_NUMBER>' --exclude-dir=.git --exclude=personalize.sh --exclude=SETUP-GUIDE.md . \
 | while read -r f; do
     sed -i.bak -e "s/CEO_GITHUB_USERNAME/$CEO/g" -e "s/BOT_GITHUB_USERNAME/$BOT/g" -e "s/<PROJECT_NUMBER>/$PROJ/g" "$f" && rm -f "$f.bak"
   done
echo "Done. Review with: git diff"
