#!/bin/bash
set -euo pipefail

start_ms=$(node -e 'console.log(Date.now())')

node <<'NODE'
const fs = require('fs');
const os = require('os');
const path = require('path');
const { fileURLToPath, pathToFileURL } = require('url');

const root = process.cwd();
const pluginDir = path.join(root, 'opencode/.config/opencode/plugin/autoresearch');
const pkgPath = path.join(pluginDir, 'package.json');
const indexPath = path.join(pluginDir, 'index.js');
const commandPath = path.join(pluginDir, 'commands/autoresearch.md');
const readmePath = path.join(pluginDir, 'README.md');
const configPath = path.join(root, 'opencode/.config/opencode/opencode.jsonc');

function has(p) {
  return fs.existsSync(p);
}

function resolvePluginEntry(entry, configDir) {
  if (!entry) return null;
  if (entry.startsWith('file://')) {
    try {
      return fileURLToPath(entry);
    } catch {
      return null;
    }
  }
  if (entry.startsWith('~/')) {
    return path.join(os.homedir(), entry.slice(2));
  }
  if (path.isAbsolute(entry)) {
    return entry;
  }
  return path.resolve(configDir, entry);
}

function findAutoresearchPluginTargets(configText, configDir) {
  const matches = [...configText.matchAll(/"([^"]*autoresearch[^"]*)"/g)].map((m) => m[1]);
  return matches.map((entry) => ({ entry, resolved: resolvePluginEntry(entry, configDir) }));
}

(async () => {
  let score = 0;

  if (has(pluginDir)) score += 1;
  if (has(pkgPath)) score += 1;
  if (has(indexPath)) score += 1;
  if (has(commandPath)) score += 1;
  if (has(readmePath)) score += 1;

  if (has(pkgPath)) {
    try {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
      if (typeof pkg.name === 'string' && pkg.name.includes('autoresearch')) score += 1;
      if (pkg.type === 'module') score += 1;
      if (typeof pkg.dependencies === 'object' && pkg.dependencies && pkg.dependencies['@opencode-ai/plugin']) score += 1;
    } catch {}
  }

  if (has(configPath)) {
    const config = fs.readFileSync(configPath, 'utf8');
    const targets = findAutoresearchPluginTargets(config, path.dirname(configPath));
    if (targets.length > 0) score += 1;
    if (targets.some((target) => target.resolved && fs.existsSync(target.resolved))) score += 1;
  }

  if (has(indexPath)) {
    try {
      const mod = await import(pathToFileURL(indexPath).href + `?t=${Date.now()}`);
      const plugin = mod.default;
      if (typeof plugin === 'function') {
        score += 1;
        const hooks = await plugin({
          client: {},
          project: {},
          directory: root,
          worktree: root,
          $: () => { throw new Error('shell not available in benchmark'); },
        });
        const toolDef = hooks?.tool?.autoresearch_manage;
        if (toolDef) score += 1;
        if (toolDef?.args?.action && typeof toolDef.args.action.safeParse === 'function') score += 1;
        if (hooks && typeof hooks['experimental.chat.system.transform'] === 'function') score += 1;
        if (hooks && typeof hooks['experimental.session.compacting'] === 'function') score += 1;
      }
    } catch {}
  }

  console.log(`METRIC score=${score}`);
})();
NODE

end_ms=$(node -e 'console.log(Date.now())')
duration_ms=$((end_ms - start_ms))
echo "METRIC duration_ms=$duration_ms"
