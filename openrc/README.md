# OpenRC Init Scripts

This directory contains custom OpenRC init scripts for services that do not
ship their own `/etc/init.d/` script on Devuan, or where the upstream init
script has systemd dependencies that need to be removed.

**Repository:** https://github.com/WB2024/WBs_Systemdless_Server

---

## Deployment

The install scripts in `scripts/` deploy these automatically using the
`deploy_openrc_script()` helper from `scripts/lib/common.sh`.

To deploy manually:

```bash
cp openrc/<service_name> /etc/init.d/<service_name>
chmod +x /etc/init.d/<service_name>
rc-update add <service_name> default
rc-service <service_name> start
```

---

## Scripts in this directory

| Script | Service | Runlevel | Notes |
|---|---|---|---|
| `docker` | Docker CE daemon | `default` | Replaces upstream systemd unit |
| `tailscaled` | Tailscale VPN | `default` | Custom — no upstream OpenRC script |
| `netdata` | Netdata monitoring | `default` | Fallback if installer doesn't provide one |
| `snapraid-sync` | SnapRAID sync | *(manual only)* | One-shot, not added to boot |

---

## OpenRC Primer

### Key commands

```bash
# Check all service statuses
rc-status

# Add a service to boot
rc-update add <service> default

# Remove from boot
rc-update del <service> default

# Start / stop / restart now
rc-service <service> start
rc-service <service> stop
rc-service <service> restart

# Check service status
rc-service <service> status

# List all runlevels and their services
rc-update show
```

### Runlevels used in this project

| Runlevel | Purpose |
|---|---|
| `boot` | Essential services only (networking, logging) |
| `default` | Normal operating services (Docker, Samba, etc.) |
| `sysinit` | Kernel/hardware init (do not modify) |
| `shutdown` | Pre-shutdown hooks |

### Dependency keywords

```bash
depend() {
    need net         # hard dependency — net must be up
    after net        # soft ordering — start after net if both in same runlevel
    use dns logger   # optional soft deps
}
```

---

## Writing an OpenRC init script

Minimal template:

```bash
#!/sbin/openrc-run
description="Service description"

command="/path/to/daemon"
command_args="--flag1 --flag2"
command_user="user"
pidfile="/var/run/service.pid"
command_background="yes"

stdout_log="/var/log/service.log"
stderr_log="/var/log/service.log"

depend() {
    need net
    after net
}

start_pre() {
    # Setup checks before start (return 1 to abort)
    checkpath --directory --owner user:group --mode 0755 /var/run/service
}
```

### `checkpath` usage

```bash
checkpath --directory --owner root:root --mode 0755 /path/to/dir
checkpath --file     --owner root:root --mode 0640 /path/to/file.log
```

---

## Troubleshooting

```bash
# View service startup errors
tail -f /var/log/messages

# View service-specific log
tail -f /var/log/<service>.log

# Test an init script without OpenRC
bash -x /etc/init.d/<service> start

# Check what's in the default runlevel
ls -la /etc/runlevels/default/
```
