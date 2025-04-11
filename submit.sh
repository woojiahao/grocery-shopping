#!/bin/bash

# TODO maybe this should be a dedicated CLI instead of a complex Bash script

set -e

check_binary() {
  if ! which "$1" >/dev/null; then
    (>&2 echo "$2")
    exit 1
  fi
}

# TODO Maybe check if Github connection is working as well?
check_binary "git" "You need to install Github"
check_binary "gh" "You need to install the Github CLI"

if ! gh auth status >/dev/null 2>&1; then
  echo "You aren't logged in to Github CLI yet. Run gh auth login to login"
  exit 1
fi

# Get current directory name to get exercise name
EXERCISE_NAME=${PWD##*/}

# Check if PR exists already
OPEN_PR=$(gh pr list --repo git-mastery/$EXERCISE_NAME --state "open" --author "@me" --head "submission")

CURRENT_USERNAME=$(gh api user -q ".login")

if [ ! $(git rev-parse --verify submission 2>/dev/null) ]; then
  git branch submission 2>/dev/null
fi

# We need to push the submission to the submission branch so we just want to switch back after
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Pushing all changes"
git push --all origin
git checkout submission
git commit -m "Submission" --allow-empty
git push origin submission
git checkout $CURRENT_BRANCH

if [[ -z $OPEN_PR ]]; then
  echo "You don't have an open PR for $EXERCISE_NAME yet, creating one on your behalf"
  gh pr create \
    --repo git-mastery/$EXERCISE_NAME \
    --title "[$CURRENT_USERNAME] [$EXERCISE_NAME] Submission" \
    --body "" \
    --head $CURRENT_USERNAME:submission
fi
