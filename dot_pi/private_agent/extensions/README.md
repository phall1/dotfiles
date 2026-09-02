# Pi extensions

Tracked extensions are portable code loaded by Pi with user permissions.
Reviewed npm packages are pinned by `modify_settings.json`.

`role-profile.ts` is the capability-policy adapter. It removes known
user-question/interview tools from every role and blocks stale calls while
retaining child-to-parent supervisor coordination:
- Commander is the broad productive default.
- Spartan registers pi-subagents' public session-scoped capability ceiling so
  local code/command read-only restrictions propagate monotonically to nested
  and async children. Explicit Blackbird mail and reservation operations remain
  available and can mutate coordination state.
- YOLO widens delegation depth through its launcher but retains the shared
  upstream/third-party autonomy boundary.

Goal completion tools remain available under Spartan because they terminate or
pause autonomous work without granting local mutation authority. Long-horizon
policy lives in the separately tracked `pi-goal.json`; the main-session
watchdog is a bounded second pass, not a replacement for fresh reviewers.

Spartan deliberately keeps trusted provider extensions loaded for web research,
nested delegation, and explicit Blackbird tools; the allowed-tool intersection
prevents descendants from invoking mutation tools but does not suppress trusted
extension lifecycle code. Tool policy is not an OS sandbox. Use a container,
VM, or Pi's documented sandbox extensions when process isolation is required.

The dirty-repo guard, checkpoint, permission-gate, and example extensions are
`.disabled` references; they do not prompt during ordinary Commander work.
Runtime credentials and generated package trees never belong here.
