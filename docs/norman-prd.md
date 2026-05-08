# Norman — PRD

## Problem Statement

Managing a personal digital life — recurring routines, ad-hoc tasks, calendar coordination — requires constant manual orchestration. Tasks fall through the cracks, context is lost between sessions, and there's no systematic way to delegate automatable work to an AI agent while still having visibility into what's happening.

## Solution

Norman is a personal Claude Code plugin that acts as an AI executive assistant. It is routine-oriented: cron jobs invoke Norman on a schedule, Norman reads task definitions from an Obsidian vault, executes what it can autonomously, hands off the rest to the human via Google Calendar and email, and logs everything back to Obsidian. An interactive skill interface allows ad-hoc task intake and manual triggers.

## User Stories

1. As a user, I want cron to invoke Norman automatically so that my routines run without me thinking about them.
2. As a user, I want Norman to read routine definitions from my Obsidian vault so that I can author and edit routines in a familiar interface.
3. As a user, I want to classify tasks as AFK, HITL, or Manual in the routine note so that Norman knows exactly how to handle each one.
4. As a user, I want AFK tasks to be executed end-to-end by Norman so that I don't have to be present.
5. As a user, I want HITL tasks to result in a calendar block and a handoff email so that I know what Norman did and what I need to finish.
6. As a user, I want Manual tasks to be treated like appointments — just block the time on my calendar.
7. As a user, I want Norman to check my calendar for conflicts before scheduling any block so that it never double-books me.
8. As a user, I want every AFK run logged to Obsidian so that I have a passive audit trail.
9. As a user, I want signal-only emails for AFK tasks — only when something fails or needs my attention — so that my inbox isn't noisy.
10. As a user, I want to add ad-hoc tasks conversationally via `/norman add-task` so that I can delegate things mid-day without opening Obsidian.
11. As a user, I want ad-hoc tasks written to `Norman/Queue/` in Obsidian so that they persist and cron drains them on the next run.
12. As a user, I want `/norman run <routine-name>` to manually trigger any routine so that I can test without waiting for cron.
13. As a user, I want `/norman status` to show today's queue and recent log entries so that I have a quick visibility layer without opening Obsidian.
14. As a user, I want each routine to declare which skills it needs in frontmatter so that Norman loads only what's required.

## Implementation Decisions

### Plugin Structure

Norman is a Claude Code plugin with a single multi-command skill. It lives in the user's local plugin directory and is not published to the marketplace.

```
norman/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── norman/
│       └── SKILL.md
└── bin/
    └── run.sh
```

### Launcher (`bin/run.sh`)

- Accepts a routine name as its sole argument
- Constructs and fires a non-interactive `claude -p` invocation with a prompt that includes the routine name and instructs Norman to read the corresponding Obsidian note and execute
- Sets up any required environment variables
- Kept minimal — all intelligence lives in the skill/Obsidian layer, not the script

### Cron Entries

- One cron entry per routine schedule
- Each entry calls `~/.norman/bin/run.sh <routine-name>`
- Cron also runs a queue-drain routine on a regular cadence (e.g. every 15 minutes) to process `Norman/Queue/`

### Obsidian Schema

All Norman data lives in the user's Obsidian vault under a `Norman/` directory:

```
Norman/
  Routines/
    <routine-name>.md     ← one note per routine
  Log/
    YYYY-MM-DD.md         ← daily execution log
  Queue/
    <task-id>.md          ← ad-hoc tasks pending execution
```

**Routine note frontmatter contract:**
- `name` — routine identifier
- `schedule` — human-readable schedule description
- `tasks` — list of task objects, each with `description`, `type` (AFK/HITL/Manual), `duration_minutes`
- `skills` — list of skill names required by this routine
- `fallback_type` — (optional) type to escalate to if AFK execution fails

**Queue note frontmatter contract:**
- `added_at` — ISO timestamp
- `description` — free-text task description (as parsed by Norman from the add-task invocation)
- `type` — AFK/HITL/Manual
- `status` — `pending` | `in_progress` | `done`

**Log entry structure:**
- One section per routine run
- Records: routine name, timestamp, tasks executed, outcomes, any escalations or failures

### Norman Skill (`skills/norman/SKILL.md`)

Handles three commands:

**`add-task <description>`**
- Parses the description, classifies the task (asks user to confirm type if ambiguous), writes a structured note to `Norman/Queue/`
- Confirms back to the user with the queued task summary

**`run <routine-name>`**
- Reads `Norman/Routines/<routine-name>.md` from Obsidian
- Executes the routine inline (same logic as the cron path, but interactive)
- Used for testing and manual triggers

**`status`**
- Reads `Norman/Queue/` for pending items
- Reads today's `Norman/Log/YYYY-MM-DD.md`
- Presents a summary in the conversation

### Execution Logic (shared between cron and `run`)

1. Read routine note from Obsidian, parse frontmatter
2. Load declared skills
3. For each task:
   - **AFK**: execute using declared skills; on failure, escalate to `fallback_type` or send signal email
   - **HITL**: execute automatable steps, then check calendar for conflicts, create a calendar block with handoff context, send email with what Norman did and what the human must complete
   - **Manual**: check calendar for conflicts, create a calendar block
4. Write execution log to `Norman/Log/YYYY-MM-DD.md`
5. Send signal email only on failure or escalation

### External Integrations

- **`gworkspace` skill** — Calendar reads (conflict check), Calendar writes (block creation), Gmail (send email)
- **`obsidian-cli` skill** — Read routine notes, write log entries, read/write queue notes
- **Additional skills** — Declared per-routine in frontmatter; not pre-wired globally

## Testing Decisions

Per project policy, tests are only written when `/tdd` is explicitly invoked. If tests are written, the behaviors worth verifying are:

- `run.sh` constructs the correct claude invocation given a routine name argument
- Queue note written by `add-task` has valid frontmatter structure
- Cron drain skips notes with `status: done`
- Log entry is always written regardless of task outcome (success or failure)
- Calendar conflict check blocks scheduling when a slot is occupied

Test external behavior via the Obsidian and calendar outputs — do not test internal parsing logic.

## Out of Scope

- GUI or dashboard of any kind
- Mid-run ad-hoc queue draining (queue is drained only on cron schedule)
- Email-based task intake
- Multi-user support
- Third-party LLM API integration
- Publishing Norman to the claude-plugins marketplace
- Any intelligence for runtime task reclassification — type is always set by the human at authoring time

## Further Notes

- Norman is a personal plugin. It lives in the user's local plugin directory, not in the `roysiddharth/claude-plugins` marketplace repo.
- The `gworkspace` skill already exists at `~/.claude/skills/gworkspace` and is the only permitted interface for all Google Workspace operations.
- The Obsidian plugin (`obsidian-skills`) is already installed and provides `obsidian-cli` for vault operations.
- The Obsidian vault is the canonical memory store — it persists state across all sessions and is the source of truth for routine definitions, task queue, and execution history.
- The plugin must work with both Claude Code and OpenCode (skills installed via Claude Code are visible to OpenCode).
