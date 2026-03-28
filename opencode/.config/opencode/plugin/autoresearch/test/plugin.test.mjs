import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const pluginDir = path.resolve(here, "..");
const installedPluginDir = path.join(os.homedir(), ".config", "opencode", "plugin", "autoresearch");
const pluginPath = fs.existsSync(path.join(installedPluginDir, "index.js"))
  ? path.join(installedPluginDir, "index.js")
  : path.join(pluginDir, "index.js");
const commandPath = path.resolve(pluginDir, "..", "..", "commands", "autoresearch.md");

async function loadPluginModule() {
  return import(`${pathToFileURL(pluginPath).href}?t=${Date.now()}`);
}

async function loadPlugin() {
  const mod = await loadPluginModule();
  return mod.default;
}

test("plugin module only exports the default hook factory", async () => {
  const mod = await loadPluginModule();
  assert.deepEqual(Object.keys(mod).sort(), ["default"]);
  assert.equal(typeof mod.default, "function");
});

test("autoresearch_manage start/off/clear persists state", async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "opencode-autoresearch-"));
  const plugin = await loadPlugin();
  const hooks = await plugin({ directory: tmp, worktree: tmp });

  const start = JSON.parse(await hooks.tool.autoresearch_manage.execute({ action: "start", goal: "test goal" }));
  assert.equal(start.active, true);
  assert.equal(start.goal, "test goal");
  assert.equal(start.hasAutoresearchMd, false);
  assert.equal(fs.existsSync(path.join(tmp, ".opencode-autoresearch-state.json")), true);

  const off = JSON.parse(await hooks.tool.autoresearch_manage.execute({ action: "off" }));
  assert.equal(off.active, false);
  const offState = JSON.parse(fs.readFileSync(path.join(tmp, ".opencode-autoresearch-state.json"), "utf8"));
  assert.equal(offState.active, false);
  assert.equal(offState.goal, "test goal");

  fs.writeFileSync(path.join(tmp, "autoresearch.jsonl"), "{}\n");
  const cleared = JSON.parse(await hooks.tool.autoresearch_manage.execute({ action: "clear" }));
  assert.deepEqual(cleared.cleared, [".opencode-autoresearch-state.json", "autoresearch.jsonl"]);
  assert.equal(fs.existsSync(path.join(tmp, ".opencode-autoresearch-state.json")), false);
  assert.equal(fs.existsSync(path.join(tmp, "autoresearch.jsonl")), false);
});

test("autoresearch_manage start reports resume context when autoresearch.md exists", async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "opencode-autoresearch-"));
  fs.writeFileSync(path.join(tmp, "autoresearch.md"), "# plan\n");

  const plugin = await loadPlugin();
  const hooks = await plugin({ directory: tmp, worktree: tmp });

  const start = JSON.parse(await hooks.tool.autoresearch_manage.execute({ action: "start", goal: "resume loop" }));
  assert.equal(start.active, true);
  assert.equal(start.hasAutoresearchMd, true);
  assert.equal(start.stateFile, ".opencode-autoresearch-state.json");

  const state = JSON.parse(fs.readFileSync(path.join(tmp, ".opencode-autoresearch-state.json"), "utf8"));
  assert.equal(state.active, true);
  assert.equal(state.goal, "resume loop");
  assert.match(state.guardrail, /do not cheat on the benchmarks/i);
});

test("system transform injects autoresearch note only when active", async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "opencode-autoresearch-"));
  const plugin = await loadPlugin();
  const hooks = await plugin({ directory: tmp, worktree: tmp });

  assert.equal(typeof hooks.tool.autoresearch_manage.args.action.safeParse, "function");

  const inactive = { system: [] };
  await hooks["experimental.chat.system.transform"]({}, inactive);
  assert.equal(inactive.system.length, 0);

  await hooks.tool.autoresearch_manage.execute({ action: "start", goal: "resume loop" });
  const active = { system: [] };
  await hooks["experimental.chat.system.transform"]({}, active);
  assert.equal(active.system.length, 1);
  assert.match(active.system[0], /Autoresearch Mode/);
  assert.match(active.system[0], /do not cheat on the benchmarks/i);
});

test("compaction hook preserves resume guidance", async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "opencode-autoresearch-"));
  const plugin = await loadPlugin();
  const hooks = await plugin({ directory: tmp, worktree: tmp });

  await hooks.tool.autoresearch_manage.execute({ action: "start", goal: "resume loop" });
  const output = { context: [] };
  await hooks["experimental.session.compacting"]({ sessionID: "s1" }, output);
  assert.equal(output.context.length, 1);
  assert.match(output.context[0], /resume by reading autoresearch\.md/i);
});

test("slash command prompt is installed at the real OpenCode commands path", () => {
  const text = fs.readFileSync(commandPath, "utf8");
  assert.match(text, /If `\$ARGUMENTS` is empty, explain usage:/);
  assert.match(text, /\/autoresearch <goal>/);
  assert.match(text, /If `\$ARGUMENTS` is `off`:/);
  assert.match(text, /\/autoresearch off/);
  assert.match(text, /If `\$ARGUMENTS` is `clear`:/);
  assert.match(text, /\/autoresearch clear/);
  assert.match(text, /Prefer calling the `autoresearch_manage` tool with `action: "start"`/);
  assert.match(text, /do not cheat on the benchmarks/i);
});
