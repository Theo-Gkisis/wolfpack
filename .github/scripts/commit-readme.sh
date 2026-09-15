#!/usr/bin/env bash
set -euo pipefail

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add README.md
git diff --cached --quiet || git commit -m "chore: update vulnerability scan summary"

for attempt in 1 2 3; do
  if git push origin HEAD:main; then
    exit 0
  fi
  echo "Push rejected (attempt ${attempt}/3), rebasing onto latest main and retrying..."
  git fetch origin main
  git rebase origin/main
done

echo "::error::Failed to push README update after 3 attempts"
exit 1
