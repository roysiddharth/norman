# Norman

A Claude Code plugin that acts as a personal AI executive assistant. Norman runs recurring routines defined in your Obsidian vault, manages a task queue, and coordinates across Google Workspace and Obsidian.

---

## What it does

- **Task queue** — accept ad-hoc tasks via `/norman add-task`, classify them, and queue them to Obsidian
- **Routine scheduling** — define routines as markdown files; Norman auto-syncs them to your system crontab
- **Three execution modes**:
  - **AFK** — fully automated end-to-end via declared Claude Code skills
  - **HITL** — agent completes automatable steps, then hands off to you with a calendar block
  - **Manual** — agent manages scheduling only; you do the work
- **Web dashboard** — view queue, routines, and logs at `localhost:3007`
- **Integrations** — Google Workspace (Gmail, Calendar, Drive) and Obsidian vault

---

## Structure

```
bin/          Shell scripts (run.sh, sync.sh, status.sh, log.sh, dashboard.sh)
dashboard/    Next.js web UI (port 3007)
skills/       Claude Code skills (norman, gworkspace, obsidian-cli, obsidian-markdown, obsidian-bases)
vault/        Obsidian vault
  Norman/
    Routines/ Routine definitions (.md with YAML frontmatter)
    Queue/    Pending tasks
    Log/      Execution logs (per date)
```

---

## Setup

**1. Bootstrap the sync cron (one-time):**

```bash
crontab -e
# Add:
*/5 * * * * /absolute/path/to/project-norman/bin/sync.sh
```

This keeps your Obsidian routines in sync with the system crontab every 5 minutes.

**2. Start the dashboard (optional):**

```bash
cd dashboard && npm install
npm run dev   # or ./bin/dashboard.sh
```

Dashboard runs at `http://localhost:3007`.

---

## Usage

From Claude Code, use the `/norman` skill:

```
/norman add-task   — queue a new ad-hoc task
/norman run        — manually trigger a named routine
/norman status     — show today's pending queue and recent log entries
```

---

## Defining routines

Create a `.md` file in `vault/Norman/Routines/` with YAML frontmatter:

```markdown
---
title: Weekly Review
schedule: every Monday at 9am
mode: HITL
skills:
  - gworkspace
  - obsidian-cli
---

Summarise last week's completed tasks and draft next week's priorities.
```

Norman picks up new/updated routines automatically via `bin/sync.sh`.

---

## Version

See [CHANGELOG.md](CHANGELOG.md) for release history. Use `./bin/bump.sh` to cut a new version.
