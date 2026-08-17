import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { registerSubagentCapabilityCeiling } from "pi-subagents/capability-ceiling";

type CeilingRegistration = { dispose(): void };

const BLACKBIRD_TOOLS = [
  "blackbird_start_session", "blackbird_observe_work_ref",
  "blackbird_create_objective_and_work", "blackbird_activate_objective",
  "blackbird_plan_run_with_bindings", "blackbird_join_run", "blackbird_start_run",
  "blackbird_get_context", "blackbird_sync_events", "blackbird_agent_register",
  "blackbird_agents_list", "blackbird_conversation_open", "blackbird_message_send",
  "blackbird_message_reply", "blackbird_inbox_fetch", "blackbird_thread_fetch",
  "blackbird_message_mark_read", "blackbird_message_acknowledge",
  "blackbird_reservation_acquire", "blackbird_reservation_renew",
  "blackbird_reservation_release",
];

const SPARTAN_TOOLS = [
  "read", "grep", "find", "ls", "subagent", "subagent_wait",
  "contact_supervisor", "subagent_supervisor", "intercom", "ask_user_question",
  "web_search", "source_check", "fetch_content", "get_search_content",
  ...BLACKBIRD_TOOLS,
];

export default function roleProfile(pi: ExtensionAPI) {
  let restriction: CeilingRegistration | undefined;
  const rawRole = (process.env.PI_AGENT_ROLE || "commander").toLowerCase();
  const role = ["commander", "spartan", "yolo"].includes(rawRole) ? rawRole : "commander";

  const restrictActiveTools = () => {
    if (role !== "spartan") return;
    const available = new Set(pi.getAllTools().map((tool) => tool.name));
    pi.setActiveTools(SPARTAN_TOOLS.filter((name) => available.has(name)));
  };

  const apply = (ctx: ExtensionContext) => {
    restriction?.dispose();
    restriction = undefined;
    if (role === "spartan") {
      restrictActiveTools();
      restriction = registerSubagentCapabilityCeiling({
        sessionId: ctx.sessionManager.getSessionId(),
        source: "role-profile:spartan",
        ceiling: { allowedTools: SPARTAN_TOOLS },
      });
    }
    if (ctx.hasUI) ctx.ui.setStatus("agent-role", `role:${role}`);
  };

  pi.on("tool_call", async (event) => {
    if (role === "spartan" && !SPARTAN_TOOLS.includes(event.toolName)) {
      return { block: true, reason: `Spartan capability ceiling denies tool: ${event.toolName}` };
    }
    return undefined;
  });

  pi.on("session_start", (_event, ctx) => apply(ctx));
  // Other extensions can register or reactivate tools during session startup.
  // Reassert the visible Spartan surface immediately before every agent turn.
  pi.on("before_agent_start", () => restrictActiveTools());
  pi.on("session_shutdown", (_event, ctx) => {
    restriction?.dispose();
    restriction = undefined;
    if (ctx.hasUI) ctx.ui.setStatus("agent-role", undefined);
  });

  pi.registerCommand("role", {
    description: "Show the active Commander, Spartan, or YOLO role",
    handler: async (_args, ctx) => ctx.ui.notify(`Active Pi role: ${role}`, "info"),
  });
}
