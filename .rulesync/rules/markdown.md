---
root: false
targets:
  - '*'
globs:
  - '**/*.md'
claudecode:
  paths:
    - '**/*.md'
---
# Markdown Formatting

## Line Length

Filling to 100 columns is mandatory, not a stylistic preference -- treat stopping short the same way
you'd treat exceeding it. Before treating a paragraph as finished, check its shortest line: if that
line's sentence continues onto the next line, the paragraph isn't done. A habit of wrapping near 80
columns because that's the common convention for code comments and READMEs is exactly the failure
this rule exists to prevent. 100 was chosen deliberately, not picked at random: it's rustfmt's own
stable default, sits above Prettier's 80 and Black's 88, and is where prose and code blocks alike
now target.

The linter does not enforce line length inside code blocks or tables (set in
`.markdownlint-cli2.jsonc`):

- Code blocks: 100 columns, same as prose. Break at a sensible syntactic boundary once a line would
  exceed it, and keep logical units intact instead of filling to the edge. Exceed 100 only when a
  break would change behavior or hurt clarity, such as long string literals, URLs, import paths, or
  regex that cannot be split.
- Tables: no limit. Let them run to whatever width the aligned columns require.

A line is correctly short only when content genuinely ends there: the last sentence of a paragraph
that would exceed 100 combined with the next, a list item, a heading, or a similar natural terminal
point.

## Headings

Use title case for all headings: capitalize the first word, the last word, and every principal word.
Leave articles, coordinating conjunctions, and short prepositions lowercase unless they begin or end
the heading.

## Linting Tool

Validate every Markdown file with exactly this command and no other tool:

```bash
markdownlint-cli2 --config "${HOME}/.markdownlint-cli2.jsonc" <file>
```

This command is mandatory and not optional. Do not use any other linter, formatter, or invocation
for Markdown. The tool and the config are fixed. Run it after writing or editing any `.md` file and
resolve all reported errors before declaring the task complete.

## Tables

Tables must use column-aligned padding so cells line up visually. Each column is padded to exactly
the width of its widest cell, with no extra padding. One space on each side of cell content.
Separator rows use compact dashes with no spaces. Example:

```markdown
| Tool        | Path                     | Extension |
|-------------|--------------------------|-----------|
| Claude Code | `home/dot_claude/rules/` | `.md`     |
| Cursor      | `home/dot_cursor/rules/` | `.mdc`    |
```

To produce this formatting, run `align-tables <file>` after editing a table, then lint. It aligns
every table in the file and leaves fenced code blocks untouched.

## Documentation Content

- Do not include entire source files in documentation. Include only the sections necessary to
  explain the subject and link to the full file.
- Do not add emoji unprompted -- to headings, bullets, or anywhere else -- even when the content
  might seem to invite it. This is about unsolicited decoration, the kind that litters every heading
  and bullet, not emoji as such. When the user explicitly asks for emoji, or they serve as a
  meaningful functional indicator rather than decoration (a status column in a table, say), they're
  fine.

## Prohibited Workarounds

Linting errors must be resolved by fixing the content, not by:

- Modifying `.markdownlint-cli2.jsonc` or any markdownlint config file
- Adding inline suppressions (`<!-- markdownlint-disable -->` or similar)
- Switching to a different linting tool or skipping the lint step

If content cannot satisfy a rule, say so and ask. Per-project rule overrides are the user's
decision. Model-initiated config changes are not acceptable.
