# Crontab Setup

Norman manages its own cron entries automatically via `bin/sync.sh`. The only manual step is a one-time bootstrap: install the `sync.sh` entry into crontab.

## Bootstrap (run once per machine)

```bash
(crontab -l 2>/dev/null; echo "*/5 * * * * /absolute/path/to/norman/bin/sync.sh") | crontab -
```

Replace `/absolute/path/to/norman` with the absolute path to your clone of this repository (e.g. `/Users/sid/Projects/project-norman`).

After this, `sync.sh` runs every 5 minutes and rewrites the `# BEGIN NORMAN` / `# END NORMAN` managed block in crontab to match the routines in `vault/Norman/Routines/`. Adding or removing a routine takes effect within 5 minutes — no further crontab editing required.
