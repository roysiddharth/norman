---
name: drain-queue
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
