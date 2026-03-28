import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

const STATE_FILE = ".opencode-autoresearch-state.json";
const JSONL_FILE = "autoresearch.jsonl";
const MD_FILE = "autoresearch.md";
const IDEAS_FILE = "autoresearch.ideas.md";
const CHECKS_FILE = "autoresearch.checks.sh";
const GUARDRAIL = "Be careful not to overfit to the benchmarks and do not cheat on the benchmarks.";
const HOME_PLUGIN_TOOL_PATH = path.join(
  os.homedir(),
  ".config",
  "opencode",
  "node_modules",
  "@opencode-ai",
  "plugin",
  "dist",
  "tool.js",
);

function statePath(root) {
  return path.join(root, STATE_FILE);
}

function jsonlPath(root) {
  return path.join(root, JSONL_FILE);
}

function readState(root) {
  try {
    return JSON.parse(fs.readFileSync(statePath(root), "utf8"));
  } catch {
    return { active: false };
  }
}

function writeState(root, state) {
  fs.writeFileSync(statePath(root), `${JSON.stringify(state, null, 2)}\n`);
}

function clearState(root) {
  try {
    fs.unlinkSync(statePath(root));
  } catch {}
}

function buildAutoresearchSystemNote(root, state) {
  const lines = [
    "## Autoresearch Mode (ACTIVE)",
    "You are in autoresearch mode inside OpenCode.",
    "Optimize the tracked objective through an autonomous experiment loop.",
    `Read ${MD_FILE} at the start of the turn if it exists and follow it as the source of truth.`,
    `If ${IDEAS_FILE} exists, use it as a backlog for deferred ideas.`,
    GUARDRAIL,
  ];

  if (state.goal) {
    lines.push(`Current goal: ${state.goal}`);
  }

  if (fs.existsSync(path.join(root, CHECKS_FILE))) {
    lines.push(`Correctness checks exist in ${CHECKS_FILE}; do not keep benchmark wins that fail them.`);
  }

  return lines.join("\n");
}

async function manage(root, args = {}) {
  const action = String(args.action || "start").trim().toLowerCase();
  const goal = String(args.goal || "").trim();
  const state = readState(root);

  if (action === "off") {
    writeState(root, {
      ...state,
      active: false,
      stoppedAt: new Date().toISOString(),
    });
    return JSON.stringify({ ok: true, action, active: false, message: "Autoresearch mode OFF" }, null, 2);
  }

  if (action === "clear") {
    clearState(root);
    try {
      fs.unlinkSync(jsonlPath(root));
    } catch {}
    return JSON.stringify({ ok: true, action, active: false, cleared: [STATE_FILE, JSONL_FILE] }, null, 2);
  }

  const next = {
    active: true,
    goal,
    startedAt: state.startedAt || new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    guardrail: GUARDRAIL,
  };
  writeState(root, next);
  return JSON.stringify(
    {
      ok: true,
      action: "start",
      active: true,
      goal,
      hasAutoresearchMd: fs.existsSync(path.join(root, MD_FILE)),
      stateFile: STATE_FILE,
    },
    null,
    2,
  );
}

export default async function AutoresearchPlugin(input = {}) {
  const root = input.directory || input.worktree || process.cwd();
  const { tool } = await import(pathToFileURL(HOME_PLUGIN_TOOL_PATH).href);

  return {
    tool: {
      autoresearch_manage: tool({
        description: "Manage persistent OpenCode autoresearch state for /autoresearch-like workflows",
        args: {
          action: tool.schema.enum(["start", "off", "clear"]).describe("Whether to start, stop, or clear autoresearch state"),
          goal: tool.schema.string().optional().describe("Goal text for start/resume"),
        },
        async execute(args) {
          return manage(root, args);
        },
      }),
    },

    "experimental.chat.system.transform": async (_input, output) => {
      const state = readState(root);
      if (!state.active) return;
      output.system.push(buildAutoresearchSystemNote(root, state));
    },

    "experimental.session.compacting": async (_input, output) => {
      const state = readState(root);
      if (!state.active) return;
      output.context.push(
        [
          "Autoresearch is active.",
          `After compaction, resume by reading ${MD_FILE} and continuing the experiment loop.`,
          `Check ${IDEAS_FILE} for deferred ideas before repeating dead ends.`,
          GUARDRAIL,
        ].join(" "),
      );
    },
  };
}

