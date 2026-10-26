#!/usr/bin/env bash
# Usage: bash scripts/setup-project.sh <organization> <project-number> <bot-username> [repository]
# Creates missing project fields, links the repository, and grants the bot write access.
set -euo pipefail

ORG="${1:?usage: setup-project.sh <organization> <project-number> <bot-username> [repository]}"
PROJECT_NUMBER="${2:?usage: setup-project.sh <organization> <project-number> <bot-username> [repository]}"
BOT="${3:?usage: setup-project.sh <organization> <project-number> <bot-username> [repository]}"
REPO="${4:-Company-hq}"

if [[ ! "$PROJECT_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Project number must be a positive integer." >&2
  exit 2
fi

gh auth status --hostname github.com >/dev/null

PROJECT_QUERY='query($org: String!, $number: Int!) {
  organization(login: $org) {
    projectV2(number: $number) {
      id
      title
      fields(first: 100) {
        nodes {
          ... on ProjectV2FieldCommon { name }
        }
      }
      repositories(first: 100) {
        nodes { nameWithOwner }
      }
    }
  }
}'

PROJECT_ID=$(gh api graphql -F org="$ORG" -F number="$PROJECT_NUMBER" -f query="$PROJECT_QUERY" \
  --jq '.data.organization.projectV2.id')
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
  echo "Could not find organization project $ORG/projects/$PROJECT_NUMBER." >&2
  exit 1
fi

PROJECT_TITLE=$(gh api graphql -F org="$ORG" -F number="$PROJECT_NUMBER" -f query="$PROJECT_QUERY" \
  --jq '.data.organization.projectV2.title')
FIELD_NAMES=$(gh api graphql -F org="$ORG" -F number="$PROJECT_NUMBER" -f query="$PROJECT_QUERY" \
  --jq '.data.organization.projectV2.fields.nodes[].name')

has_field() {
  grep -Fxq "$1" <<< "$FIELD_NAMES"
}

create_select_field() {
  local name="$1"
  local options="$2"
  if has_field "$name"; then
    echo "Keeping existing field: $name"
  else
    gh project field-create "$PROJECT_NUMBER" --owner "$ORG" --name "$name" \
      --data-type SINGLE_SELECT --single-select-options "$options" >/dev/null
    echo "Created field: $name"
  fi
}

create_text_field() {
  local name="$1"
  if has_field "$name"; then
    echo "Keeping existing field: $name"
  else
    gh project field-create "$PROJECT_NUMBER" --owner "$ORG" --name "$name" \
      --data-type TEXT >/dev/null
    echo "Created field: $name"
  fi
}

create_select_field "Phase" "Intake,Discovery,Product,Planning,Build,Release"
create_select_field "Gate" "Gate 1,Gate 2,Gate 3,Release,—"
create_text_field "Idea"
create_text_field "Agent"
create_select_field "Size" "S,M,L"

REPO_ID=$(gh api graphql -F org="$ORG" -F repo="$REPO" \
  -f query='query($org: String!, $repo: String!) { repository(owner: $org, name: $repo) { id } }' \
  --jq '.data.repository.id')
BOT_ID=$(gh api graphql -F login="$BOT" \
  -f query='query($login: String!) { user(login: $login) { id } }' \
  --jq '.data.user.id')

LINKED_REPOS=$(gh api graphql -F org="$ORG" -F number="$PROJECT_NUMBER" -f query="$PROJECT_QUERY" \
  --jq '.data.organization.projectV2.repositories.nodes[].nameWithOwner')
if grep -Fxq "$ORG/$REPO" <<< "$LINKED_REPOS"; then
  echo "Repository already linked: $ORG/$REPO"
else
  gh api graphql -F projectId="$PROJECT_ID" -F repositoryId="$REPO_ID" \
    -f query='mutation($projectId: ID!, $repositoryId: ID!) {
      linkProjectV2ToRepository(input: {projectId: $projectId, repositoryId: $repositoryId}) {
        repository { nameWithOwner }
      }
    }' >/dev/null
  echo "Linked repository: $ORG/$REPO"
fi

gh api graphql -F projectId="$PROJECT_ID" -F botId="$BOT_ID" \
  -f query='mutation($projectId: ID!, $botId: ID!) {
    updateProjectV2Collaborators(input: {
      projectId: $projectId,
      collaborators: [{userId: $botId, role: WRITE}]
    }) {
      projectV2 { id }
    }
  }' >/dev/null

echo "Granted $BOT write access to \"$PROJECT_TITLE\"."
echo "The default Status options, Sprint iteration field, views, and project workflows still need to be configured in the GitHub UI."
