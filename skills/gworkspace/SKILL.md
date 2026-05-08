---
name: gworkspace
description: Use this skill for all Google Workspace operations — reading, writing, searching, or updating Drive files, Gmail messages, Calendar events, Google Docs, Sheets, or Chat. Invoked when the user asks to interact with any Google Workspace service: "find that doc", "send an email", "add to my sheet", "show my calendar", "upload to Drive", "search Gmail", "create a spreadsheet", etc. Replaces Google Drive, Gmail, and Calendar MCP tools.
---

# Google Workspace via gws CLI

## Setup

Run on every invocation:
```bash
bash ~/.claude/skills/gworkspace/setup.sh
```
If it exits non-zero, follow the printed instructions before continuing.

## Operations

See [./commands.md](./commands.md) for curated patterns covering Drive, Gmail, Calendar, Docs, Sheets, and Chat.

For any operation not covered, discover the syntax first:
```bash
gws <service> --help
gws <service> <resource> --help
gws <service> <resource> <method> --help
```
Then run the discovered command.

## Output

All commands return JSON. Pass raw JSON to the user unless they ask for a summary. Use `jq` to filter specific fields when helpful:
```bash
gws drive files list --params '{"pageSize": 10}' | jq '.files[] | {name, id}'
```

## Key flags

| Flag | Purpose |
|------|---------|
| `--dry-run` | Preview request without executing |
| `--page-all` | Auto-paginate results (NDJSON output) |
| `--page-limit N` | Cap pagination at N pages |
| `--params '{...}'` | API query parameters |
| `--json '{...}'` | Request body |
