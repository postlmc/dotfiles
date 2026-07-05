---
description: 'Markdown formatting rules — line length, linting tool, and prohibited workarounds.'
applyTo: '**/*.md'
---

# Markdown Formatting

## Line Length

**132 columns is the maximum, not the target.** Prose lines must fill toward 132 characters before wrapping. A line that ends at
80 or 100 characters when the sentence has more to say violates the intent of the rule, even if it passes the check numerically.
The markdownlint config sets a ceiling; write toward it.

Exceptions (already configured in `.markdownlint-cli2.jsonc` — no action required):

- Code blocks: no line length limit
- Tables: no line length limit

A line is correctly short only when content genuinely ends there: the last sentence of a paragraph that would exceed 132 combined
with the next, a list item, a heading, or a similar natural terminal point.

## Linting Tool

Always validate Markdown with:

```bash
markdownlint-cli2 --config "${HOME}/.markdownlint-cli2.jsonc" <file>
```

**Do not use:** `markdownlint`, `npx markdownlint-cli2`, or `markdownlint-cli2` without the `--config` flag. The bare invocation
loads different defaults and may auto-modify files.

Run the linter after writing or editing any `.md` file. Resolve all reported errors before declaring the task complete.

## Prohibited Workarounds

Linting errors must be resolved by fixing the content, not by:

- Modifying `.markdownlint-cli2.jsonc` or any markdownlint config file
- Adding inline suppressions (`<!-- markdownlint-disable -->` or similar)
- Switching to a different linting tool or skipping the lint step

If content cannot satisfy a rule, say so and ask. Per-project rule overrides are the user's decision. Model-initiated config
changes are not acceptable.
