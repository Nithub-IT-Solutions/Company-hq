#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <agency-agents-checkout> <claude-agents-directory>" >&2
  exit 2
fi

source_dir="$1"
destination_dir="$2"
required_agents=(
  "product/product-trend-researcher.md|Trend Researcher"
  "specialized/business-strategist.md|Business Strategist"
  "design/design-ux-researcher.md|UX Researcher"
  "product/product-feedback-synthesizer.md|Feedback Synthesizer"
  "specialized/specialized-pricing-analyst.md|Pricing Analyst"
  "finance/finance-financial-analyst.md|Financial Analyst"
  "marketing/marketing-growth-hacker.md|Growth Hacker"
  "support/support-legal-compliance-checker.md|Legal Compliance Checker"
  "engineering/engineering-software-architect.md|Software Architect"
  "testing/testing-reality-checker.md|Reality Checker"
)

if [[ ! -f "$source_dir/LICENSE" ]]; then
  echo "Agency-agent source has no LICENSE file; refusing to install definitions." >&2
  exit 1
fi

mkdir -p "$destination_dir"
for entry in "${required_agents[@]}"; do
  relative_path="${entry%%|*}"
  expected_name="${entry#*|}"
  source_file="$source_dir/$relative_path"
  if [[ ! -f "$source_file" ]]; then
    echo "Required specialist definition is missing: $relative_path" >&2
    exit 1
  fi
  if ! grep -Fxq "name: $expected_name" "$source_file"; then
    echo "Unexpected agent name in $relative_path; refusing to install it." >&2
    exit 1
  fi
done

for entry in "${required_agents[@]}"; do
  relative_path="${entry%%|*}"
  cp "$source_dir/$relative_path" "$destination_dir/$(basename "$relative_path")"
done
cp "$source_dir/LICENSE" "$destination_dir/AGENCY_AGENTS_LICENSE.txt"
