---
name: routine-name
schedule: "daily at 08:00"
tasks:
  - description: "Description of what this task involves"
    type: Manual
    duration_minutes: 15
  - description: "Description of an automated task"
    type: AFK
    duration_minutes: 5
  - description: "Description of a task requiring handoff"
    type: HITL
    duration_minutes: 30
skills:
  - gworkspace
fallback_type: HITL
---

# Routine Name

Brief description of what this routine does and when it runs.

## Schedule Field Vocabulary

The `schedule` frontmatter field must use one of the following exact patterns.
`bin/sync.sh` reads these to generate cron entries. Any unrecognised pattern is
**skipped with a warning** — the routine will not be scheduled until fixed.

| Pattern | Example | Cron equivalent |
|---|---|---|
| `"daily at HH:MM"` | `"daily at 07:30"` | `30 7 * * *` |
| `"weekdays at HH:MM"` | `"weekdays at 09:00"` | `0 9 * * 1-5` |
| `"every N minutes"` | `"every 15 minutes"` | `*/15 * * * *` |

`HH:MM` must be 24-hour time with zero-padded hours and minutes. `N` must be a
positive integer that divides 60 evenly (1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60).
