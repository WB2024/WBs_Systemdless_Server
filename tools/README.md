# Tools

**Repository:** https://github.com/WB2024/WBs_Systemdless_Server

> **Status:** Stub — add standalone utility scripts here as needed.

This directory is for standalone utility scripts and one-off tools that don't
fit into the main `scripts/` install pipeline.

---

## Intended Contents

| Script | Purpose |
|---|---|
| *(future)* `check-health.sh` | Quick system health summary (drives, services, pool) |
| *(future)* `backup-config.sh` | Archive `/etc/` config files to `/srv/backups/config/` |
| *(future)* `verify-pool.sh` | Verify mergerfs pool + SnapRAID status at a glance |
| *(future)* `rotate-logs.sh` | Force immediate logrotate run for all WBS logs |

---

## Guidelines for Scripts in This Directory

- Same header conventions as `scripts/`: `#!/usr/bin/env bash`, `set -euo pipefail`
- Source `scripts/lib/common.sh` for logging and helper functions:
  ```bash
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${SCRIPT_DIR}/../scripts/lib/common.sh"
  ```
- Tools should be **read-only or reversible** where possible
- Tools that modify state must have a confirmation gate via `confirm()`
- Do NOT put install scripts here — they belong in `scripts/`

---

## Running a Tool

```bash
cd /path/to/WBs_Systemdless_Server
sudo bash tools/check-health.sh
```
