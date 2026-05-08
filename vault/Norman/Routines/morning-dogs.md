---
name: morning-dogs
schedule: "daily at 07:30"
tasks:
  - description: "Feed and water the dogs"
    type: Manual
    duration_minutes: 10
  - description: "Check for upcoming vet appointments in the next 7 days"
    type: AFK
    duration_minutes: 5
  - description: "Order dog food if current bag is running low (check notes for stock level)"
    type: HITL
    duration_minutes: 20
skills:
  - gworkspace
fallback_type: HITL
---

# Morning Dogs

Daily morning routine for dog care. Runs at 07:30 each day.

- Manual tasks get a calendar block so the time is protected.
- AFK task checks the calendar for upcoming vet visits and logs what it finds.
- HITL task initiates any dog food order flow and hands off payment confirmation to the human.
