import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const STATE_FILE = ".opencode-autoresearch-state.json";
const JSONL_FILE = "autoresearch.jsonl";
const MD_FILE = "autoresearch.md";
const IDEAS_FILE = "autoresearch.ideas.md";
const CHECKS_FILE = "autoresearch.checks.sh";
const GUARDRAIL = "Be careful not to overfit to the benchmarks and do not cheat on the benchmarks.";
const TOOL_MODULE_CANDIDATES = [
  path.join(os.homedir(), ".config", "opencode", "node_modules", "@opencode-ai", "plugin", "dist", "tool.js"),
  path.join(HERE, "node_modules", "@opencode-ai", "plugin", "dist", "tool.js"),
];

let toolPromise;

function fileExists(filePath) {
  return fs.existsSync(filePath);
}

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

function toJson(value) {
  return JSON.stringify(value, null, 2);
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

  if (fileExists(path.join(root, CHECKS_FILE))) {
    lines.push(`Correctness checks exist in ${CHECKS_FILE}; do not keep benchmark wins that fail them.`);
  }

  return lines.join("\n");
}

async function loadTool() {
  for (const toolModulePath of TOOL_MODULE_CANDIDATES) {
    if (!fileExists(toolModulePath)) {
      continue;
    }

    try {
      const mod = await import(pathToFileURL(toolModulePath).href);
      if (mod?.tool?.schema) {
        return mod.tool;
      }
    } catch {}
  }

  throw new Error("Unable to resolve @opencode-ai/plugin/tool from the active OpenCode installation.");
}

function getTool() {
  toolPromise ??= loadTool();
  return toolPromise;
}

async function manage(root, args = {}) {
  const action = String(args.action || "start").trim().toLowerCase();
  const goal = String(args.goal || "").trim();
  const state = readState(root);

  switch (action) {
    case "off": {
      writeState(root, {
        ...state,
        active: false,
        stoppedAt: new Date().toISOString(),
      });
      return toJson({ ok: true, action, active: false, message: "Autoresearch mode OFF" });
    }

    case "clear": {
      clearState(root);
      try {
        fs.unlinkSync(jsonlPath(root));
      } catch {}
      return toJson({ ok: true, action, active: false, cleared: [STATE_FILE, JSONL_FILE] });
    }

    default: {
      writeState(root, {
        active: true,
        goal,
        startedAt: state.startedAt || new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        guardrail: GUARDRAIL,
      });

      return toJson({
        ok: true,
        action: "start",
        active: true,
        goal,
        hasAutoresearchMd: fileExists(path.join(root, MD_FILE)),
        stateFile: STATE_FILE,
      });
    }
  }
}

export default async function AutoresearchPlugin(input = {}) {
  const root = input.directory || input.worktree || process.cwd();
  const tool = await getTool();

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
      const note = buildAutoresearchSystemNote(root, state);
      output.system ??= [];
      const existingIndex = output.system.findIndex(
        (entry) => typeof entry === "string" && entry.includes("Autoresearch Mode (ACTIVE)"),
      );
      if (existingIndex >= 0) {
        output.system[existingIndex] = note;
      } else {
        output.system.push(note);
      }
    },

    "experimental.session.compacting": async (_input, output) => {
      const state = readState(root);
      if (!state.active) return;
      const message = [
        "Autoresearch is active.",
        `After compaction, resume by reading ${MD_FILE} and continuing the experiment loop.`,
        `Check ${IDEAS_FILE} for deferred ideas before repeating dead ends.`,
        GUARDRAIL,
      ].join(" ");
      output.context ??= [];
      const existingIndex = output.context.findIndex(
        (entry) => typeof entry === "string" && entry.startsWith("Autoresearch is active."),
      );
      if (existingIndex >= 0) {
        output.context[existingIndex] = message;
      } else {
        output.context.push(message);
      }
    },
  };
}
