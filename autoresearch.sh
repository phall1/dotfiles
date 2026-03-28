#!/bin/bash
set -euo pipefail

start_ms=$(node -e 'console.log(Date.now())')

node <<'NODE'
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');

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

(async () => {
  let score = 0;

  if (has(pluginDir)) score += 1;
  if (has(pkgPath)) score += 1;
  if (has(indexPath)) score += 1;
  if (has(commandPath)) score += 1;
  if (has(readmePath)) score += 1;

  let pkg = null;
  if (has(pkgPath)) {
    try {
      pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
      if (typeof pkg.name === 'string' && pkg.name.includes('autoresearch')) score += 1;
      if (pkg.type === 'module') score += 1;
      if (typeof pkg.dependencies === 'object' && pkg.dependencies && pkg.dependencies['@opencode-ai/plugin']) score += 1;
    } catch {}
  }

  if (has(configPath)) {
    const config = fs.readFileSync(configPath, 'utf8');
    if (/autoresearch/.test(config)) score += 1;
  }

  if (has(indexPath)) {
    try {
      const mod = await import(pathToFileURL(indexPath).href + `?t=${Date.now()}`);
      const plugin = mod.default;
      if (typeof plugin === 'function') {
        const hooks = await plugin({
          client: {},
          project: {},
          directory: root,
          worktree: root,
          $: () => { throw new Error('shell not available in benchmark'); },
        });
        if (hooks && hooks.tool && hooks.tool.autoresearch_manage) score += 1;
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
