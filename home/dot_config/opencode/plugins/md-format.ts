import type { Plugin } from "@opencode-ai/plugin"
import { isAbsolute, join } from "node:path"

// Reflows and lints every Markdown file an edit tool touches, via ~/.local/bin/md-format-hook, and
// appends any remaining lint problems to the tool result so the model sees and fixes them.

const MD = /\.(md|markdown)$/i
// apply_patch (used with OpenAI models) carries its targets inside the patch text
const PATCH_FILE = /^\*\*\* (?:Add File|Update File|Move to): (.+)$/gm

function markdownPaths(args: Record<string, unknown>, root: string): string[] {
  const found = new Set<string>()
  for (const key of ["filePath", "file_path", "path"]) {
    const v = args[key]
    if (typeof v === "string") found.add(v)
  }
  for (const v of Object.values(args)) {
    if (typeof v === "string" && v.includes("*** Begin Patch")) {
      for (const m of v.matchAll(PATCH_FILE)) found.add(m[1].trim())
    }
  }
  return [...found].filter((p) => MD.test(p)).map((p) => (isAbsolute(p) ? p : join(root, p)))
}

export const MdFormatPlugin: Plugin = async ({ $, directory }) => {
  const hook = join(process.env.HOME ?? "", ".local/bin/md-format-hook")
  const pending = new Map<string, string[]>()

  return {
    "tool.execute.before": async (input, output) => {
      const args = output?.args
      if (!args || typeof args !== "object") return
      const paths = markdownPaths(args as Record<string, unknown>, directory)
      if (paths.length) pending.set(input.callID, paths)
    },
    "tool.execute.after": async (input, output) => {
      const paths = pending.get(input.callID)
      if (!paths) return
      pending.delete(input.callID)

      const payload = new Response(JSON.stringify({ files: paths }))
      const result = await $`${hook} < ${payload}`.quiet().nothrow()
      const problems = String(result.stderr).trim()
      if (result.exitCode !== 0 && problems && output && typeof output.output === "string") {
        output.output += `\n\n${problems}`
      }
    },
  }
}
