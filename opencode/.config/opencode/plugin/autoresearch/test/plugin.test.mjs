import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const pluginDir = path.resolve(here, "..");
const pluginPath = path.join(pluginDir, "index.js");
const commandPath = path.join(pluginDir, "commands", "autoresearch.md");

async function loadPlugin() {
  return import(`${pathToFileURL(pluginPath).href}?t=${Date.now()}`);
}

test("autoresearch_manage start/off/clear persists state", async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "opencode-autoresearch-"));
  const { default: plugin } = await loadPlugin();
  const hooks = await plugin({ directory: tmp, worktree: tmp });

  const start = JSON.parse(await hooks.tool.autoresearch_manage.execute({ action: "start", goal: "test goal" }));
  assert.equal(start.active, true);
  assert.equal(fs.existsSync(path.join(tmp, ".opencode-autoresearch-state.json")), true);

  const off = JSON.parse(await hooks.tool.autoresearch_manage.execute({ action: "off" }));
  assert.equal(off.active, false);

  fs.writeFileSync(path.join(tmp, "autoresearch.jsonl"), "{}\n");
  await hooks.tool.autoresearch_manage.execute({ action: "clear" });
  assert.equal(fs.existsSync(path.join(tmp, ".opencode-autoresearch-state.json")), false);
  assert.equal(fs.existsSync(path.join(tmp, "autoresearch.jsonl")), false);
});

test("system transform injects autoresearch note only when active", async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "opencode-autoresearch-"));
  const { default: plugin } = await loadPlugin();
  const hooks = await plugin({ directory: tmp, worktree: tmp });

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
  const { default: plugin } = await loadPlugin();
  const hooks = await plugin({ directory: tmp, worktree: tmp });

  await hooks.tool.autoresearch_manage.execute({ action: "start", goal: "resume loop" });
  const output = { context: [] };
  await hooks["experimental.session.compacting"]({ sessionID: "s1" }, output);
  assert.equal(output.context.length, 1);
  assert.match(output.context[0], /resume by reading autoresearch\.md/i);
});

test("slash command prompt documents start off clear and guardrail", () => {
  const text = fs.readFileSync(commandPath, "utf8");
  assert.match(text, /\/autoresearch <goal>/);
  assert.match(text, /\/autoresearch off/);
  assert.match(text, /\/autoresearch clear/);
  assert.match(text, /do not cheat on the benchmarks/i);
});
