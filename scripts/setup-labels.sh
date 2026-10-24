#!/usr/bin/env bash
# Usage: bash scripts/setup-labels.sh <owner/repo>
# Creates the company label set (safe to re-run; updates existing labels).
set -euo pipefail
REPO="${1:?usage: setup-labels.sh owner/repo}"
mk() { gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force; }
# Gates (CEO decisions)
mk "ceo-approval"     "B60205" "Waiting for the CEO's decision"
mk "gate:1-idea"      "5319E7" "Gate 1 - Idea approval"
mk "gate:2-scope"     "5319E7" "Gate 2 - Scope approval"
mk "gate:3-plan"      "5319E7" "Gate 3 - Build plan approval"
mk "gate:release"     "5319E7" "Release approval"
# Phases
mk "phase:intake"     "C5DEF5" "Phase 0 - Intake"
mk "phase:discovery"  "C5DEF5" "Phase 1 - Discovery"
mk "phase:product"    "C5DEF5" "Phase 2 - Product definition"
mk "phase:planning"   "C5DEF5" "Phase 3 - Build planning"
mk "phase:build"      "C5DEF5" "Phase 4-5 - Build"
# Types
mk "type:idea"        "FBCA04" "Business idea"
mk "type:feature"     "0E8A16" "New capability"
mk "type:bug"         "D73A4A" "Something is broken"
mk "type:task"        "BFDADC" "Chore / operational task"
mk "type:security"    "B60205" "Security work or finding"
# Areas
mk "area:frontend"    "1D76DB" "UI / web / mobile"
mk "area:backend"     "1D76DB" "API / services / data"
mk "area:infra"       "1D76DB" "Cloud / CI/CD / DevOps"
mk "area:docs"        "1D76DB" "Documentation"
# Severity & status
mk "severity:critical" "B60205" "Fix before anything else"
mk "severity:high"     "D93F0B" "Fix this sprint"
mk "severity:medium"   "FBCA04" "Plan it"
mk "severity:low"      "C2E0C6" "Nice to fix"
mk "status:blocked"    "000000" "Cannot proceed - see comments"
mk "needs-ceo-input"   "B60205" "Agents need a decision"
echo "Labels ready on $REPO"
