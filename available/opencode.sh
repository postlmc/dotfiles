#!/bin/bash

command -v opencode >/dev/null 2>&1 || return

# OpenCode also loads skills from ~/.claude/skills/, including claude.ai-synced ones that depend on
# Claude-only tools. This repo's own skills reach OpenCode through rulesync instead; skills in
# ~/.agents/skills/ are unaffected.
export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1
