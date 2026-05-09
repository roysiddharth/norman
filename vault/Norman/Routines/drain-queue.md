---
name: drain-queue
enabled: false
schedule: "every 15 minutes"
tasks:
  - description: "Drain all pending Norman queue notes"
    type: AFK
    duration_minutes: 15
skills:
  - gworkspace
fallback_type: HITL
---

# Drain Queue

Cron routine for processing pending notes in `vault/Norman/Queue/`.

---

## Stage 1 — Collect pending tasks

List all `.md` files in `vault/Norman/Queue/` (excluding `_template.md`).
For each file, read the frontmatter. Collect all files where `status: pending`.

If no pending files exist, skip to Stage 3.

---

## Stage 2 — Process each pending task

For each pending queue note, in order of `added_at`:

1. Read the file fully (frontmatter + body).
2. Execute the task described in `description` according to its `type`:
   - `AFK` — execute autonomously without user interaction.
   - `HITL` — pause and surface to the user before proceeding.
   - `Manual` — log that human action is required; skip execution.
3. After execution, update `status` in the frontmatter:
   - Set `status: done` if the task completed successfully.
   - Set `status: failed` if the task could not be completed; append a brief failure note to the body.

Do not delete files in this stage.

---

## Stage 3 — Delete done notes with empty bodies

After Stage 2 completes, sweep `vault/Norman/Queue/*.md` (excluding `_template.md`).

For each file:

1. Read the file.
2. Check frontmatter: skip if `status` is not `done`.
3. Check body: extract all content after the closing `---` of the frontmatter block.
4. If the body contains only whitespace (or is empty), **hard-delete the file**.
5. If the body contains any non-whitespace content, **preserve the file** — it holds notes that should be kept.

Files with any status other than `done` are never touched in this stage.
