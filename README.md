# Norman

A personal AI executive assistant that runs on your machine.

Norman manages your routines, task queue, and integrations — running autonomously on a schedule or on demand. It pairs with your Obsidian vault and connects to your choice of LLM provider.

---

## How it works

- **Routines** — define recurring tasks as markdown files in your Obsidian vault. Norman runs them on a schedule via cron.
- **Task queue** — add ad-hoc tasks; Norman classifies and executes them.
- **Integrations** — Google Workspace (Gmail, Calendar, Drive) and Obsidian.
- **App** — a local web UI at `localhost:3007` to view queue, routines, and logs.

## LLM providers

Norman works with:
- **Claude Code** or **OpenCode** — one-click connect; Norman delegates execution to your harness
- **Anthropic / OpenAI API key** — Norman runs its own agentic stack via the Vercel AI SDK

## Structure

```
app/        Web UI (Next.js, port 3007)
bin/        Daemon scripts (run.sh, sync.sh) — installed to ~/.norman/bin/
skills/     Harness adapter skills (Claude Code, OpenCode)
```

## Setup

```bash
norman setup
```

The setup wizard configures your vault path, LLM provider, and bootstraps the cron schedule.
