# Crontab Setup

Wire a Norman routine into cron by calling `bin/run.sh` with the routine name:

```cron
0 8 * * * /path/to/norman/bin/run.sh morning-dogs
*/15 * * * * /path/to/norman/bin/run.sh drain-queue
```

Use an absolute path to `bin/run.sh`; cron does not start in the repository directory.
