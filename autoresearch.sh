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
const commandPath = path.join(root, 'opencode/.config/opencode/commands/autoresearch.md');
const readmePath = path.join(pluginDir, 'README.md');
const configPath = path.join(root, 'opencode/.config/opencode/opencode.jsonc');
const gitignorePath = path.join(root, '.gitignore');

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
    return null;
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
        const hasSystemTransform = hooks && typeof hooks['experimental.chat.system.transform'] === 'function';
        if (hasSystemTransform) score += 1;
        const hasCompaction = hooks && typeof hooks['experimental.session.compacting'] === 'function';
        if (hasCompaction) score += 1;

        try {
          const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'autoresearch-bench-'));
          try {
            const tmpHooks = await plugin({
              client: {},
              project: {},
              directory: tmpRoot,
              worktree: tmpRoot,
              $: () => {
                throw new Error('shell not available in benchmark');
              },
            });

            const manageTool = tmpHooks?.tool?.autoresearch_manage;
            if (manageTool?.execute && hasSystemTransform && hasCompaction) {
              await manageTool.execute({ action: 'start', goal: 'dedup check' });

              const systemOutput = { system: [] };
              await tmpHooks['experimental.chat.system.transform']({}, systemOutput);
              await tmpHooks['experimental.chat.system.transform']({}, systemOutput);
              if (Array.isArray(systemOutput.system) && systemOutput.system.length === 1) {
                score += 1;
              }

              await manageTool.execute({ action: 'start', goal: 'updated goal' });
              await tmpHooks['experimental.chat.system.transform']({}, systemOutput);
              if (
                Array.isArray(systemOutput.system) &&
                systemOutput.system.length === 1 &&
                typeof systemOutput.system[0] === 'string' &&
                systemOutput.system[0].includes('Current goal: updated goal')
              ) {
                score += 1;
              }

              const compactionOutput = { context: [] };
              await tmpHooks['experimental.session.compacting']({}, compactionOutput);
              await tmpHooks['experimental.session.compacting']({}, compactionOutput);
              if (Array.isArray(compactionOutput.context) && compactionOutput.context.length === 1) {
                score += 1;
              }
            }
          } finally {
            fs.rmSync(tmpRoot, { recursive: true, force: true });
          }
        } catch {}
      }
    } catch {}
  }

  if (has(commandPath)) {
    try {
      const command = fs.readFileSync(commandPath, 'utf8');
      if (/\/autoresearch <goal>/.test(command) && /\/autoresearch off/.test(command) && /\/autoresearch clear/.test(command)) {
        score += 1;
      }
    } catch {}
  }

  if (has(configPath)) {
    try {
      const config = fs.readFileSync(configPath, 'utf8');
      if (/file:\/\/\/.*\/\.config\/opencode\/plugin\/autoresearch/.test(config)) score += 1;
    } catch {}
  }

  if (has(gitignorePath)) {
    try {
      const gitignore = fs.readFileSync(gitignorePath, 'utf8');
      if (/^\.opencode-autoresearch-state\.json$/m.test(gitignore)) score += 1;
    } catch {}
  }

  console.log(`METRIC score=${score}`);
})();
NODE

end_ms=$(node -e 'console.log(Date.now())')
duration_ms=$((end_ms - start_ms))
echo "METRIC duration_ms=$duration_ms"
