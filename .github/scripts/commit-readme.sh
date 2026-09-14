#!/usr/bin/env bash
set -euo pipefail

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add README.md
git diff --cached --quiet || git commit -m "chore: update vulnerability scan summary"
git push origin HEAD:main
