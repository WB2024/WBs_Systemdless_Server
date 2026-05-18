# Cockpit Web UI

**Repository:** https://github.com/WB2024/WBs_Systemdless_Server

> **Status:** Stub — Cockpit is an alternative to the custom FastAPI web UI.
> Decision pending. See `docs/open-questions.md Q1`.

---

## What is Cockpit?

Cockpit is a web-based server management UI that provides:
- System overview (CPU, RAM, disk, network)
- Storage management (LVM, RAID, etc.)
- Service management
- Terminal access in the browser
- User management

Official site: https://cockpit-project.org/

---

## Cockpit on Devuan: Open Questions

<!-- TODO: DECISION REQUIRED — see Knowledge.md §17 Q1 -->

Before choosing Cockpit, the following must be verified on Devuan Daedalus:

1. **Does `cockpit-ws` require logind/elogind?**
   Cockpit uses PAM for authentication. On some configurations, PAM calls
   into `pam_systemd` to create login sessions. On Devuan without elogind,
   this may fail or fall back gracefully.

2. **Does `cockpit` pull in libsystemd?**
   If the Devuan package of `cockpit` depends on `libsystemd0` or
   `libelogind0`, this may conflict with the project's systemd-free goal.
   Check: `apt-cache depends cockpit | grep -i systemd`

3. **Does the OpenRC Cockpit init script exist?**
   Check: `apt-get install cockpit && ls /etc/init.d/cockpit`

---

## Installation (if Cockpit is chosen)

Set `WEBUI_MODE=cockpit` and run:

```bash
WEBUI_MODE=cockpit sudo bash scripts/09-install-webui.sh
```

Or install manually:

```bash
apt-get install cockpit
rc-update add cockpit default
rc-service cockpit start
```

Access at: `https://<server-ip>:9090`

---

## If Custom FastAPI is chosen instead

The custom FastAPI web UI is in `webui/custom/`. It has no systemd or logind
dependencies and is the current default.

See: `webui/custom/README.md`

---

## Decision Criteria

| Criterion | Cockpit | Custom FastAPI |
|---|---|---|
| logind dependency | Unknown — needs testing | None |
| systemd dependency | Possible — needs testing | None |
| NAS-specific features | Generic sysadmin UI | Can be tailored to NAS |
| Maintenance burden | Low (upstream maintained) | High (we maintain it) |
| Package count impact | ~20 extra packages | Minimal (Python + venv) |
| Port | 9090 | 8080 |
