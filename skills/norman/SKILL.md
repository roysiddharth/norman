---
name: norman
description: "Norman is your personal AI executive assistant. Use this skill when the user invokes /norman or mentions 'norman' with a command. Handles three commands: (1) add-task — queue a new ad-hoc task described conversationally; (2) run — manually trigger a named routine from the Obsidian vault; (3) status — show today's pending queue and recent log entries."
---

# Norman — Personal AI Executive Assistant

Norman reads routine definitions from your Obsidian vault, executes tasks (AFK, HITL, or Manual), coordinates with Google Calendar, and logs everything back to Obsidian.

## Commands

### `add-task <description>`

**Trigger phrases:** `/norman add-task`, "norman add task", "queue a task for norman", "add to norman queue"

Intake a new ad-hoc task conversationally and write it to the Obsidian queue.

1. Parse the free-text description to understand the task
2. Classify the task as AFK, HITL, or Manual based on how much human involvement is required:
   - **AFK** — can be completed end-to-end by the agent (no human needed)
   - **HITL** — agent handles automatable steps, human must complete the rest
   - **Manual** — human must do everything; agent just schedules a calendar block
3. If classification is ambiguous, ask the user to confirm the type
4. Write a queue note to `vault/Norman/Queue/` using obsidian-cli:
   ```yaml
   ---
   added_at: <ISO timestamp>
   description: <parsed task description>
   type: <AFK|HITL|Manual>
   status: pending
   ---
   ```
   Filename: `<YYYYMMDD-HHmmss>-<slug>.md` (timestamp-based, unique)
5. Confirm back to the user with a summary: task description, type, and filename

---

### `run <routine-name>`

**Trigger phrases:** `/norman run`, "norman run", "trigger routine", "run norman routine", "manually run"

Manually execute a named routine from the Obsidian vault without waiting for cron.

1. Read `vault/Norman/Routines/<routine-name>.md` using obsidian-cli
2. If the file does not exist, tell the user clearly: "No routine found: `<routine-name>`. Check `vault/Norman/Routines/` for available routines."
3. Parse frontmatter to get tasks, skills, and fallback_type
4. Execute each task using the shared execution logic (same as cron path):
   - **Manual tasks**: check Google Calendar for conflicts via gworkspace; create a calendar block for each; if no free slot, send an email notification
   - **HITL tasks**: execute automatable steps using declared skills; check calendar for conflicts; create a calendar block with handoff context; send handoff email via gworkspace
   - **AFK tasks**: load declared skills from frontmatter; execute end-to-end; on failure, re-run as `fallback_type` if set, otherwise send a signal email
5. Write execution log to `vault/Norman/Log/YYYY-MM-DD.md` (append a new section per run)
6. Return a summary of what was executed and the outcome

---

### `status`

**Trigger phrases:** `/norman status`, "norman status", "what's in the norman queue", "show norman log", "what did norman do today"

Show today's queue and recent execution log.

1. Read all notes in `vault/Norman/Queue/` using obsidian-cli
2. List pending items (status: pending) with their type and description
3. Read `vault/Norman/Log/YYYY-MM-DD.md` for today's date
4. Summarise completed runs: routine name, timestamp, tasks executed, outcomes
5. Format output clearly for the Claude Code conversation:
   ```
   ## Norman Status — <date>

   ### Queue (pending)
   - [AFK] <description>
   - [Manual] <description>

   ### Today's Log
   - <time> — <routine-name>: <outcome summary>
   ```
6. If the queue is empty, say so explicitly
7. If no log exists for today, say so explicitly

---

## Shared Execution Logic

Shared between `run` and the cron path (`bin/run.sh`).

### Task type: Manual

1. Parse task `description` and `duration_minutes` from routine note
2. Check Google Calendar for conflicts in the desired time window via gworkspace
3. If a free slot exists: create a calendar block with the task description as event title
4. If no free slot: send an email notification (via gworkspace Gmail) with the task details

### Task type: HITL

1. Execute any automatable steps using skills declared in routine frontmatter
2. Check Google Calendar for conflicts via gworkspace
3. Create a calendar block; event description must include:
   - What Norman completed
   - What the human must do
   - Any relevant context
4. Send a handoff email via gworkspace with the same information

### Task type: AFK

1. Load skills declared in routine `skills` frontmatter field
2. Execute the task end-to-end using loaded skills
3. On failure:
   - If `fallback_type` is set in frontmatter: re-run the task as that type
   - Otherwise: send a signal email with failure details via gworkspace Gmail
4. Send signal email only on failure or escalation — never on successful runs

### Logging

After every run (success or failure), append a section to `vault/Norman/Log/YYYY-MM-DD.md`:

```markdown
## <routine-name> — <HH:mm timestamp>

- **Tasks executed:** <count>
- **Outcomes:** <per-task summary>
- **Escalations:** <any escalations or failures>
```

Use obsidian-cli to write log entries.
