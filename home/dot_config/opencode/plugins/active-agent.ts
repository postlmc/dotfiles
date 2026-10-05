import type { Plugin } from "@opencode-ai/plugin"

// ACTIVE_AGENT trips the minimal agent-shell branch in .zshrc/.bashrc (no pager, no history, no
// plugins), matching what Claude Code's settings env and the VS Code Copilot terminal profile set.
// `opencode run` shells skip .zshrc entirely and inherit the launching terminal's pager, so the
// pager overrides from that branch are set here too.
export const ActiveAgentPlugin: Plugin = async () => ({
  "shell.env": async (_input, output) => {
    output.env.ACTIVE_AGENT = "opencode"
    output.env.PAGER = "cat"
    output.env.GIT_PAGER = "cat"
  },
})
