---
description: Create a git commit for staged changes
mode: agent
model: claude-haiku-4-5
tools:
  - changes
  - runCommands
  - codebase
---

# Git Commit

Review the staged changes and create a git commit.

- Use Conventional Commits format: `<type>(<scope>): <subject>`
- Subject line 50 characters max, imperative mood, no period
- Add a body only when the "why" is non-obvious
- Do not add a generated-by footer
- Stage additional related unstaged changes only if clearly part of the same
  logical change; ask otherwise
- Run `git commit` with the composed message when ready
