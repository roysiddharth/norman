# Build an executive assistant

Let's call him **Norman**.

**Goal:**
To organize my digital life. Integrated with AI. Make it work with cron. Give it some routines to perform.

- Should be routine-oriented via cron jobs
- Give ad-hoc job queueing once the core loop works
- Integrate with Google Calendar to organize our calendars; should be calendar context aware (must check before scheduling AFK, HITL or Manual tasks)
- Integrate with an obsidian vault for long-term, graph-based memory

**Types of tasks:**
- AFK task: can be performed end-to-end via the agent only
- HITL: some or most steps in the task can be performed by the agent but requires real-time human input for the rest of the steps
- Manual: has to be performed by the human completely manually, treated like an appointment

**Communication strategy:**
Communicate via Calendar mostly. Also can occasionally send emails my inbox for alerts, updates or CTA.

**AI Integration:**
- Works like a Claude Code [plugin](https://code.claude.com/docs/en/plugins-reference). 
  - Should also work with Opencode. Have noticed that if I install a plugin/marketplace via claude code, it is added to opencode as well (at least the skills are. Rest is untested).
  - Refer to already existing [plugin marketplace](https://github.com/roysiddharth/claude-plugins) that I have made. Norman **does not** go into the marketplace because it's a personal agent, but this is a good reference.
- No third-party LLM API integration required since this is supposed to be an open-source and personal project.

**User story:**

As a user, I want to be able to take care of my dogs. There would be some tasks I have to do every day, at specific times like a routine and some tasks that would be added ad-hoc on some specific days. The assistant should be able to ingest those tasks, prepare the routine, break it down into sub-tasks and add it to my calendar. If the tasks are AFK tasks that the agent can handle, it should schedule a cron job for that. If it is something that I need to do by myself, the calendar time block that it sets should be enough.

> The above is an example. There can be many different kinds of routines to be set which can be similar to the above or vastly different. It's important that the agent can adapt to new kinds of routines with all the other skills and plugins they have, instead of having the workflow optimized for any one kind of routine.

**Integration with other skills/plugins:**

- `/gworkspace` (exists in ~/.claude/skills/): would be needed for operating the inbox and calendar

Some other skills that are already configured:

```
sid@Sids-Macbook-Air project-norman % ls ~/.claude/skills
deploy-to-vercel		llm-council
extract-video-transcript	playwright-cli
find-skills			skill-builder
github-manager			ssh-vm-ops
gworkspace			system-design-advisor
karpathy-guidelines		writing-content-with-voice
```

We need to brainstorm on what skills would be useful/required for this plugin.

Obsidian Plugin:

```
obsidian @ obsidian-skills
  Scope: user
  Version: 1.0.1
  Create and edit Obsidian vault files including Markdown, Bases, and Canvas. Use
  when working with .md, .base, or .canvas files in an Obsidian vault.

  Author: Steph Ango
  Status: Enabled

  Installed components:
  ● Skills: defuddle, obsidian-markdown, obsidian-bases, obsidian-cli, json-canvas


  ❯ Disable plugin
    Add to favorites
    Mark for update
    Update now
    Uninstall
    View repository
    Back to plugin list

  ctrl+p to navigate · Enter to select · Esc to go back
```

The obsidian plugin is already added. This can be used for handling the graph-based knowledge base. This would be the bread and buttern for the agent to read and write from memory, interact with the filesystem and persist information across sessions.