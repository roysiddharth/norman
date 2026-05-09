# Norman v0.2 — Product Requirements Document

## Problem Statement

Norman v0.1 was a Claude Code plugin: tightly coupled to one agentic harness, installed via a versioned plugin cache, and reliant on shell scripts and crontab entries that pointed at the dev project directory. There was no stable installation path, no real UI product, and no way to use Norman with any harness other than Claude Code. Users couldn't onboard cleanly, couldn't switch LLM providers, and had no persistent data layer beyond Obsidian markdown files.

The core promise of Norman — a personal AI executive assistant that runs routines and manages tasks autonomously in the background — was real, but the delivery was brittle and developer-only.

## Solution

Norman v0.2 is a standalone, local-first product. It installs to a stable path on the user's machine (`~/.norman/`), runs as an always-on background service, and exposes a full web UI at `localhost:3007`. Users bring their own intelligence — either by connecting an existing agentic harness (Claude Code, OpenCode) or by providing an LLM API key directly (Anthropic, OpenAI). Norman owns its own data via SQLite. Routines and tasks are managed entirely within the product.

The core identity does not change: Norman is a routine-based, AI executive assistant that executes tasks for the user in the background.

## User Stories

1. As a new user, I want a setup wizard that walks me through configuring Norman on my machine, so that I can be fully operational without editing config files manually.
2. As a user, I want Norman to start automatically when my machine boots, so that my routines run without me needing to open an app.
3. As a user, I want to define routines in Norman's UI with a schedule, mode, and set of capabilities, so that Norman can execute them autonomously.
4. As a user, I want to view all my routines, their schedules, and their last execution status in the app, so that I know what Norman is doing.
5. As a user, I want to add ad-hoc tasks to Norman's queue from the app, so that Norman can handle work outside of scheduled routines.
6. As a user, I want to view my task queue and see the status of each task, so that I can track what Norman is working on.
7. As a user, I want to view execution logs by date, so that I can audit what Norman did and when.
8. As a user, I want to connect Claude Code or OpenCode as my intelligence provider with a single action, so that Norman delegates LLM execution to my existing harness.
9. As a user, I want to connect an Anthropic or OpenAI API key so that Norman runs its own agentic stack without requiring an external harness.
10. As a user, I want to switch my intelligence provider from the app settings, so that I'm not locked into a harness choice at install time.
11. As a Claude Code user who connects their harness, I want Norman's skills to be automatically installed into my Claude Code skills folder, so that I can invoke Norman capabilities from within Claude Code.
12. As a user without an existing harness, I want Norman to function fully using only my API key, so that I don't need to install Claude Code or OpenCode.
13. As a user, I want a settings page in the app where I can update my vault path, intelligence provider, and other configuration, so that I never need to edit files directly.
14. As a user, I want Norman to run routines at their defined schedules autonomously, even when I'm not actively using the app, so that the assistant operates in the background as intended.
15. As a user, I want routine execution to support three modes — AFK (fully automated), HITL (automated steps + handoff), and Manual (scheduling only) — so that I can control how much autonomy Norman has per routine.

## Implementation Decisions

### Data Layer
- **Database:** SQLite, managed via Drizzle ORM. Single file stored at `~/.norman/norman.db`.
- **Schema covers:** routines (name, schedule, mode, capabilities, enabled), tasks (description, status, created_at, resolved_at), execution logs (routine name, date, outcome, detail), app configuration (intelligence provider, provider credentials, vault path if used).
- All configuration that was previously a flat file (`~/.norman/config`) is stored in the database and managed through the app UI.
- No Obsidian dependency for data in v0.2. SQLite is the sole source of truth.

### App Architecture
- **Framework:** Next.js (existing `app/` directory), running at `localhost:3007`.
- **Scheduling:** `node-cron` runs inside the Next.js server process. All routine scheduling is managed in-process — no system crontab.
- **Lifecycle:** Norman runs as an always-on background service managed by a launchd plist on macOS. The setup wizard installs the plist. Norman starts on login and is always available to fire scheduled routines.
- **API routes** handle routine CRUD, task queue operations, log reads, provider configuration, and triggering manual routine runs.

### Intelligence Provider
- Two connection modes, not tiers — both are first-class:
  - **Harness mode:** User connects Claude Code or OpenCode. Norman delegates routine execution by invoking the harness CLI with a constructed prompt. Executor command is stored in the database.
  - **API key mode:** User provides an Anthropic or OpenAI API key. Norman becomes the agentic runtime using the Vercel AI SDK. Norman handles tool use, context, and execution directly.
- Provider can be changed at any time from the settings page.
- Norman functions fully in API key mode without any harness installed.

### Skills
- Skills (gworkspace, obsidian-cli, etc.) are internal capability constructs within Norman, not Claude Code plugin artifacts.
- In API key mode, skills are implemented as Vercel AI SDK tool definitions inside Norman's own runtime.
- In harness mode, if the user connects Claude Code or OpenCode, the relevant skills are installed into the harness's global skills directory (e.g., `~/.claude/skills/`). This happens at provider connection time, not at setup time.
- Skill installation is conditional on harness connection — never happens automatically.

### Setup Wizard
- Invoked via `norman setup` (CLI entry point, delivered via homebrew or bootstrap script).
- Collects: vault path (optional, for future Obsidian connector), intelligence provider choice, API key or harness CLI path.
- Scaffolds: `~/.norman/` directory, SQLite database with schema, launchd plist, initial configuration rows in DB.
- Does not install harness skills — that happens when the user connects a harness in the app.

### Delivery
- Installed to `~/.norman/` as a stable, version-independent path.
- Distributed via Homebrew formula or `curl | sh` bootstrap script.
- `~/.norman/bin/` contains the Node.js entry points that launchd invokes.
- No versioned paths in any system-level configuration (launchd plist, etc.).

### Bin Scripts
- Existing shell scripts (`run.sh`, `sync.sh`, etc.) are deprecated. Their logic is absorbed into the Next.js app's API routes and the internal `node-cron` scheduler.
- The `bin/` directory in the repo is retained temporarily as reference during the rewrite, then removed.

## Testing Decisions

Per project policy, tests are only written when `/tdd` is explicitly invoked. If tests are added, the behaviors worth verifying are:

- Routine scheduling: a routine with a valid cron expression fires at the right time; a disabled routine does not fire.
- Task queue: tasks transition through correct states (pending → in_progress → done/failed).
- Provider dispatch: harness mode constructs the correct prompt and invokes the correct CLI; API key mode constructs the correct Vercel AI SDK call.
- Skill installation: connecting a harness installs skills to the correct directory; disconnecting does not leave orphaned skills.
- Setup wizard: all required `~/.norman/` artifacts are created; re-running setup does not destroy existing data.

## Out of Scope

- **Obsidian connector** — deferred. No read/write integration with Obsidian vaults in v0.2.
- **macOS native app / Tauri wrapper** — localhost Next.js app is the product in v0.2. System tray / native app is v3.
- **Remote sync or cloud storage** — SQLite is local only. No remote database, no sync service.
- **Multi-machine support** — Norman is single-machine in v0.2.
- **Windows / Linux support** — launchd is macOS-only. Cross-platform service management is a future concern.
- **Plugin / marketplace distribution** — Norman is no longer a Claude Code plugin. No marketplace, no `claude plugin install`.
- **CHANGELOG and version bump tooling** — removed with the plugin era.

## Further Notes

- The existing `app/` (Next.js) directory is the foundation but the UI needs a full overhaul — it currently reflects the plugin-era dashboard (queue, routines, log as read-only panels). v0.2 requires authoring flows, settings, provider connection UI, and a design pass.
- Vercel AI SDK is the chosen framework for Norman's own agentic runtime. Use context7 to fetch current docs when implementing.
- The launchd plist approach means the app process must be stable and handle restarts gracefully. The SQLite connection should use WAL mode to avoid locking issues.
- Intelligence provider credentials (API keys) are configured locally by the user and encrypted at rest in SQLite.
