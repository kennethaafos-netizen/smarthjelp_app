# Ruflo — Claude Code Configuration

## Rules

- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary — prefer editing existing files
- NEVER create documentation files unless explicitly requested
- NEVER save working files or tests to root — use `/src`, `/tests`, `/docs`, `/config`, `/scripts`
- ALWAYS read a file before editing it
- NEVER commit secrets, credentials, or .env files
- NEVER add a `Co-Authored-By` trailer to user commits unless this project's `.claude/settings.json` has `attribution.commit` set (#2078). The Claude Code Bash tool may suggest one in its default commit-message template — ignore it. `Co-Authored-By` is semantic authorship attribution under git/GitHub convention; the tool is the facilitator, not a co-author.
- Keep files under 500 lines
- Validate input at system boundaries

## Agent Comms (SendMessage-First Coordination)

Named agents coordinate via `SendMessage`, not polling or shared state.

```
Lead (you) ←→ architect ←→ developer ←→ tester ←→ reviewer
              (named agents message each other directly)
```

### Spawning a Coordinated Team

```javascript
// ALL agents in ONE message, each knows WHO to message next
Agent({ prompt: "Research the codebase. SendMessage findings to 'architect'.",
  subagent_type: "researcher", name: "researcher", run_in_background: true })
Agent({ prompt: "Wait for 'researcher'. Design solution. SendMessage to 'coder'.",
  subagent_type: "system-architect", name: "architect", run_in_background: true })
Agent({ prompt: "Wait for 'architect'. Implement it. SendMessage to 'tester'.",
  subagent_type: "coder", name: "coder", run_in_background: true })
Agent({ prompt: "Wait for 'coder'. Write tests. SendMessage results to 'reviewer'.",
  subagent_type: "tester", name: "tester", run_in_background: true })
Agent({ prompt: "Wait for 'tester'. Review code quality and security.",
  subagent_type: "reviewer", name: "reviewer", run_in_background: true })

// Kick off the pipeline
SendMessage({ to: "researcher", summary: "Start", message: "[task context]" })
```

### Patterns

| Pattern | Flow | Use When |
|---------|------|----------|
| **Pipeline** | A → B → C → D | Sequential dependencies (feature dev) |
| **Fan-out** | Lead → A, B, C → Lead | Independent parallel work (research) |
| **Supervisor** | Lead ↔ workers | Ongoing coordination (complex refactor) |

### Rules

- ALWAYS name agents — `name: "role"` makes them addressable
- ALWAYS include comms instructions in prompts — who to message, what to send
- Spawn ALL agents in ONE message with `run_in_background: true`
- After spawning: STOP, tell user what's running, wait for results
- NEVER poll status — agents message back or complete automatically

## Swarm & Routing

### Config
- **Topology**: hierarchical-mesh (anti-drift)
- **Max Agents**: 8
- **Memory**: hybrid
- **HNSW**: Enabled
- **Neural**: Enabled

```bash
npx @claude-flow/cli@latest swarm init --topology hierarchical --max-agents 8 --strategy specialized
```

### Agent Routing

| Task | Agents | Topology |
|------|--------|----------|
| Bug Fix | researcher, coder, tester | hierarchical |
| Feature | architect, coder, tester, reviewer | hierarchical |
| Refactor | architect, coder, reviewer | hierarchical |
| Performance | perf-engineer, coder | hierarchical |
| Security | security-architect, auditor | hierarchical |

### When to Swarm
- **YES**: 3+ files, new features, cross-module refactoring, API changes, security, performance
- **NO**: single file edits, 1-2 line fixes, docs updates, config changes, questions

### 3-Tier Model Routing

| Tier | Handler | Use Cases |
|------|---------|-----------|
| 1 | Agent Booster (WASM) | Simple transforms — skip LLM, use Edit directly |
| 2 | Haiku | Simple tasks, low complexity |
| 3 | Sonnet/Opus | Architecture, security, complex reasoning |

## Memory & Learning

### Before Any Task
```bash
npx @claude-flow/cli@latest memory search --query "[task keywords]" --namespace patterns
npx @claude-flow/cli@latest hooks route --task "[task description]"
```

### After Success
```bash
npx @claude-flow/cli@latest memory store --namespace patterns --key "[name]" --value "[what worked]"
npx @claude-flow/cli@latest hooks post-task --task-id "[id]" --success true --store-results true
```

### MCP Tools (use `ToolSearch("keyword")` to discover)

| Category | Key Tools |
|----------|-----------|
| **Memory** | `memory_store`, `memory_search`, `memory_search_unified` |
| **Bridge** | `memory_import_claude`, `memory_bridge_status` |
| **Swarm** | `swarm_init`, `swarm_status`, `swarm_health` |
| **Agents** | `agent_spawn`, `agent_list`, `agent_status` |
| **Hooks** | `hooks_route`, `hooks_post-task`, `hooks_worker-dispatch` |
| **Security** | `aidefence_scan`, `aidefence_is_safe`, `aidefence_has_pii` |
| **Hive-Mind** | `hive-mind_init`, `hive-mind_consensus`, `hive-mind_spawn` |

### Background Workers

| Worker | When |
|--------|------|
| `audit` | After security changes |
| `optimize` | After performance work |
| `testgaps` | After adding features |
| `map` | Every 5+ file changes |
| `document` | After API changes |

```bash
npx @claude-flow/cli@latest hooks worker dispatch --trigger audit
```

## Agents

**Core**: `coder`, `reviewer`, `tester`, `planner`, `researcher`
**Architecture**: `system-architect`, `backend-dev`, `mobile-dev`
**Security**: `security-architect`, `security-auditor`
**Performance**: `performance-engineer`, `perf-analyzer`
**Coordination**: `hierarchical-coordinator`, `mesh-coordinator`, `adaptive-coordinator`
**GitHub**: `pr-manager`, `code-review-swarm`, `issue-tracker`, `release-manager`

Any string works as a custom agent type.

## Build & Test

- ALWAYS run tests after code changes
- ALWAYS verify build succeeds before committing

```bash
npm run build && npm test
```

## CLI Quick Reference

```bash
npx @claude-flow/cli@latest init --wizard           # Setup
npx @claude-flow/cli@latest swarm init --v3-mode     # Start swarm
npx @claude-flow/cli@latest memory search --query "" # Vector search
npx @claude-flow/cli@latest hooks route --task ""    # Route to agent
npx @claude-flow/cli@latest doctor --fix             # Diagnostics
npx @claude-flow/cli@latest security scan            # Security scan
npx @claude-flow/cli@latest performance benchmark    # Benchmarks
```

26 commands, 140+ subcommands. Use `--help` on any command for details.

## Setup

```bash
claude mcp add claude-flow -- npx -y @claude-flow/cli@latest
npx @claude-flow/cli@latest daemon start
npx @claude-flow/cli@latest doctor --fix
```

**Agent tool** handles execution (agents, files, code, git). **MCP tools** handle coordination (swarm, memory, hooks). **CLI** is the same via Bash.

## SmartHjelp Specific Rules

SmartHjelp is a Flutter app with Provider, `AppState` as the single source of truth, immutable models, Supabase backend, Google Maps, local-first fallback, and a Norwegian premium mobile-first UX.

### Architecture Rules

- `AppState` owns app state, business logic, job flows, notifications, and Supabase/local sync unless the user explicitly asks for a refactor.
- Do not move logic out of `AppState` just to “clean up” the code.
- Models are immutable. Always update models with `copyWith`.
- Never mutate models directly. Do not do `job.status = ...`, `user.rating = ...`, or similar.
- Prefer additive and backwards-compatible changes.
- Do not remove, simplify, or rewrite existing functionality unless explicitly requested.
- Preserve the current Provider architecture and existing file structure unless there is a clear reason and the user approves it.

### Workflow Rules

- Always inspect the repository structure before editing.
- Always read relevant files before modifying them.
- Explain the implementation plan before writing code.
- Prefer editing existing files over creating new files.
- For meaningful changes, return complete updated files, not snippets.
- Warn before large refactors, Supabase/RLS changes, Firebase/FCM changes, Google Maps key/config changes, Android Gradle changes, payment/auth changes, or navigation-wide changes.
After code changes, run or instruct the user to run:
  - `flutter pub get` when dependencies changed
  - `flutter analyze`
  - `flutter test` when relevant
  - `flutter run -d <device>` when platform behavior is affected
  - `flutter clean` only when build/cache issues are suspected

### UI / UX Rules

- Keep all user-facing labels and copy in Norwegian unless explicitly asked otherwise.
- The app should feel premium, clean, trustworthy, and mobile-first.
- Avoid clutter, excessive colors, and unnecessary UI noise.
- Preserve consistent spacing, hierarchy, rounded cards, clear CTAs, and map/list consistency.
- Do not degrade existing mobile UX to satisfy desktop/web behavior.

### SmartHjelp Domain Rules

- Valid job statuses are only:
  - `open`
  - `reserved`
  - `inProgress`
  - `completed`
- Do not invent new statuses without explicit approval.
- Worker-facing views must show worker payout, not total customer payment.
- Customer-facing views may show total payment where appropriate.
- Preserve reservation, payment reservation, completion, approval, cancellation, rating, chat, and notification flows.
- Use domain wording consistently:
  - `oppdrag`
  - `oppdragsgiver`
  - `utfører`
  - `reservert`
  - `pågående`
  - `fullført`

### Supabase / Local-First Rules

- The app is local-first with Supabase sync.
- The UI should remain responsive even if Supabase fails.
- Do not remove fallback/local behavior.
- Remote write failures must be handled honestly with clear feedback.
- Do not assume Supabase writes, updates, or selects always succeed.
- Be careful with RLS. If a Supabase operation returns 0 rows, 406, PGRST116, or FK errors, analyze policies/data before changing Dart logic.
- SQL migrations must be safe and reversible where possible, using `IF EXISTS` / `IF NOT EXISTS` when appropriate.

### Notifications and Navigation

- Notifications must be actionable where possible.
- Message notifications should navigate to `ChatScreen`.
- Job/reservation/status notifications should navigate to `JobDetailScreen`.
- Preserve unread indicators, mark-as-read behavior, and navigation safety.
- Do not add fake notification UI that is not connected to real app state.

### Map/List Rules

- Map and list views must stay consistent in filters, categories, job visibility, and navigation.
- If a job can be opened/reserved from the list, the equivalent map flow should be considered.
- Preserve price/context on job cards, map cards, and pins.
- Do not hardcode Google Maps API keys in tracked files.
- Android and web Maps keys may require separate platform-restricted keys.

### Security Rules

- Never commit secrets.
- Never commit Firebase service account JSON.
- Never commit release keystores or key property files.
- Never put Google Maps API keys directly in tracked Dart files.
- Keep `android/local.properties` out of Git.
- `google-services.json` may be tracked as Firebase client config, but do not confuse it with private service account credentials.
- If a key was exposed, recommend rotation and platform/API restrictions.

### Code Quality Rules

- Keep changes small, deliberate, and easy to review.
- Do not “modernize” unrelated files while fixing a specific issue.
- Do not silence errors without understanding the cause.
- Do not introduce breaking changes to models, AppState methods, routes, Supabase schema assumptions, or UI flows without approval.
If uncertain, inspect more files first. Ask before editing only when ambiguity could cause architectural damage, data loss, security risk, or broken user flows.
