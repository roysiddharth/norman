---
name: norman
description: "Norman is your personal AI executive assistant. Use this skill when the user invokes /norman or mentions 'norman' with a command. Handles three commands: (1) add-task — queue a new ad-hoc task described conversationally; (2) run — manually trigger a named routine from the Obsidian vault; (3) status — show today's pending queue and recent log entries."
---

# Norman — Personal AI Executive Assistant

Norman reads routine definitions from your Obsidian vault, executes tasks (AFK, HITL, or Manual), coordinates with Google Calendar, and logs everything back to Obsidian.

## Machine Setup

When setting up Norman on a new machine:

1. Read `docs/crontab-setup.md` for the bootstrap command.
2. Execute the bootstrap step: install the `*/5 * * * * /absolute/path/to/norman/bin/sync.sh` cron entry with the correct absolute path for this machine.
3. No further crontab interaction is needed — `sync.sh` manages all Norman cron entries from this point on.

---

## Commands

### `add-task <description>`

**Trigger phrases:** `/norman add-task`, "norman add task", "queue a task for norman", "add to norman queue"

Intake a new ad-hoc task conversationally and write it to the Obsidian queue.

1. Parse the free-text description to understand the task
2. Classify the task as AFK, HITL, or Manual based on how much human involvement is required:
   - **AFK** — can be completed end-to-end by the agent (no human needed)
   - **HITL** — agent handles automatable steps, human must complete the rest
   - **Manual** — human must do everything; agent just schedules a calendar block
3. If classification is ambiguous, ask the user to confirm the type before proceeding
4. Generate the filename and note content:
   - **Timestamp:** current datetime in `YYYYMMDD-HHmmss` format (local time)
   - **Slug:** lowercase description, non-alphanumeric chars replaced with hyphens, collapsed and trimmed, truncated to 40 chars (e.g., `"Feed the dogs!"` → `feed-the-dogs`)
   - **Filename:** `<timestamp>-<slug>.md` (e.g., `20260508-143022-feed-the-dogs.md`)
   - **ISO timestamp:** current datetime in ISO 8601 format with timezone offset (e.g., `2026-05-08T14:30:22-07:00`)
5. Invoke the `obsidian:obsidian-cli` skill to write the queue note:
   ```bash
   obsidian create path="Norman/Queue/<filename>" content="---\nadded_at: \"<ISO timestamp>\"\ndescription: \"<task description>\"\ntype: <AFK|HITL|Manual>\nstatus: pending\n---" silent
   ```
6. Confirm back to the user with a summary:
   ```
   Queued: <description>
   Type: <AFK|HITL|Manual>
   File: Norman/Queue/<filename>
   ```

---

### `run <routine-name>`

**Trigger phrases:** `/norman run`, "norman run", "trigger routine", "run norman routine", "manually run"

Manually execute a named routine from the Obsidian vault without waiting for cron.

1. Accept exactly one routine name argument, as in `/norman run morning-dogs`
2. Read `vault/Norman/Routines/<routine-name>.md` using obsidian-cli. Read the named routine from `vault/Norman/Routines/<routine-name>.md`
3. If the file does not exist, tell the user clearly: "No routine found: `<routine-name>`. Check `vault/Norman/Routines/` for available routines." Do not attempt execution or write a success log when the named routine does not exist
4. Parse only the YAML frontmatter between the opening and closing `---` delimiters to get `name`, `schedule`, `tasks`, `skills`, and `fallback_type`
5. Execute the routine using the same execution logic as the cron path (`bin/run.sh`). Manual, HITL, and AFK paths must all work from `/norman run`:
   - **Manual tasks**: check Google Calendar for conflicts via gworkspace; create a calendar block for each; if no free slot, send an email notification
   - **HITL tasks**: load declared skills; execute automatable steps before handoff; check calendar for conflicts; create a calendar block with handoff context; send handoff email via gworkspace
   - **AFK tasks**: load declared skills from frontmatter; execute end-to-end; on failure, re-run as `fallback_type` if set, otherwise send a signal email
6. Write execution log to `vault/Norman/Log/YYYY-MM-DD.md` using the same log format as cron-triggered runs (append a new section per run)
7. Return a clear summary naming the routine, tasks executed, and final outcome

---

### `status`

**Trigger phrases:** `/norman status`, "norman status", "what's in the norman queue", "show norman log", "what did norman do today"

Show today's queue and recent execution log.

**Step 1: List pending queue items**

Invoke the `obsidian:obsidian-cli` skill. Search for notes in the Queue folder:

```bash
obsidian search query='path:"Norman/Queue"' limit=100
```

For each result that is not `_template.md`, read the note:

```bash
obsidian read path="Norman/Queue/<filename>.md"
```

Parse frontmatter from each note. Collect only notes where `status: pending`. Extract `type` and `description` from each.

**Step 2: Read today's log**

Compute today's date in `YYYY-MM-DD` format. Read the log file:

```bash
obsidian read path="Norman/Log/<YYYY-MM-DD>.md"
```

If the file does not exist, note that no runs have been logged today.

**Step 3: Check sync status**

Run the following to inspect crontab:

```bash
crontab -l 2>/dev/null || true
```

From the output:
- **Bootstrap installed** — true if any line contains `sync.sh`
- **Managed block present** — true if `# BEGIN NORMAN` and `# END NORMAN` markers are present
- **Managed entries** — lines between those markers that are not comments (i.e., actual cron lines)

**Step 4: Format and output**

Format the result clearly for the Claude Code conversation:

```
## Norman Status — <YYYY-MM-DD>

### Sync
- Bootstrap: ✓ sync.sh installed (runs every 5 min)   [or ✗ not installed — run bootstrap from docs/crontab-setup.md]
- Managed entries: <count>
  - <routine-name>: <cron-expression>

### Queue (pending)
- [AFK] <description>
- [Manual] <description>
- [HITL] <description>

### Today's Log
- <time> — <routine-name>: <outcome summary>
```

- If bootstrap is not installed, show the exact bootstrap command from `docs/crontab-setup.md` with the correct absolute path filled in
- If managed block is absent or empty: output `  _No managed entries — sync.sh has not run yet or no routines are scheduled._`
- If no pending items: output `### Queue (pending)\n_No pending tasks._`
- If no log file for today: output `### Today's Log\n_No runs logged today._`

---

## Shared Execution Logic

Shared between `run` and the cron path (`bin/run.sh`).

### Routine: drain-queue

1. Read all notes in `vault/Norman/Queue/` whose frontmatter has `status: pending`
2. Execute each pending queue note using the existing execution path selected by its `type` field: `AFK`, `HITL`, or `Manual`
3. After successful execution, update that queue note frontmatter to `status: done`
4. Skip queue notes whose frontmatter status is `done` or `in_progress`
5. Log each drained queue task to `vault/Norman/Log/YYYY-MM-DD.md` with note filename, type, description, and outcome

### Task type: Manual

1. Parse task `description` and `duration_minutes` from routine note
2. Process only tasks whose `type` is `Manual` for the Manual execution path
3. Use gworkspace to inspect the calendar before scheduling, using the task's desired window derived from the routine `schedule` and `duration_minutes`
4. If a free slot exists: Create a Google Calendar block for each Manual task and use the task `description` as the event title
5. If no conflict-free slot is available, send an email notification via gworkspace Gmail instead of failing silently; include the routine name, task description, desired window, and conflict summary
6. Append the Manual execution result to `vault/Norman/Log/YYYY-MM-DD.md` with routine name, timestamp, tasks scheduled, and any conflicts

### Task type: HITL

1. Process only tasks whose `type` is `HITL` for the HITL execution path
2. Load skills listed in the routine frontmatter `skills` field before automating HITL steps
3. Execute any automatable HITL steps using those declared skills before handing off to the human
4. Check Google Calendar for conflicts via gworkspace before creating the HITL handoff block
5. Create the HITL handoff calendar block only in a conflict-free slot; HITL calendar event description must contain what Norman completed, what the human must do, and any relevant context:
   - What Norman completed
   - What the human must do
   - Any relevant context
6. Send a HITL handoff email via gworkspace with the same context as the calendar event
7. Append the HITL execution result to `vault/Norman/Log/YYYY-MM-DD.md` with steps completed, handoff time, and calendar block created

### Task type: AFK

1. Process only tasks whose `type` is `AFK` for the AFK execution path
2. Load skills declared in routine `skills` frontmatter field
3. Execute the task end-to-end using loaded skills
4. On failure:
    - If `fallback_type` is set in frontmatter: re-run the task as that type
    - Otherwise: send a signal email with failure details via gworkspace Gmail
5. Send signal email only on failure or escalation — never on successful runs
6. Append the AFK execution result to `vault/Norman/Log/YYYY-MM-DD.md` with success or failure, and any escalation

### Logging

After every run (success or failure), append a section to `vault/Norman/Log/YYYY-MM-DD.md`:

```markdown
## <routine-name> — <HH:mm timestamp>

- **Tasks executed:** <count>
- **Outcomes:** <per-task summary>
- **Escalations:** <any escalations or failures>
```

Use obsidian-cli to write log entries.
