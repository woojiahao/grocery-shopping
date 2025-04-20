#!/bin/bash

set -e

log_step() {
  echo "[INFO] $1"
}

error_exit() {
  echo "[ERROR] $1" >&2
  exit 1
}

check_binary() {
  if ! which "$1" >/dev/null 2>&1; then
    error_exit "$2"
  fi
}

# Check for required tools
check_binary "git" "You need to install Git"
check_binary "gh" "You need to install the GitHub CLI"

# Check GitHub authentication
if ! gh auth status >/dev/null 2>&1; then
  error_exit "You aren't logged into GitHub CLI. Run 'gh auth login' to login."
fi

# Get current directory name to determine exercise name
EXERCISE_NAME=${PWD##*/}
log_step "Detected exercise: $EXERCISE_NAME"

# Check if a PR already exists
OPEN_PR=$(gh pr list --state "open" --author "@me" --head "submission" 2>/dev/null)

# Get current GitHub username
CURRENT_USERNAME=$(gh api user -q ".login" 2>/dev/null)

# Create submission branch if it doesn't exist
if ! git rev-parse --verify submission >/dev/null 2>&1; then
  log_step "Creating 'submission' branch"
  git branch submission >/dev/null 2>&1
fi

# Save the current branch to return later
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

log_step "Pushing all branches"
git push --all origin >/dev/null 2>&1

log_step "Committing to 'submission' branch"
git checkout submission >/dev/null 2>&1
git commit -m "Submission" --allow-empty >/dev/null 2>&1
git push origin submission >/dev/null 2>&1

# Return to the original branch
git checkout "$CURRENT_BRANCH" >/dev/null 2>&1

# Create a PR if one doesn't already exist
if [[ -z $OPEN_PR ]]; then
  log_step "No open PR found — creating a new pull request"
  gh pr create \
    --repo git-mastery/$EXERCISE_NAME \
    --title "[$CURRENT_USERNAME] [$EXERCISE_NAME] Submission" \
    --body "" \
    --head $CURRENT_USERNAME:submission >/dev/null 2>&1
else
  log_step "An open PR already exists — skipping PR creation"
fi

PR_URL=$(gh pr list --state "open" --author "@me" --head "submission" --json url -q '.[0].url' -L 1 | awk '{print($0)}' | column)
log_step "Submission process complete!"
log_step "Go to '$PR_URL' for the feedback!"
