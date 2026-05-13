# Pi Extensions

TypeScript modules that extend pi with custom tools, commands, shortcuts, UI, and event handlers.

## Quick Start

Create a `.ts` file here (or a `name/index.ts` subdirectory for multi-file extensions).

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  // Subscribe to events
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Extension loaded!", "info");
  });

  // Register tools the LLM can call
  pi.registerTool({
    name: "my_tool",
    label: "My Tool",
    description: "What this tool does",
    parameters: Type.Object({
      input: Type.String({ description: "Input text" }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return {
        content: [{ type: "text", text: `Result: ${params.input}` }],
        details: {},
      };
    },
  });

  // Register commands (invoked via /command)
  pi.registerCommand("hello", {
    description: "Say hello",
    handler: async (args, ctx) => {
      ctx.ui.notify(`Hello ${args || "world"}!`, "info");
    },
  });

  // Register keyboard shortcuts
  pi.registerShortcut("ctrl+shift+h", {
    description: "Quick hello",
    handler: async (ctx) => ctx.ui.notify("Hey!", "info"),
  });
}
```

## Capabilities

- **Custom tools** — `pi.registerTool()` — LLM-callable tools
- **Event hooks** — `pi.on()` — intercept tool calls, inject context, customize compaction
- **Commands** — `pi.registerCommand()` — `/slash` commands
- **Shortcuts** — `pi.registerShortcut()` — keyboard shortcuts
- **UI** — `ctx.ui.*` — notifications, confirmations, selections, custom widgets
- **State** — `pi.appendEntry()` — persist data across restarts
- **Providers** — `pi.registerProvider()` — custom model providers

## Events (lifecycle order)

session_start → input → before_agent_start → agent_start →
  turn_start → context → before_provider_request →
    tool_call → tool_execution_start → tool_execution_end → tool_result →
  turn_end →
agent_end → session_shutdown

## Extension Styles

- **Single file**: `my-extension.ts`
- **Directory**: `my-extension/index.ts` (multi-file)
- **With deps**: `my-extension/package.json` + `npm install` (npm dependencies)

## Example Ideas

- Permission gates (confirm before dangerous commands)
- Git checkpointing (stash/restore at each turn)
- Protected paths (block writes to sensitive files)
- Sub-agents (spawn pi instances)
- Plan mode (structured task planning)
- Custom compaction (summarize your way)
- Status lines, headers, footers
- SSH/sandbox execution

## Reference

- Docs: https://pi.dev/docs/latest/extensions
- Examples: https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions
- Hot reload: `/reload` in pi
